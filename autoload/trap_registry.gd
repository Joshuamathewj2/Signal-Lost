extends Node

## TrapRegistry
## Global spatial manager for mechanical traps and environmental hazards.
## Provides query interfaces for enemy AI trap awareness, pathfinding avoidance,
## and player acoustic disarming.

signal trap_triggered(trap: Node2D, trap_id: StringName)
signal trap_disarmed(trap: Node2D, trap_id: StringName)

var registered_traps: Array[Node2D] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if SceneRouter != null and SceneRouter.has_signal("level_loaded"):
		SceneRouter.level_loaded.connect(_on_level_loaded)

func _on_level_loaded(_level_root: Node) -> void:
	reset_for_level()

func reset_for_level() -> void:
	registered_traps.clear()

func register_trap(trap: Node2D) -> void:
	if trap == null or not is_instance_valid(trap):
		return
	if not registered_traps.has(trap):
		registered_traps.append(trap)

func unregister_trap(trap: Node2D) -> void:
	registered_traps.erase(trap)

## Checks if there is an active, armed trap within check_dist along the facing direction.
func is_hazard_ahead(from_pos: Vector2, facing_dir: float, check_dist: float = 64.0) -> bool:
	for trap in registered_traps:
		if not is_instance_valid(trap):
			continue
		if trap.get("is_disarmed") == true:
			continue
		var to_trap: Vector2 = trap.global_position - from_pos
		# Check horizontal alignment in facing direction
		if absf(to_trap.y) <= 32.0 and signf(to_trap.x) == signf(facing_dir):
			if absf(to_trap.x) <= check_dist:
				return true
	return false

## Returns the nearest active trap within max_dist.
func get_nearest_trap(from_pos: Vector2, max_dist: float = 200.0) -> Node2D:
	var nearest: Node2D = null
	var min_d: float = max_dist
	for trap in registered_traps:
		if not is_instance_valid(trap):
			continue
		var d: float = from_pos.distance_to(trap.global_position)
		if d < min_d:
			min_d = d
			nearest = trap
	return nearest
