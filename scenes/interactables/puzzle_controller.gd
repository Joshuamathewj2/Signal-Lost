class_name PuzzleController
extends Node

## PuzzleController
## Manages multi-element puzzles (resonance panels, harmonic lanterns, seal locks).
## Handles order validation, timeout resets, and unlocking target blast doors.

signal puzzle_solved(controller: PuzzleController)
signal puzzle_reset(controller: PuzzleController)
signal element_triggered(element: Node, index: int)

@export var elements: Array[NodePath] = []
@export var target_door: NodePath
@export var is_sequential: bool = false
@export var sequence_order: Array[int] = []
@export var sequence_timeout: float = 8.0
@export var auto_unlock_door: bool = true

var is_solved: bool = false
var current_sequence: Array[int] = []
var sequence_timer: float = 0.0
var active_elements: Dictionary = {}
var registered_nodes: Array[Node] = []


func _ready() -> void:
	add_to_group(&"puzzle_controllers")
	for path in elements:
		var node: Node = get_node_or_null(path)
		if node != null:
			register_element(node)


func register_element(node: Node, explicit_index: int = -1) -> void:
	if registered_nodes.has(node):
		return
	registered_nodes.append(node)
	var idx: int = explicit_index if explicit_index >= 0 else registered_nodes.size() - 1
	if node.has_signal("struck"):
		node.connect("struck", func(_lantern: Node, p_idx: int) -> void:
			_on_element_triggered(node, p_idx if p_idx >= 0 else idx)
		)
	elif node.has_signal("triggered"):
		node.connect("triggered", func(_elem: Variant = null) -> void:
			_on_element_triggered(node, idx)
		)
	elif node.has_signal("state_changed"):
		node.connect("state_changed", func(_elem: Node, is_active: bool) -> void:
			if is_active:
				_on_element_triggered(node, idx)
			else:
				active_elements.erase(idx)
		)


func _on_element_triggered(elem: Node, idx: int) -> void:
	if is_solved:
		return

	element_triggered.emit(elem, idx)
	active_elements[idx] = true

	if is_sequential:
		if current_sequence.is_empty():
			sequence_timer = sequence_timeout

		current_sequence.append(idx)
		var step: int = current_sequence.size() - 1

		# Validate current step in sequence
		if step < sequence_order.size() and sequence_order[step] == idx:
			if current_sequence.size() == sequence_order.size():
				solve()
		else:
			# Sequence mismatch -> Reset
			reset_puzzle()
	else:
		_check_parallel_solution()


func _check_parallel_solution() -> void:
	var total_required: int = elements.size() if not elements.is_empty() else registered_nodes.size()
	if active_elements.size() >= total_required and total_required > 0:
		solve()


func _process(delta: float) -> void:
	if is_solved:
		return

	if is_sequential and not current_sequence.is_empty():
		sequence_timer -= delta
		if sequence_timer <= 0.0:
			reset_puzzle()


func solve() -> void:
	if is_solved:
		return
	is_solved = true
	puzzle_solved.emit(self)

	# Unlock target door if assigned
	if auto_unlock_door and not target_door.is_empty():
		var door_node: Node = get_node_or_null(target_door)
		if door_node != null:
			if door_node.has_method("unlock"):
				door_node.call("unlock")
			elif door_node.has_method("open"):
				door_node.call("open")
			elif "is_open" in door_node:
				door_node.set("is_open", true)


func reset_puzzle() -> void:
	current_sequence.clear()
	sequence_timer = 0.0
	active_elements.clear()

	# Notify registered elements to reset visual/activation state
	for node in registered_nodes:
		if node != null and node.has_method("reset"):
			node.call("reset")

	puzzle_reset.emit(self)
