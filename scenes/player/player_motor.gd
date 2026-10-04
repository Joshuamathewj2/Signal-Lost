class_name PlayerMotor
extends Node

signal landed(impact_speed: float)
signal jumped

@export var body: CharacterBody2D
@export var collision_shape: CollisionShape2D
@export var ceiling_ray: RayCast2D
@export var visual: PlayerVisual

var is_sneaking: bool = false
var is_crouching: bool = false
var is_on_floor: bool = false
var facing: int = 1
var is_charging: bool = false
var input_enabled: bool = true

func _ready() -> void:
	if body != null:
		body.floor_snap_length = 6.0
		body.up_direction = Vector2.UP

func _physics_process(delta: float) -> void:
	if body == null:
		return

	var cfg: GameConfigData = GameConfig.data

	# Read Input
	var dir: float = 0.0
	var want_sneak: bool = false
	if input_enabled:
		dir = Input.get_axis(&"move_left", &"move_right")
		want_sneak = Input.is_action_pressed(&"sneak")

	# Crouch & Sneak Handling
	if want_sneak and body.is_on_floor():
		_set_crouch(true)
	elif not want_sneak:
		if ceiling_ray != null and ceiling_ray.is_colliding():
			_set_crouch(true)
		else:
			_set_crouch(false)

	is_sneaking = is_crouching and body.is_on_floor()

	# Facing
	if dir > 0.05:
		facing = 1
	elif dir < -0.05:
		facing = -1

	# Horizontal target velocity
	var speed: float = cfg.sneak_speed if is_sneaking else cfg.run_speed
	if is_charging:
		speed *= cfg.charge_move_mult
	var target_vx: float = dir * speed

	if body.is_on_floor():
		if dir != 0.0:
			body.velocity.x = move_toward(body.velocity.x, target_vx, cfg.ground_accel * delta)
		else:
			body.velocity.x = move_toward(body.velocity.x, 0.0, cfg.ground_friction * delta)
	else:
		if dir != 0.0:
			body.velocity.x = move_toward(body.velocity.x, target_vx, cfg.air_accel * delta)

	# Vertical velocity / Gravity
	if not body.is_on_floor():
		var g: float = cfg.gravity
		if body.velocity.y > 0.0:
			g *= cfg.fall_gravity_mult
		body.velocity.y += g * delta
		body.velocity.y = minf(body.velocity.y, cfg.max_fall_speed)

	# Move and Slide
	var was_on_floor: bool = body.is_on_floor()
	var pre_vy: float = body.velocity.y

	body.move_and_slide()

	is_on_floor = body.is_on_floor()
	if not was_on_floor and is_on_floor:
		landed.emit(pre_vy)

	# Update visual
	if visual != null:
		visual.set_facing(facing)
		if not is_on_floor:
			visual.set_pose(&"jump" if body.velocity.y < 0.0 else &"fall")
		elif is_crouching:
			visual.set_pose(&"sneak" if absf(body.velocity.x) > 5.0 else &"crouch")
		elif absf(body.velocity.x) > 5.0:
			visual.set_pose(&"run")
		else:
			visual.set_pose(&"idle")

func _set_crouch(crouched: bool) -> void:
	if is_crouching == crouched:
		return
	is_crouching = crouched
	if collision_shape != null and collision_shape.shape is CapsuleShape2D:
		var capsule: CapsuleShape2D = collision_shape.shape as CapsuleShape2D
		if is_crouching:
			capsule.height = 12.0
			collision_shape.position.y = 3.0
		else:
			capsule.height = 18.0
			collision_shape.position.y = 0.0
