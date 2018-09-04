/**
 *  StateMachine
 *
 *  Copyright (c) Jean-Baptiste Castro 2018
 *  MIT license - see LICENSE.md
 */

import Foundation

// MARK: State

open class State: Hashable {
    
    /* Hashable */
    
    public var hashValue: Int {
        return self.name.hashValue
    }
    
    /* Properties */
    
    public let name: String
    
    /* Initialization */
    
    public init(_ name: String) {
        self.name = name
    }
}

extension State: Equatable {
    
    static open func == (lhs: State,
                         rhs: State) -> Bool {
        
        return lhs.name == rhs.name
    }
}

// MARK: Transition

open class Transition: Hashable {
    
    /* Hashable */
    
    public var hashValue: Int {
        return self.name.hashValue
    }
    
    /* Properties */
    
    public let name: String
    public let from: State
    public let to: State
    
    /* Initialization */
    
    public init(_ name: String,
                from: State,
                to: State) {
        
        self.name = name
        self.from = from
        self.to = to
    }
}

extension Transition: Equatable {
    
    static open func == (lhs: Transition,
                         rhs: Transition) -> Bool {
        
        return lhs.name == rhs.name && lhs.from == rhs.from && lhs.to == rhs.to
    }
}

// MARK: LifecycleEvent

public enum LifecycleEvent {
    
    /* State */
    
    case onState(_: State)
    case leaveState(_: State)
    
    /* Transition */
    
    case beforeTransition(_: Transition)
    case onTransition(_: Transition)
}

extension LifecycleEvent: Hashable {
    
    public var hashValue: Int {
        switch self {
        case .beforeTransition(let value):
            return "bt\(value.hashValue)".hashValue
        case .leaveState(let value):
            return "ls\(value.hashValue)".hashValue
        case .onState(let value):
            return "os\(value.hashValue)".hashValue
        case .onTransition(let value):
            return "ot\(value.hashValue)".hashValue
        }
    }
}

extension LifecycleEvent: Equatable {
    
    public static func == (lhs: LifecycleEvent, rhs: LifecycleEvent) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

// MARK: Error

public enum TransitionError: Error {
    
    case unknown
    case notAllowed
}

// MARK: Context

private struct Context {
    
    let queue: DispatchQueue
    var block: ([AnyHashable: Any]?) -> Void
}

// MARK: State Machine

open class StateMachine {
    
    /* Properties */
    
    private var currentState: State
    
    private let transitionQueue = DispatchQueue(label: "com.statemachine.transition",
                                                qos: .default,
                                                attributes: .concurrent,
                                                autoreleaseFrequency: .workItem,
                                                target: nil)
    
    private lazy var states: [State] = [State]()
    private lazy var transitions: [Transition] = [Transition]()
    private lazy var map: [State: [Transition]] = [State: [Transition]]()
    private lazy var contexts: [LifecycleEvent: Context] = [LifecycleEvent: Context]()
    
    // MARK: Initialization
    
    public init(initialState: State,
                transitions: [Transition]) {
        
        self.currentState = initialState
        
        configure(transitions: transitions)
    }
    
    // MARK: Transition
    
    public func fire(transition: Transition,
                     userInfo: [AnyHashable: Any]?) throws {
        
        if !transitions.contains(transition) {
            throw TransitionError.unknown
        }
        
        if !canFire(transition: transition) {
            throw TransitionError.notAllowed
        }
        
        transitionQueue.async(flags: .barrier) { [weak self] in
            self?.begin(transition)
            self?.execute(transition,
                          userInfo: userInfo)
        }
    }
    
    // MARK: Observer
    
    public func on(_ event: LifecycleEvent,
                   queue: DispatchQueue = DispatchQueue.main,
                   using block: @escaping([AnyHashable: Any]?) -> Void) {
        
        let context = Context(queue: queue,
                              block: block)
        contexts[event] = context
    }
    
    // MARK: Lifecycle
    
    private func begin(_ transition: Transition) {
        if let context = contexts[.beforeTransition(transition)] {
            context.queue.async {
                context.block(nil)
            }
        }
        
        if let context = contexts[.leaveState(transition.from)] {
            context.queue.async {
                context.block(nil)
            }
        }
    }
    
    private func execute(_ transition: Transition,
                         userInfo: [AnyHashable: Any]?) {
        
        currentState = transition.to
        
        if let context = contexts[.onState(transition.to)] {
            context.queue.async {
                context.block(userInfo)
            }
        }
        
        if let context = contexts[.onTransition(transition)] {
            context.queue.async {
                context.block(userInfo)
            }
        }
    }
    
    // MARK: Configuration
    
    private func configure(transitions: [Transition]) {
        transitions.forEach { (transition) in
            map(transition: transition)
        }
    }
    
    private func map(transition: Transition) {
        add(state: transition.from)
        add(state: transition.to)
        add(transition: transition)
        
        if var set = map[transition.from] {
            set.append(transition)
            map[transition.from] = set
        }
    }
    
    private func add(state: State) {
        guard map[state] == nil else {
            return
        }
        
        states.append(state)
        map[state] = [Transition]()
    }
    
    private func add(transition: Transition) {
        guard !transitions.contains(transition) else {
            return
        }
        
        transitions.append(transition)
    }
    
    // MARK: Helpers
    
    public func isCurrent(state: State) -> Bool {
        var isCurrent = false
        
        transitionQueue.sync {
            isCurrent = (state == currentState)
        }
        
        return isCurrent
    }
    
    public func canFire(transition: Transition) -> Bool {
        guard let allowedTransition = allowedTransitions() else {
            return false
        }
        
        return !(allowedTransition.filter({
            $0 == transition
        }).isEmpty)
    }
    
    public func allowedTransitions() -> [Transition]? {
        var allowedTransition: [Transition]?
        
        transitionQueue.sync {
            allowedTransition = map[currentState]
        }
        
        return allowedTransition
    }
    
    public func state(name: String) -> State? {
        var state: State?
        
        transitionQueue.sync {
            state = states.first(where: {
                $0.name == name
            })
        }
        
        return state
    }
    
    public func allStates() -> [State] {
        var allStates = [State]()
        
        transitionQueue.sync {
            allStates = states
        }
        
        return allStates
    }
    
    public func transition(name: String) -> Transition? {
        var transition: Transition?
        
        transitionQueue.sync {
            transition = transitions.first(where: {
                $0.name == name
            })
        }
        
        return transition
    }
    
    public func allTransitions() -> [Transition] {
        var allTransitions = [Transition]()
        
        transitionQueue.sync {
            allTransitions = transitions
        }
        
        return allTransitions
    }
}
