class_name PlatformMover
extends Node

signal arrived
signal path_failed

@export var body: EnemyBase

var graph: PlatformGraph = null
var bounds: Array[float] = []
var target_pos: Vector2 = Vector2.ZERO
var current_speed: float = 0.0
var is_moving: bool = false

var current_path: PackedVector2Array = PackedVector2Array()
var current_path_types: Array[int] = []
var current_path_idx: int = 0
var repath_timer: float = 0.0

func _ready() -> void:
	if body == null and get_parent() is EnemyBase:
		body = get_parent() as EnemyBase

func move_to(target: Vector2, speed: float) -> void:
	target_pos = target
	current_speed = speed
	is_moving = true

	if graph != null and body != null:
		var can_j: bool = body.profile.can_jump if body.profile != null else true
		var path_res: Dictionary = graph.find_path(body.global_position, target, can_j)
		current_path = path_res.get("points", PackedVector2Array())
		current_path_types = path_res.get("types", [])
		current_path_idx = 1 if current_path.size() > 1 else 0
		if current_path.is_empty():
			stop()
			path_failed.emit()

func stop() -> void:
	is_moving = false
	current_speed = 0.0
	current_path.clear()
	current_path_types.clear()
	current_path_idx = 0
	if body != null:
		body.velocity.x = 0.0

func _physics_process(_delta: float) -> void:
	if not is_moving or body == null:
		return

	if graph != null:
		_process_graph_mode()
	else:
		_process_flat_mode()

func _process_graph_mode() -> void:
	if current_path.is_empty() or current_path_idx >= current_path.size():
		stop()
		arrived.emit()
		return

	var wp: Vector2 = current_path[current_path_idx]
	var edge_type: int = current_path_types[current_path_idx] if current_path_idx < current_path_types.size() else 0
	var dx: float = wp.x - body.global_position.x
	var dy: float = body.global_position.y - wp.y

	# Check waypoint arrival
	var arrived_wp: bool = false
	if edge_type == 0: # WALK
		arrived_wp = absf(dx) < 6.0
	else: # JUMP or DROP
		arrived_wp = absf(dx) < 10.0 and absf(dy) < 16.0 and body.is_on_floor()

	if arrived_wp:
		current_path_idx += 1
		if current_path_idx >= current_path.size():
			stop()
			arrived.emit()
			return
		wp = current_path[current_path_idx]
		edge_type = current_path_types[current_path_idx] if current_path_idx < current_path_types.size() else 0
		dx = wp.x - body.global_position.x
		dy = body.global_position.y - wp.y

	var move_dir: int = 1 if dx > 0.0 else -1
	body.face(move_dir)
	body.velocity.x = float(move_dir) * current_speed

	if edge_type == 1: # JUMP
		if body.is_on_floor() and absf(dx) < 32.0:
			var g: float = GameConfig.data.gravity if (GameConfig != null and GameConfig.data != null) else 1800.0
			var rise_px: float = maxf(dy, 0.0) + 20.0
			body.velocity.y = -sqrt(2.0 * g * rise_px)
	elif edge_type == 2: # DROP
		if body.is_on_floor() and absf(dx) < 12.0:
			body.set_collision_mask_value(2, false)
			get_tree().create_timer(0.2).timeout.connect(func() -> void:
				if is_instance_valid(body):
					body.set_collision_mask_value(2, true)
			)

	body.move_and_slide()

func _process_flat_mode() -> void:
	var dx: float = target_pos.x - body.global_position.x
	if absf(dx) < 6.0:
		stop()
		arrived.emit()
		return

	var move_dir: int = 1 if dx > 0.0 else -1
	body.face(move_dir)

	if bounds.size() >= 2:
		if move_dir < 0 and body.global_position.x <= bounds[0]:
			stop()
			path_failed.emit()
			return
		elif move_dir > 0 and body.global_position.x >= bounds[1]:
			stop()
			path_failed.emit()
			return

	if body.is_on_wall():
		var wall_n: Vector2 = body.get_wall_normal()
		if (move_dir > 0 and wall_n.x < -0.5) or (move_dir < 0 and wall_n.x > 0.5):
			stop()
			path_failed.emit()
			return

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
		var step: float = 16.0
		var cur_x: float = start_x
		while cur_x > start_x - 400.0:
			var next_x: float = cur_x - step
			var q_wall := PhysicsRayQueryParameters2D.create(Vector2(cur_x, body.global_position.y), Vector2(next_x, body.global_position.y), 1)
			if not space_state.intersect_ray(q_wall).is_empty():
				min_x = cur_x
				break
			var q_floor := PhysicsRayQueryParameters2D.create(Vector2(next_x, body.global_position.y), Vector2(next_x, body.global_position.y + 32.0), 3)
			if space_state.intersect_ray(q_floor).is_empty():
				min_x = cur_x
				break
			cur_x = next_x
			min_x = cur_x

		cur_x = start_x
		while cur_x < start_x + 400.0:
			var next_x: float = cur_x + step
			var q_wall := PhysicsRayQueryParameters2D.create(Vector2(cur_x, body.global_position.y), Vector2(next_x, body.global_position.y), 1)
			if not space_state.intersect_ray(q_wall).is_empty():
				max_x = cur_x
				break
			var q_floor := PhysicsRayQueryParameters2D.create(Vector2(next_x, body.global_position.y), Vector2(next_x, body.global_position.y + 32.0), 3)
			if space_state.intersect_ray(q_floor).is_empty():
				max_x = cur_x
				break
			cur_x = next_x
			max_x = cur_x

	return Vector2(min_x, max_x)
