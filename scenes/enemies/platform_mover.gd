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

# --- Intent mode (body has a Fighter) ---------------------------------------
# The mover never touches velocity: it writes the Fighter's intent (walk / jump /
# drop) and the Fighter moves the body with the same physics as the hero.
var fighter: Fighter = null
var home_pos: Vector2 = Vector2.ZERO
var stuck_time: float = 1.5          ## data/enemies/<kind>.json nav.stuck_time
var launch_distance: float = 40.0    ## nav.launch_distance: start a jump edge this close
var allow_home_teleport: bool = true ## nav.home_teleport
var ledge_clearance: float = 14.0    ## nav.ledge_clearance: extra px above a lip when climbing
var _stuck_timer: float = 0.0
var _stuck_strikes: int = 0
var _best_dist: float = INF
var _turn_timer: float = 0.0

func _ready() -> void:
	if body == null and get_parent() is EnemyBase:
		body = get_parent() as EnemyBase
	if body != null:
		fighter = body.get_node_or_null("Fighter") as Fighter
		home_pos = body.global_position


func configure_nav(nav: Dictionary) -> void:
	stuck_time = float(nav.get("stuck_time", stuck_time))
	launch_distance = float(nav.get("launch_distance", launch_distance))
	allow_home_teleport = bool(nav.get("home_teleport", allow_home_teleport))
	ledge_clearance = float(nav.get("ledge_clearance", ledge_clearance))

func move_to(target: Vector2, speed: float) -> void:
	target_pos = target
	current_speed = speed
	is_moving = true

	if fighter != null:
		fighter.speed_mult = clampf(speed / maxf(fighter.stats.run_speed, 1.0), 0.1, 2.0)
		_best_dist = INF
		_stuck_timer = 0.0

	if graph != null and body != null:
		var can_j: bool = body.profile.can_jump if body.profile != null else true
		var path_res: Dictionary
		if fighter != null and fighter.stats.can_jump and can_j:
			# Only edges this fighter can physically make (jump height / gap from JSON).
			path_res = graph.find_path_capable(body.global_position, target,
					fighter.stats.jump_apex() - 8.0, fighter.stats.max_gap + 32.0)
		else:
			path_res = graph.find_path(body.global_position, target, can_j and (fighter == null or fighter.stats.can_jump))
		current_path = path_res.get("points", PackedVector2Array())
		current_path_types.assign(path_res.get("types", []))
		current_path_idx = 1 if current_path.size() > 1 else 0
		if current_path.is_empty() and fighter == null:
			stop()
			path_failed.emit()
		# Fighters without a graph route fall back to raycast navigation (_flat_intent).

func stop() -> void:
	is_moving = false
	current_speed = 0.0
	current_path.clear()
	current_path_types.clear()
	current_path_idx = 0
	if body != null and fighter == null:
		body.velocity.x = 0.0
	if fighter != null:
		fighter.intent.move_dir = 0.0

func _physics_process(delta: float) -> void:
	if fighter != null:
		_process_intent(delta)
		return
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
		if body.is_on_floor() and absf(dx) < 48.0:
			var g: float = GameConfig.data.gravity if (GameConfig != null and GameConfig.data != null) else 1800.0
			var rise_px: float = maxf(dy, 0.0) + 24.0
			var v_y: float = -sqrt(2.0 * g * rise_px)
			body.velocity.y = v_y
			var t_up: float = -v_y / g
			var fall_dist: float = maxf(rise_px - dy, 0.0)
			var t_dn: float = sqrt(2.0 * fall_dist / g)
			var total_t: float = maxf(t_up + t_dn, 0.25)
			body.velocity.x = dx / total_t
	elif edge_type == 2: # DROP
		if body.is_on_floor() and absf(dx) < 16.0:
			body.set_collision_mask_value(2, false)
			get_tree().create_timer(0.25).timeout.connect(func() -> void:
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

# --- Intent mode --------------------------------------------------------------

func _process_intent(delta: float) -> void:
	var it: FighterIntent = fighter.intent
	it.move_dir = 0.0
	if not is_moving or body == null:
		return
	if _turn_timer > 0.0:
		# Anti-stuck strike 2: back off the obstacle briefly.
		_turn_timer -= delta
		it.move_dir = float(-body.facing)
		return
	if graph != null and not current_path.is_empty():
		_follow_path_intent(it)
	else:
		_flat_intent(it)
	if is_moving:
		_check_stuck(delta, it)


func _follow_path_intent(it: FighterIntent) -> void:
	if current_path_idx >= current_path.size():
		stop()
		arrived.emit()
		return
	var wp: Vector2 = current_path[current_path_idx]
	var edge_type: int = current_path_types[current_path_idx] if current_path_idx < current_path_types.size() else 0
	var feet: Vector2 = fighter.feet_position()
	var dx: float = wp.x - feet.x
	var dy: float = feet.y - wp.y
	var on_floor: bool = body.is_on_floor()

	var arrived_wp: bool = absf(dx) < 6.0 if edge_type == PlatformGraph.EdgeType.WALK else (absf(dx) < 10.0 and absf(dy) < 16.0 and on_floor)
	if arrived_wp:
		current_path_idx += 1
		_best_dist = INF
		if current_path_idx >= current_path.size():
			stop()
			arrived.emit()
			return
		wp = current_path[current_path_idx]
		edge_type = current_path_types[current_path_idx] if current_path_idx < current_path_types.size() else 0
		dx = wp.x - feet.x
		dy = feet.y - wp.y

	var dir: int = 1 if dx > 0.0 else -1
	it.move_dir = float(dir)
	if edge_type == PlatformGraph.EdgeType.JUMP and on_floor and not fighter.ballistic_flight:
		# Take off from the edge's start node (or the lip, if the ground ends first),
		# never from "near the landing" - that is already over the gap.
		var takeoff: Vector2 = current_path[current_path_idx - 1] if current_path_idx > 0 else feet
		var at_takeoff: bool = absf(feet.x - takeoff.x) <= 6.0 or (signf(feet.x - takeoff.x) == float(dir))
		if (at_takeoff or not fighter.probe_ground_ahead(dir, 10.0)) and absf(dx) <= launch_distance + 192.0:
			_jump_to(it, wp)
	elif edge_type == PlatformGraph.EdgeType.DROP and on_floor and absf(dx) < 16.0 and dy < -8.0:
		it.drop_through = true


## Graph-less navigation from raycasts: jump gaps <= max_gap, climb ledges within
## jump height when the target is above, drop down when the target is below.
func _flat_intent(it: FighterIntent) -> void:
	var feet: Vector2 = fighter.feet_position()
	var dx: float = target_pos.x - feet.x
	var dy: float = feet.y - target_pos.y
	if absf(dx) < 6.0 and absf(dy) < 24.0:
		stop()
		arrived.emit()
		return
	var dir: int = 1 if dx > 0.0 else -1
	it.move_dir = float(dir)
	if not body.is_on_floor() or fighter.ballistic_flight:
		return
	var st: FighterStats = fighter.stats
	if fighter.probe_wall(dir):
		var rise: float = fighter.probe_ledge_rise(dir)
		if st.can_jump and rise > 0.0 and rise <= st.jump_apex() - 6.0:
			_jump_to(it, fighter.feet_position() + Vector2(float(dir) * 28.0, -rise))
		else:
			stop()
			path_failed.emit()
		return
	if not fighter.probe_ground_ahead(dir, 12.0):
		if dy < -24.0:
			return # target is below: just walk off the edge
		var gap: float = fighter.probe_gap_width(dir, st.max_gap + 48.0)
		if st.can_jump and gap <= st.max_gap:
			_jump_to(it, fighter.feet_position() + Vector2(float(dir) * (gap + 28.0), 0.0))
		else:
			stop()
			path_failed.emit()


## Jump toward a feet position. Up onto a ledge: rise to lip height + clearance
## and air-steer over it (like the hero). Level / downward gaps: computed arc.
## Fallback: a full held jump.
func _jump_to(it: FighterIntent, target_feet: Vector2) -> void:
	if fighter.jump_cooldown_timer > 0.0 or not fighter.stats.can_jump:
		return
	var rise: float = fighter.feet_position().y - target_feet.y
	if rise > 4.0:
		if fighter.jump_to_height(rise + ledge_clearance):
			return
	var v: Vector2 = fighter.ballistic_to(target_feet)
	if v != Vector2.INF:
		fighter.launch(v)
	else:
		it.jump_pressed = true
		it.jump_held = true


## Anti-stuck: no progress toward the waypoint for `stuck_time` seconds ->
## 1st strike jump, 2nd strike back off + repath, 3rd strike teleport home.
func _check_stuck(delta: float, it: FighterIntent) -> void:
	var goal: Vector2 = target_pos
	if not current_path.is_empty() and current_path_idx < current_path.size():
		goal = current_path[current_path_idx]
	var d: float = body.global_position.distance_to(goal)
	if d < _best_dist - 2.0:
		_best_dist = d
		_stuck_timer = 0.0
		return
	_stuck_timer += delta
	if _stuck_timer < stuck_time:
		return
	_stuck_timer = 0.0
	_best_dist = INF
	_stuck_strikes += 1
	if _stuck_strikes == 1:
		it.jump_pressed = true
		it.jump_held = true
	elif _stuck_strikes == 2:
		_turn_timer = 0.4
		var t: Vector2 = target_pos
		var sp: float = current_speed
		get_tree().create_timer(0.45).timeout.connect(func() -> void:
			if is_instance_valid(body) and is_moving:
				move_to(t, sp)
		)
	else:
		_stuck_strikes = 0
		if allow_home_teleport and home_pos != Vector2.ZERO:
			body.global_position = home_pos
			body.velocity = Vector2.ZERO
		stop()
		path_failed.emit()


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


static func calculate_jump_velocity(from_pos: Vector2, to_pos: Vector2, gravity: float = 980.0, apex_margin: float = 24.0) -> Vector2:
	var highest_y: float = minf(from_pos.y, to_pos.y) - apex_margin
	var h1: float = from_pos.y - highest_y
	var h2: float = to_pos.y - highest_y
	var vy0: float = -sqrt(2.0 * gravity * maxf(h1, 10.0))
	var t_up: float = absf(vy0) / gravity
	var t_down: float = sqrt(2.0 * maxf(h2, 10.0) / gravity)
	var total_t: float = maxf(t_up + t_down, 0.1)
	var vx: float = (to_pos.x - from_pos.x) / total_t
	return Vector2(vx, vy0)

