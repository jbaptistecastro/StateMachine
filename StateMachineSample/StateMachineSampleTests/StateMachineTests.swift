/**
 *  StateMachine
 *
 *  Copyright (c) Jean-Baptiste Castro 2018
 *  MIT license - see LICENSE.md
 */

import XCTest
@testable import StateMachineSample

// MARK: Mocks

private struct StateMachineMocks {
    
    struct Constants {
        
        static let stateA = "stateA"
        static let stateB = "stateB"
        
        static let transitionA = "transitionA"
        static let transitionB = "transitionB"
    }
    
    static func stateA() -> State {
        return State(Constants.stateA)
    }
    
    static func stateB() -> State {
        return State(Constants.stateB)
    }
    
    static func transitionA() -> Transition {
        return Transition(Constants.transitionA,
                          from: stateA(),
                          to: stateB())
    }
    
    static func transitionB() -> Transition {
        return Transition(Constants.transitionB,
                          from: stateB(),
                          to: stateA())
    }
    
    static func unknownTransition() -> Transition {
        return Transition("unknown",
                          from: stateB(),
                          to: stateA())
    }
    
    static func transitions() -> [Transition] {
        return [transitionA(), transitionB()]
    }
    
    static func userInfo() -> [AnyHashable: Any] {
        var userInfo = [AnyHashable: Any]()
        userInfo["key"] = "object"
        
        return userInfo
    }
}

// MARK: Tests

class StateMachineTests: XCTestCase {
    
    func testAllowedTransition() {
        let transitions = StateMachineMocks.transitions()
        let stateMachine = StateMachine(initialState: StateMachineMocks.stateA(),
                                        transitions: transitions)
        let transition = StateMachineMocks.transitionA()
        
        XCTAssertNoThrow(try stateMachine.fire(transition: transition, userInfo: nil))
        
        let expectedState = StateMachineMocks.stateB()
        
        XCTAssertTrue(stateMachine.isCurrent(state: expectedState))
    }
    
    func testUnknownTransition() {
        let transitions = StateMachineMocks.transitions()
        let stateMachine = StateMachine(initialState: StateMachineMocks.stateA(),
                                        transitions: transitions)
        let transition = StateMachineMocks.unknownTransition()
        
        XCTAssertThrowsError(try stateMachine.fire(transition: transition, userInfo: nil)) { error in
            XCTAssertEqual(error as? TransitionError, TransitionError.unknown)
        }
    }
    
    func testNotAllowedTransition() {
        let transitions = StateMachineMocks.transitions()
        let stateMachine = StateMachine(initialState: StateMachineMocks.stateA(),
                                        transitions: transitions)
        let transition = StateMachineMocks.transitionB()
        
        XCTAssertThrowsError(try stateMachine.fire(transition: transition, userInfo: nil)) { error in
            XCTAssertEqual(error as? TransitionError, TransitionError.notAllowed)
        }
    }
    
    func testStateObserver() {
        let expectation = XCTestExpectation(description: "StateObserver")
        
        let transitions = StateMachineMocks.transitions()
        let stateMachine = StateMachine(initialState: StateMachineMocks.stateA(),
                                        transitions: transitions)
        let transition = StateMachineMocks.transitionA()
        
        stateMachine.on(.onState(StateMachineMocks.stateB())) { (_) in
            expectation.fulfill()
        }
        
        try? stateMachine.fire(transition: transition,
                               userInfo: nil)
        
        wait(for: [expectation],
             timeout: 1)
    }
    
    func testTransitionObserver() {
        let expectation = XCTestExpectation(description: "TransitionObserver")
        
        let transitions = StateMachineMocks.transitions()
        let stateMachine = StateMachine(initialState: StateMachineMocks.stateA(),
                                        transitions: transitions)
        let transition = StateMachineMocks.transitionA()
        
        stateMachine.on(.onTransition(transition)) { (_) in
            expectation.fulfill()
        }
        
        try? stateMachine.fire(transition: transition,
                               userInfo: nil)
        
        wait(for: [expectation],
             timeout: 1)
    }
    
    func testObserverWithUserInfo() {
        let transitions = StateMachineMocks.transitions()
        let stateMachine = StateMachine(initialState: StateMachineMocks.stateA(),
                                        transitions: transitions)
        let transition = StateMachineMocks.transitionA()
        let expectedUserInfo = StateMachineMocks.userInfo()
        
        stateMachine.on(.onTransition(StateMachineMocks.transitionB())) { (userInfo) in
            guard let userInfo = userInfo else {
                XCTFail()
                return
            }
            
            XCTAssertTrue(NSDictionary(dictionary: userInfo).isEqual(to: expectedUserInfo))
        }
        
        try? stateMachine.fire(transition: transition,
                               userInfo: StateMachineMocks.userInfo())
    }
    
    func testStateMachineLifecycle() {
        let beforeTransitionExpectation = XCTestExpectation(description: "beforeTransitionExpectation")
        let leaveStateExpectation = XCTestExpectation(description: "leaveStateExpectation")
        let onStateExpectation = XCTestExpectation(description: "onStateExpectation")
        let onTransitionExpectation = XCTestExpectation(description: "onTransitionExpectation")
        
        let transitions = StateMachineMocks.transitions()
        let stateMachine = StateMachine(initialState: StateMachineMocks.stateA(),
                                        transitions: transitions)
        let transition = StateMachineMocks.transitionA()
        
        stateMachine.on(.beforeTransition(transition)) { (_) in
            beforeTransitionExpectation.fulfill()
        }
        
        stateMachine.on(.leaveState(StateMachineMocks.stateA())) { (_) in
            leaveStateExpectation.fulfill()
        }
        
        stateMachine.on(.onState(StateMachineMocks.stateB())) { (_) in
            onStateExpectation.fulfill()
        }
        
        stateMachine.on(.onTransition(transition)) { (_) in
            onTransitionExpectation.fulfill()
        }
        
        try? stateMachine.fire(transition: transition,
                               userInfo: nil)
        
        wait(for: [beforeTransitionExpectation, leaveStateExpectation, onStateExpectation, onTransitionExpectation], timeout: 1, enforceOrder: true)
    }
}
