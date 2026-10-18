class_name PlayerMotor
extends Node

signal landed(impact_speed: float)
signal jumped
signal state_changed(old_state: MotorState, new_state: MotorState)

enum MotorState {
	IDLE,
	RUN,
	JUMP,
	FALL,
	SNEAK,
	ATTACK_1,
	ATTACK_2,
	ATTACK_3,
	HEAVY,
	PARRY,
	HURT,
	DEAD,
	TAKEDOWN
}

@export var body: CharacterBody2D
@export var collision_shape: CollisionShape2D
@export var ceiling_ray: RayCast2D
@export var visual: PlayerVisual

var current_state: MotorState = MotorState.IDLE
var is_on_floor: bool = false
var is_charging: bool = false
var input_enabled: bool = true

## Shared locomotion layer (also used by villains). PlayerMotor only turns Input
## into a FighterIntent and maps the result onto poses / motor states.
var fighter: Fighter = null

# Forwarded so existing callers (combat, debug overlay, tests) keep working.
var facing: int:
	get: return fighter.facing if fighter != null else 1
	set(v):
		if fighter != null:
			fighter.facing = v
var is_sneaking: bool:
	get: return fighter.is_sneaking if fighter != null else false
var is_crouching: bool:
	get: return fighter.is_crouching if fighter != null else false
var coyote_timer: float:
	get: return fighter.coyote_timer if fighter != null else 0.0
var jump_buffer_timer: float:
	get: return fighter.jump_buffer_timer if fighter != null else 0.0
var drop_through_timer: float:
	get: return fighter.drop_through_timer if fighter != null else 0.0
var jump_start_y: float:
	get: return fighter.jump_start_y if fighter != null else 0.0
var max_jump_height: float:
	get: return fighter.max_jump_height if fighter != null else 0.0


func _init() -> void:
	fighter = Fighter.new()
	fighter.name = "Fighter"
	fighter.auto_step = false


func _notification(what: int) -> void:
	# A motor freed before entering the tree never adopted its Fighter.
	if what == NOTIFICATION_PREDELETE and fighter != null and fighter.get_parent() == null:
		fighter.free()


func _ready() -> void:
	if body != null:
		body.floor_snap_length = 6.0
		body.up_direction = Vector2.UP
	fighter.body = body
	fighter.ceiling_ray = ceiling_ray
	fighter.stats = FighterStats.new().apply_game_config(GameConfig.data)
	add_child(fighter)
	fighter.crouch_changed.connect(_on_crouch_changed)
	fighter.jumped.connect(func() -> void: jumped.emit())
	fighter.landed.connect(_on_fighter_landed)


func set_state(new_state: MotorState) -> void:
	if current_state == new_state:
		return
	var old_state := current_state
	current_state = new_state
	state_changed.emit(old_state, new_state)


func is_locomotion_state() -> bool:
	return current_state in [MotorState.IDLE, MotorState.RUN, MotorState.JUMP, MotorState.FALL, MotorState.SNEAK]


func get_state_name(s: MotorState = current_state) -> String:
	match s:
		MotorState.IDLE: return "Idle"
		MotorState.RUN: return "Run"
		MotorState.JUMP: return "Jump"
		MotorState.FALL: return "Fall"
		MotorState.SNEAK: return "Sneak"
		MotorState.ATTACK_1: return "Attack1"
		MotorState.ATTACK_2: return "Attack2"
		MotorState.ATTACK_3: return "Attack3"
		MotorState.HEAVY: return "Heavy"
		MotorState.PARRY: return "Parry"
		MotorState.HURT: return "Hurt"
		MotorState.DEAD: return "Dead"
		MotorState.TAKEDOWN: return "Takedown"
	return "Unknown"


func _physics_process(delta: float) -> void:
	if body == null:
		return

	var cfg: GameConfigData = GameConfig.data

	# If DEAD, halt motion completely and never override poses
	if current_state == MotorState.DEAD:
		body.velocity = Vector2.ZERO
		return

	# HURT / TAKEDOWN: decelerate + plain gravity, poses untouched
	if current_state in [MotorState.HURT, MotorState.TAKEDOWN]:
		fighter.step_passive(delta, false)
		is_on_floor = fighter.is_on_floor
		return

	# Combat actions (ATTACK, HEAVY, PARRY): friction + fall gravity, poses untouched
	if current_state in [MotorState.ATTACK_1, MotorState.ATTACK_2, MotorState.ATTACK_3, MotorState.HEAVY, MotorState.PARRY]:
		fighter.step_passive(delta, true)
		is_on_floor = fighter.is_on_floor
		return

	# --- LOCOMOTION: Input -> FighterIntent -> Fighter ---
	var intent: FighterIntent = fighter.intent
	intent.clear()
	if input_enabled:
		intent.move_dir = Input.get_axis(&"move_left", &"move_right")
		intent.crouch = Input.is_action_pressed(&"sneak")
		intent.jump_pressed = Input.is_action_just_pressed(&"jump")
		intent.jump_held = Input.is_action_pressed(&"jump")
		intent.jump_released = Input.is_action_just_released(&"jump")
	fighter.speed_mult = cfg.charge_move_mult if is_charging else 1.0
	fighter.step(delta)
	is_on_floor = fighter.is_on_floor

	# Derive Locomotion State
	if not is_on_floor:
		current_state = MotorState.JUMP if body.velocity.y < 0.0 else MotorState.FALL
	elif is_crouching:
		current_state = MotorState.SNEAK
	elif absf(body.velocity.x) > 5.0:
		current_state = MotorState.RUN
	else:
		current_state = MotorState.IDLE

	# Update visual locomotion pose only when in locomotion state
	if visual != null:
		visual.set_facing(facing)
		match current_state:
			MotorState.JUMP:
				visual.set_pose(&"jump")
			MotorState.FALL:
				visual.set_pose(&"fall")
			MotorState.SNEAK:
				visual.set_pose(&"sneak" if absf(body.velocity.x) > 5.0 else &"crouch")
			MotorState.RUN:
				visual.set_pose(&"run")
			MotorState.IDLE:
				visual.set_pose(&"idle")


func _on_fighter_landed(impact_speed: float) -> void:
	landed.emit(impact_speed)
	if impact_speed > 250.0:
		ParticlesFactory.spawn_landing_dust(body.get_parent(), body.global_position)


func _on_crouch_changed(crouched: bool) -> void:
	_set_crouch(crouched)


func _set_crouch(crouched: bool) -> void:
	if collision_shape != null and collision_shape.shape is CapsuleShape2D:
		var capsule: CapsuleShape2D = collision_shape.shape as CapsuleShape2D
		if crouched:
			capsule.height = 12.0
			collision_shape.position.y = 3.0
		else:
			capsule.height = 18.0
			collision_shape.position.y = 0.0
