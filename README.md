# StateMachine
A state machine implemented in Swift.

## Installation

### CocoaPods

```ruby
  pod 'StateMachine', '~> 1.0.0'
```

### Carthage

```ruby
  carthage 'jbaptistecastro/StateMachine' "1.0.0"
```

## Classes

### State

A state only needs a name. 

##### Create a State object

```swift
let myState = State("MyState")
```

### Transition

A transition needs a name, a "from" state and a "to" state. 

##### Create a Transition object

```swift
let fromState = State("FromState")
let toState = State("ToState")

let myTransition = Transition("MyTransition", from: fromState, to: toState)
```

### Lifecycle Events

##### Before a specific transition

```swift
beforeTransition(transition)
```

##### On leaving a specific state

```swift
leaveState(state)
```

##### On entering in a specific state

```swift
onState(state)
```

##### On entering in a specific transition

```swift
onTransition(transition)
```

### StateMachine

A state machine takes an initial State and a Transition array.

##### Create a StateMachine object

```swift
let stateA = State("StateA")
let stateB = State("StateB")

let transitionA = Transition("TransitionA", from: stateA, to: stateB)
let transitionB = Transition("TransitionB", from: stateB, to: stateA)

let stateMachine = StateMachine(initialState: stateA, transitions: [transitionA, transitionB]
```
##### Fire a Transition

```swift
do {
    stateMachine.fire(transition: transitionB, userInfo: nil)
} catch TransitionError.unknown {
    print("Transition unknown)
} catch TransitionError.notAllowed {
    print("Transition not allowed")
} 
```

##### Observe a lifecycle event

An event can be observed on a specific queue and can be triggered with a "userInfo" dictionary.

```swift
stateMachine.on(.onState(stateB), queue: observeQueue) { (userInfo) in
            
}
```

#### Helper functions

##### Compare a state with the current state

```swift
let isCurrent = stateMachine.isCurrent(state: myState)
```

##### If a transition can be fired

```swift
let canFire = stateMachine.canFire(transition: myTransition)
```

##### Get allowed transitions from the current state

```swift
let allowedTransitions = stateMachine.allowedTransitions()
```

##### Get a state from a specific name

```swift
let stateA = stateMachine.state(name: "stateA")
```

##### Get registered states

```swift
let states = stateMachine.allStates()
```

##### Get a transition from a specific name

```swift
let transitionA = stateMachine.transition(name: "transitionA")
```

##### Get registered transitions

```swift
let transitions = stateMachine.allTransitions()
```

### Objective C compatibility

Actually, StateMachine doesn't support Objective C and there is no plan to support it.