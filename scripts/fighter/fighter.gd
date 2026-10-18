class_name Fighter
extends Node

## Fighter
## Shared locomotion layer for the hero AND every villain. Consumes a FighterIntent
## (player: filled from Input by PlayerMotor; enemies: filled by PlatformMover / AI)
## and owns: gravity, variable-height jump, coyote time, jump buffer, drop-through,
## crouch, dash (optionally telegraphed), knockback / control lock, and wall / ledge
## probes. Tuning comes from FighterStats (JSON).
##
## The player steps it manually (auto_step = false) to keep its exact frame order;
## enemies leave auto_step on and the Fighter moves the body every physics frame.

signal jumped
signal apex_reached          ## top of any jump/launch (jump-apex attacks hook here)
signal landed(impact_speed: float)
signal crouch_changed(crouched: bool)
signal dash_telegraphed(duration: float)
signal dash_started
signal dash_ended

enum DashPhase { NONE, TELEGRAPH, ACTIVE }

const WORLD_MASK: int = 1
const GROUND_MASK: int = 1 | 2

@export var body: CharacterBody2D
@export var ceiling_ray: RayCast2D
@export var auto_step: bool = true

var stats: FighterStats = FighterStats.new()
var intent: FighterIntent = FighterIntent.new()

var facing: int = 1
var is_on_floor: bool = false
var is_crouching: bool = false
var is_sneaking: bool = false
var speed_mult: float = 1.0
var locomotion_enabled: bool = true

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var drop_through_timer: float = 0.0
var jump_cooldown_timer: float = 0.0
var control_lock: float = 0.0
var jump_start_y: float = 0.0
var max_jump_height: float = 0.0
var ballistic_flight: bool = false  ## launched on a computed arc: keep vx until landing

var _feet_offset: float = -1.0

var dash_phase: DashPhase = DashPhase.NONE
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0


func _ready() -> void:
	if body == null:
		body = get_parent() as CharacterBody2D
	if auto_step:
		# Step after AI / PlatformMover (priority 0) have written this frame's intent.
		process_physics_priority = 10


func _physics_process(delta: float) -> void:
	if auto_step and body != null:
		if locomotion_enabled:
			step(delta)
		else:
			step_passive(delta, true)


func load_stats(json_path: String) -> bool:
	var d: Dictionary = DataLoader.load_json(json_path)
	if d.is_empty():
		return false
	stats = FighterStats.new().apply_dict(d, json_path)
	return true


## Full locomotion step driven by `intent`. Edge flags are consumed afterwards.
func step(delta: float) -> void:
	if body == null:
		return
	_tick_cooldowns(delta)

	var want_jump: bool = intent.jump_pressed

	# Drop through one-way platforms (layer 2): crouch + jump, or explicit AI request.
	if (intent.drop_through or (intent.crouch and want_jump)) and body.is_on_floor():
		if _standing_on_one_way():
			drop_through_timer = stats.drop_through_time
			body.set_collision_mask_value(2, false)
			want_jump = false

	if drop_through_timer > 0.0:
		drop_through_timer -= delta
		if drop_through_timer <= 0.0:
			body.set_collision_mask_value(2, true)

	if want_jump:
		jump_buffer_timer = stats.jump_buffer
	elif jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

	if body.is_on_floor():
		coyote_timer = stats.coyote_time
	elif coyote_timer > 0.0:
		coyote_timer -= delta

	if jump_buffer_timer > 0.0 and (body.is_on_floor() or coyote_timer > 0.0) and _can_jump_now():
		body.velocity.y = stats.jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		jump_cooldown_timer = stats.jump_cooldown
		jump_start_y = body.global_position.y
		max_jump_height = 0.0
		_set_crouch(false)
		jumped.emit()

	# Variable jump height: releasing early cuts the rise.
	if intent.jump_released and body.velocity.y < 0.0:
		body.velocity.y *= stats.jump_cut_mult

	if body.velocity.y < 0.0:
		max_jump_height = maxf(max_jump_height, jump_start_y - body.global_position.y)

	if body.is_on_floor():
		if intent.crouch:
			_set_crouch(true)
		else:
			_set_crouch(ceiling_ray != null and ceiling_ray.is_colliding())
	else:
		_set_crouch(false)
	is_sneaking = is_crouching and body.is_on_floor()

	var dir: float = intent.move_dir
	if dash_phase == DashPhase.NONE and control_lock <= 0.0:
		if dir > 0.05:
			facing = 1
		elif dir < -0.05:
			facing = -1

	if intent.dash_pressed:
		request_dash()

	_apply_horizontal(dir, delta)
	_apply_gravity(delta, true)
	_move()
	intent.consume_edges()


## Physics without player control (attack / hurt / takedown poses).
## attack_style mirrors the old motor: fall-gravity multiplier + fall-speed clamp.
func step_passive(delta: float, attack_style: bool) -> void:
	if body == null:
		return
	_tick_cooldowns(delta)
	body.velocity.x = move_toward(body.velocity.x, 0.0, stats.ground_friction * delta)
	if not body.is_on_floor():
		if attack_style:
			_apply_gravity(delta, true)
		else:
			body.velocity.y += stats.gravity * delta
	_move()
	intent.consume_edges()


func _tick_cooldowns(delta: float) -> void:
	if jump_cooldown_timer > 0.0:
		jump_cooldown_timer -= delta
	if control_lock > 0.0:
		control_lock -= delta
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
	if dash_phase != DashPhase.NONE:
		dash_timer -= delta
		if dash_timer <= 0.0:
			if dash_phase == DashPhase.TELEGRAPH:
				dash_phase = DashPhase.ACTIVE
				dash_timer = stats.dash_time
				dash_started.emit()
			else:
				dash_phase = DashPhase.NONE
				dash_cooldown_timer = stats.dash_cooldown
				dash_ended.emit()


func _apply_horizontal(dir: float, delta: float) -> void:
	if ballistic_flight and not body.is_on_floor():
		return
	if dash_phase == DashPhase.ACTIVE:
		body.velocity.x = float(facing) * stats.dash_speed
		return
	if dash_phase == DashPhase.TELEGRAPH:
		body.velocity.x = move_toward(body.velocity.x, 0.0, stats.ground_friction * delta)
		return
	if control_lock > 0.0:
		# Knockback slide: lighter friction so hits visibly carry the body.
		body.velocity.x = move_toward(body.velocity.x, 0.0, stats.knockback_friction * delta)
		return
	var speed: float = (stats.sneak_speed if is_sneaking else stats.run_speed) * speed_mult
	var target_vx: float = dir * speed
	if body.is_on_floor():
		if dir != 0.0:
			body.velocity.x = move_toward(body.velocity.x, target_vx, stats.ground_accel * delta)
		else:
			body.velocity.x = move_toward(body.velocity.x, 0.0, stats.ground_friction * delta)
	elif dir != 0.0:
		body.velocity.x = move_toward(body.velocity.x, target_vx, stats.air_accel * delta)


func _apply_gravity(delta: float, with_fall_mult: bool) -> void:
	if body.is_on_floor():
		return
	var g: float = stats.gravity
	if with_fall_mult and body.velocity.y > 0.0:
		g *= stats.fall_gravity_mult
	body.velocity.y += g * delta
	body.velocity.y = minf(body.velocity.y, stats.max_fall_speed)


func _move() -> void:
	var was_on_floor: bool = body.is_on_floor()
	var pre_vy: float = body.velocity.y
	body.move_and_slide()
	is_on_floor = body.is_on_floor()
	if not is_on_floor and pre_vy < 0.0 and body.velocity.y >= 0.0:
		apex_reached.emit()
	if not was_on_floor and is_on_floor:
		ballistic_flight = false
		landed.emit(pre_vy)


func _can_jump_now() -> bool:
	return stats.can_jump and jump_cooldown_timer <= 0.0 and dash_phase != DashPhase.ACTIVE and control_lock <= 0.0


func _standing_on_one_way() -> bool:
	for i in range(body.get_slide_collision_count()):
		var collider: Object = body.get_slide_collision(i).get_collider()
		if collider is CollisionObject2D and (collider as CollisionObject2D).get_collision_layer_value(2):
			return true
	return false


func _set_crouch(crouched: bool) -> void:
	if is_crouching == crouched:
		return
	is_crouching = crouched
	crouch_changed.emit(crouched)


# --- Actions -----------------------------------------------------------------

## Dash in the facing direction. With stats.dash_telegraph > 0 the fighter first
## freezes in a readable wind-up (enemy dashes must be telegraphed, >= 0.4 s).
func request_dash(skip_telegraph: bool = false) -> bool:
	if dash_phase != DashPhase.NONE or dash_cooldown_timer > 0.0:
		return false
	if control_lock > 0.0 and not skip_telegraph:
		return false
	control_lock = 0.0
	if stats.dash_telegraph > 0.0 and not skip_telegraph:
		dash_phase = DashPhase.TELEGRAPH
		dash_timer = stats.dash_telegraph
		dash_telegraphed.emit(stats.dash_telegraph)
	else:
		dash_phase = DashPhase.ACTIVE
		dash_timer = stats.dash_time
		dash_started.emit()
	return true


func is_dashing() -> bool:
	return dash_phase == DashPhase.ACTIVE


## Knockback / hit reaction: sets velocity and suspends steering for `lock` s.
func apply_knockback(impulse: Vector2, lock: float) -> void:
	if body == null:
		return
	body.velocity = impulse
	control_lock = maxf(control_lock, lock)
	if dash_phase != DashPhase.NONE:
		dash_phase = DashPhase.NONE
		dash_cooldown_timer = stats.dash_cooldown
		dash_ended.emit()


## Ballistic launch (pre-computed jump arc, e.g. JumpLink / graph jump edge).
func launch(velocity: Vector2) -> void:
	if body == null:
		return
	body.velocity = velocity
	ballistic_flight = velocity.y < 0.0
	jump_start_y = body.global_position.y
	jump_cooldown_timer = stats.jump_cooldown
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	jumped.emit()


## Jump straight up to `height` px (capped by this fighter's jump height) and keep
## normal air control - how the hero climbs a ledge: rise along the wall, then
## steer over the lip once the feet clear it.
func jump_to_height(height: float) -> bool:
	if body == null or not _can_jump_now():
		return false
	var h: float = minf(height, stats.jump_apex())
	body.velocity.y = -sqrt(2.0 * stats.gravity * maxf(h, 4.0))
	ballistic_flight = false
	jump_start_y = body.global_position.y
	jump_cooldown_timer = stats.jump_cooldown
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	_set_crouch(false)
	jumped.emit()
	return true


## Hop away from a threat (archers reposition, enemies dodge out). Lands
## `distance` px away when an arc is possible, otherwise a full jump with
## run-speed drift.
func jump_away(threat_x: float, distance: float = 96.0) -> bool:
	if body == null or not body.is_on_floor() or not _can_jump_now():
		return false
	var dir: float = signf(body.global_position.x - threat_x)
	if dir == 0.0:
		dir = float(-facing)
	facing = int(dir)
	var v: Vector2 = ballistic_to(feet_position() + Vector2(dir * distance, 0.0), 24.0)
	if v == Vector2.INF:
		v = Vector2(dir * stats.run_speed, stats.jump_velocity)
	launch(v)
	return true


## Distance from the body origin down to the bottom of its collision shape.
func feet_offset() -> float:
	if _feet_offset < 0.0:
		_feet_offset = 0.0
		for c in body.get_children():
			if c is CollisionShape2D and (c as CollisionShape2D).shape != null:
				var cs: CollisionShape2D = c as CollisionShape2D
				var r: Rect2 = cs.shape.get_rect()
				_feet_offset = cs.position.y + r.position.y + r.size.y
				break
	return _feet_offset


func feet_position() -> Vector2:
	return body.global_position + Vector2(0.0, feet_offset())


## Velocity for a jump whose feet land on `target` (feet position) with an apex
## margin, or Vector2.INF when the arc exceeds this fighter's jump height.
func ballistic_to(target: Vector2, apex_margin: float = 16.0) -> Vector2:
	var from: Vector2 = feet_position()
	var top: float = minf(from.y, target.y) - apex_margin
	var rise: float = from.y - top
	if rise > stats.jump_apex() + 0.5:
		return Vector2.INF
	var vy0: float = -sqrt(2.0 * stats.gravity * maxf(rise, 4.0))
	var t_up: float = -vy0 / stats.gravity
	var fall: float = maxf(target.y - top, 1.0)
	var t_down: float = sqrt(2.0 * fall / (stats.gravity * stats.fall_gravity_mult))
	var vx: float = (target.x - from.x) / maxf(t_up + t_down, 0.1)
	if absf(vx) > maxf(stats.run_speed, stats.dash_speed) * 1.25:
		return Vector2.INF
	return Vector2(vx, vy0)


# --- Probes (wall / ledge awareness) -----------------------------------------

func _ray(from: Vector2, to: Vector2, mask: int) -> Dictionary:
	var space: PhysicsDirectSpaceState2D = body.get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(from, to, mask, [body.get_rid()])
	return space.intersect_ray(q)


## Solid wall within `dist` px in `dir` at chest height.
func probe_wall(dir: int, dist: float = 14.0) -> bool:
	var p: Vector2 = body.global_position + Vector2(0.0, -4.0)
	return not _ray(p, p + Vector2(float(dir) * dist, 0.0), WORLD_MASK).is_empty()


## Ground exists `ahead` px in `dir` within one step down.
func probe_ground_ahead(dir: int, ahead: float = 16.0, depth: float = 40.0) -> bool:
	var p: Vector2 = feet_position() + Vector2(float(dir) * ahead, -4.0)
	return not _ray(p, p + Vector2(0.0, depth), GROUND_MASK).is_empty()


## Height (px, positive = up) of the surface just past a wall in `dir`, if it is
## reachable with a full jump. Returns -1 when there is no ledge in reach.
func probe_ledge_rise(dir: int, ahead: float = 24.0) -> float:
	var feet: Vector2 = feet_position()
	var top_y: float = feet.y - stats.jump_apex() - 4.0
	var x: float = feet.x + float(dir) * ahead
	var hit: Dictionary = _ray(Vector2(x, top_y), Vector2(x, feet.y + 2.0), GROUND_MASK)
	if hit.is_empty():
		return -1.0
	var rise: float = feet.y - (hit["position"] as Vector2).y
	return rise if rise > 2.0 else -1.0


## Width (px) of the gap starting `ahead` px in `dir`, scanning up to `max_scan`.
## Returns 0 when there is no gap and INF when no landing was found.
func probe_gap_width(dir: int, max_scan: float = 160.0, step_px: float = 8.0) -> float:
	var start: float = 12.0
	if probe_ground_ahead(dir, start):
		return 0.0
	var d: float = start
	while d <= max_scan:
		d += step_px
		if probe_ground_ahead(dir, d, 48.0):
			return d - start
	return INF
