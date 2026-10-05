class_name PlatformMover
extends Node

signal arrived
signal path_failed

@export var body: EnemyBase

var graph: RefCounted = null
var bounds: Array[float] = []
var target_pos: Vector2 = Vector2.ZERO
var current_speed: float = 0.0
var is_moving: bool = false

func _ready() -> void:
	if body == null and get_parent() is EnemyBase:
		body = get_parent() as EnemyBase

func move_to(target: Vector2, speed: float) -> void:
	target_pos = target
	current_speed = speed
	is_moving = true

func stop() -> void:
	is_moving = false
	current_speed = 0.0
	if body != null:
		body.velocity.x = 0.0

func _physics_process(_delta: float) -> void:
	if not is_moving or body == null:
		return

	if graph != null:
		# Graph mode added in Phase 4 (P4-T4)
		push_warning("PlatformMover: graph mode STUB")
		return

	# Flat mode: horizontal movement on current floor
	var dx: float = target_pos.x - body.global_position.x
	if absf(dx) < 6.0:
		stop()
		arrived.emit()
		return

	var move_dir: int = 1 if dx > 0.0 else -1
	body.face(move_dir)

	# Check custom bounds
	if bounds.size() >= 2:
		if move_dir < 0 and body.global_position.x <= bounds[0]:
			stop()
			path_failed.emit()
			return
		elif move_dir > 0 and body.global_position.x >= bounds[1]:
			stop()
			path_failed.emit()
			return

	# Check wall collision
	if body.is_on_wall():
		var wall_n: Vector2 = body.get_wall_normal()
		if (move_dir > 0 and wall_n.x < -0.5) or (move_dir < 0 and wall_n.x > 0.5):
			stop()
			path_failed.emit()
			return

	# Check ledge (downward raycast 20 px ahead at feet)
	if body.is_on_floor():
		var space_state: PhysicsDirectSpaceState2D = body.get_world_2d().direct_space_state
		if space_state != null:
			var p_start: Vector2 = body.global_position + Vector2(float(move_dir) * 20.0, 0.0)
			var p_end: Vector2 = body.global_position + Vector2(float(move_dir) * 20.0, 32.0)
			var query := PhysicsRayQueryParameters2D.create(p_start, p_end, 3)
			var hit := space_state.intersect_ray(query)
			if hit.is_empty():
				stop()
				path_failed.emit()
				return

	body.velocity.x = float(move_dir) * current_speed
	body.move_and_slide()

func patrol_segment() -> Vector2:
	if bounds.size() >= 2:
		return Vector2(bounds[0], bounds[1])

	if body == null:
		return Vector2.ZERO

	var start_x: float = body.global_position.x
	var min_x: float = start_x - 160.0
	var max_x: float = start_x + 160.0

	var space_state: PhysicsDirectSpaceState2D = body.get_world_2d().direct_space_state
	if space_state != null:
		# Probe left for wall or ledge
		var step: float = 16.0
		var cur_x: float = start_x
		while cur_x > start_x - 400.0:
			var next_x: float = cur_x - step
			# Wall query
			var q_wall := PhysicsRayQueryParameters2D.create(Vector2(cur_x, body.global_position.y), Vector2(next_x, body.global_position.y), 1)
			if not space_state.intersect_ray(q_wall).is_empty():
				min_x = cur_x
				break
			# Floor query
			var q_floor := PhysicsRayQueryParameters2D.create(Vector2(next_x, body.global_position.y), Vector2(next_x, body.global_position.y + 32.0), 3)
			if space_state.intersect_ray(q_floor).is_empty():
				min_x = cur_x
				break
			cur_x = next_x
			min_x = cur_x

		# Probe right for wall or ledge
		cur_x = start_x
		while cur_x < start_x + 400.0:
			var next_x: float = cur_x + step
			# Wall query
			var q_wall := PhysicsRayQueryParameters2D.create(Vector2(cur_x, body.global_position.y), Vector2(next_x, body.global_position.y), 1)
			if not space_state.intersect_ray(q_wall).is_empty():
				max_x = cur_x
				break
			# Floor query
			var q_floor := PhysicsRayQueryParameters2D.create(Vector2(next_x, body.global_position.y), Vector2(next_x, body.global_position.y + 32.0), 3)
			if space_state.intersect_ray(q_floor).is_empty():
				max_x = cur_x
				break
			cur_x = next_x
			max_x = cur_x

	return Vector2(min_x, max_x)
