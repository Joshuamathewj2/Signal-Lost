class_name TestStateMachine
extends RefCounted

const StateScript = preload("res://scripts/core/state.gd")
const StateMachineScript = preload("res://scripts/core/state_machine.gd")

class DummyStateA extends StateScript:
	var enter_called: int = 0
	var exit_called: int = 0
	var last_msg: Dictionary = {}

	func enter(msg: Dictionary = {}) -> void:
		enter_called += 1
		last_msg = msg

	func exit() -> void:
		exit_called += 1

class DummyStateB extends StateScript:
	var enter_called: int = 0
	var exit_called: int = 0
	var last_msg: Dictionary = {}

	func enter(msg: Dictionary = {}) -> void:
		enter_called += 1
		last_msg = msg

	func exit() -> void:
		exit_called += 1

func run() -> Array[String]:
	var failures: Array[String] = []

	var sm: StateMachine = StateMachineScript.new() as StateMachine
	var state_a: DummyStateA = DummyStateA.new()
	state_a.name = "StateA"
	var state_b: DummyStateB = DummyStateB.new()
	state_b.name = "StateB"

	sm.add_child(state_a)
	sm.add_child(state_b)
	sm.initial = state_a

	var changed_signals: Array[Dictionary] = []
	sm.state_changed.connect(func(actor: Node, from_s: StringName, to_s: StringName):
		changed_signals.append({"actor": actor, "from": from_s, "to": to_s})
	)

	sm._ready()

	# Initial state should be StateA
	if sm.current != state_a:
		failures.append("Expected current state to be StateA")
	if state_a.enter_called != 1:
		failures.append("Expected StateA enter_called == 1, got %d" % state_a.enter_called)

	# Transition to StateB with payload
	sm.transition_to(&"StateB", {"target": Vector2(10, 20)})
	if sm.current != state_b:
		failures.append("Expected current state to be StateB")
	if state_a.exit_called != 1:
		failures.append("Expected StateA exit_called == 1, got %d" % state_a.exit_called)
	if state_b.enter_called != 1:
		failures.append("Expected StateB enter_called == 1, got %d" % state_b.enter_called)
	if not state_b.last_msg.has("target"):
		failures.append("Expected StateB last_msg to have 'target'")

	# Transition to same state without force -> should be ignored
	sm.transition_to(&"StateB")
	if state_b.enter_called != 1:
		failures.append("Expected StateB enter_called to remain 1 after redundant transition")

	# Transition to same state WITH force -> should re-enter
	sm.transition_to(&"StateB", {"force": true})
	if state_b.enter_called != 2:
		failures.append("Expected StateB enter_called == 2 after forced transition")

	# Check transition helper on state
	state_b.transition(&"StateA")
	if sm.current != state_a:
		failures.append("Expected current state to be StateA after state.transition()")

	# Clean up
	state_a.free()
	state_b.free()
	sm.free()

	return failures
