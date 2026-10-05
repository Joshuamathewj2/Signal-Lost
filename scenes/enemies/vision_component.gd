class_name VisionComponent
extends Node2D

signal player_spotted(pos: Vector2)
signal player_lost()

@export var profile: EnemyProfile

var is_spotted: bool = false
var last_known_pos: Vector2 = Vector2.ZERO
var tick_timer: float = 0.0

func _physics_process(delta: float) -> void:
	tick_timer += delta
	var v_tick: float = GameConfig.data.vision_tick if (GameConfig != null and GameConfig.data != null) else 0.1
	if tick_timer >= v_tick:
		tick_timer = 0.0
		_check_vision()

func _check_vision() -> void:
	if profile == null or profile.sight_range <= 0.0 or profile.sight_angle_deg <= 0.0:
		return

	var player: Node = get_tree().get_first_node_in_group(&"player")
	if player == null or not (player is Node2D):
		_handle_lost()
		return

	var p2d: Node2D = player as Node2D
	var p_pos: Vector2 = p2d.global_position

	# Check reveal status
	if PulseRegistry != null and not PulseRegistry.player_revealed(p_pos):
		_handle_lost()
		return

	# Check distance
	var dist: float = global_position.distance_to(p_pos)
	if dist > profile.sight_range:
		_handle_lost()
		return

	# Check vision cone angle
	var parent_node: Node = get_parent()
	var facing_val: int = 1
	if parent_node != null and "facing" in parent_node:
		facing_val = int(parent_node.get("facing"))
	var forward: Vector2 = Vector2.RIGHT if facing_val >= 0 else Vector2.LEFT

	var to_target: Vector2 = (p_pos - global_position).normalized()
	var ang_deg: float = rad_to_deg(absf(forward.angle_to(to_target)))
	if ang_deg > profile.sight_angle_deg * 0.5:
		_handle_lost()
		return

	# Raycast line-of-sight against layer 1 (world)
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	if space_state != null:
		var query := PhysicsRayQueryParameters2D.create(global_position, p_pos, 1)
		var hit := space_state.intersect_ray(query)
		if not hit.is_empty():
			_handle_lost()
			return

	# Spotted!
	last_known_pos = p_pos
	is_spotted = true
	player_spotted.emit(p_pos)

func _handle_lost() -> void:
	if is_spotted:
		is_spotted = false
		player_lost.emit()
