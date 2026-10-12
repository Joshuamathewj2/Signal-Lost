class_name StateMachine
extends Node

signal state_changed(actor: Node, from_state: StringName, to_state: StringName)

@export var initial: State
@export var actor: Node

var current: State = null
var states: Dictionary = {}

func _ready() -> void:
	if actor == null:
		actor = get_parent()

	for child in get_children():
		if child is State:
			var s: State = child as State
			s.machine = self
			s.actor = actor
			states[s.name] = s
			states[StringName(s.name)] = s
			states[s.name.to_lower()] = s
			states[StringName(s.name.to_lower())] = s

	if initial != null:
		transition_to(initial.name)
	elif get_child_count() > 0 and get_child(0) is State:
		transition_to(get_child(0).name)

func transition_to(target_name: StringName, msg: Dictionary = {}) -> void:
	if current != null and (current.name == target_name or current.name.to_lower() == str(target_name).to_lower()) and not msg.get("force", false):
		return

	if not states.has(target_name):
		var lower_target: StringName = StringName(str(target_name).to_lower())
		if states.has(lower_target):
			target_name = lower_target
		else:
			push_warning("StateMachine: state '%s' not found" % str(target_name))
			return

	var prev_name: StringName = current.name if current != null else &""
	if current != null:
		current.exit()

	current = states[target_name] as State
	current.enter(msg)
	state_changed.emit(actor, prev_name, current.name)

func _process(delta: float) -> void:
	if current != null:
		current.update(delta)

func _physics_process(delta: float) -> void:
	if current != null:
		current.physics_update(delta)
