class_name Player
extends CharacterBody2D

signal player_died(cause: StringName)

@onready var motor: PlayerMotor = $PlayerMotor
@onready var visual: PlayerVisual = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var ceiling_ray: RayCast2D = $CeilingRay
@onready var battery: Battery = $Battery
@onready var pulse_charger: PulseCharger = $PulseCharger
@onready var footstep_emitter: FootstepEmitter = $FootstepEmitter
@onready var health: HealthComponent = get_node_or_null("HealthComponent") as HealthComponent
@onready var poise: PoiseComponent = get_node_or_null("PoiseComponent") as PoiseComponent
@onready var combat: CombatController = get_node_or_null("CombatController") as CombatController
@onready var hurtbox: HurtboxComponent = get_node_or_null("HurtboxComponent") as HurtboxComponent

var is_alive: bool = true
var death_time: float = 0.6
var map_bottom: float = 2000.0

func _ready() -> void:
	add_to_group(&"player")
	# Layer 3: player; Masks: 1 (world), 2 (one_way), 5 (interactable)
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(3, true)
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, true)
	set_collision_mask_value(5, true)
	var glow: PointLight2D = get_node_or_null("GlowLight") as PointLight2D
	if glow != null and glow.texture == null:
		glow.texture = RevealTextureFactory.get_texture()

	if health != null:
		health.died.connect(func(cause: StringName) -> void:
			die(cause)
		)

	if pulse_charger != null:
		pulse_charger.charge_started.connect(func() -> void:
			if visual != null and visual.has_method("set_eye_state"):
				visual.set_eye_state(&"charge")
		)
		pulse_charger.pulse_released.connect(func(profile: PulseProfile, _pos: Vector2) -> void:
			GameState.register_pulse(profile)
			if visual != null and visual.has_method("set_eye_state"):
				visual.set_eye_state(&"normal")
		)
		pulse_charger.pulse_failed.connect(func() -> void:
			if visual != null and visual.has_method("set_eye_state"):
				visual.set_eye_state(&"normal")
		)

const DECOY_BEACON_SCENE: PackedScene = preload("res://scenes/interactables/decoy_beacon.tscn")

var _still_anchor_pos: Vector2 = Vector2.ZERO
var _still_timer: float = 0.0
var _showing_softlock_prompt: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if not is_alive:
		return
	if event.is_action_pressed("ability_primary"):
		throw_decoy()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		if _still_timer >= 20.0 or _showing_softlock_prompt:
			if SceneRouter != null and SceneRouter.has_method("restart_level"):
				SceneRouter.restart_level()

func throw_decoy() -> void:
	if GameState == null or GameState.decoy_count <= 0:
		return
	GameState.decoy_count -= 1
	var beacon: DecoyBeacon = DECOY_BEACON_SCENE.instantiate() as DecoyBeacon
	beacon.global_position = global_position + Vector2(0.0, -12.0)
	var facing_dir: float = float(motor.facing) if motor != null else 1.0
	beacon.velocity = Vector2(facing_dir * 380.0 * 0.7071, -380.0 * 0.7071)
	get_parent().add_child(beacon)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	if global_position.y > map_bottom + 200.0:
		die(&"fell")
		return

	if battery != null and pulse_charger != null and motor != null:
		battery.is_still = absf(velocity.x) < 5.0 and is_on_floor()
		battery.is_charging = pulse_charger.is_charging
		motor.is_charging = pulse_charger.is_charging

	# Anti-softlock safety net: unmoved > 1 tile for 20s while grounded and unaware
	if is_on_floor():
		if _still_anchor_pos == Vector2.ZERO:
			_still_anchor_pos = global_position
		elif global_position.distance_to(_still_anchor_pos) > 32.0:
			_still_anchor_pos = global_position
			_still_timer = 0.0
			_showing_softlock_prompt = false
		else:
			var alert_low: bool = (GameState != null and GameState.alert_level < 0.35 and not GameState.is_any_enemy_chasing)
			if alert_low:
				_still_timer += delta
				if _still_timer >= 20.0 and not _showing_softlock_prompt:
					_showing_softlock_prompt = true
					var hud: Node = get_tree().get_first_node_in_group(&"hud")
					if hud != null and hud.has_method("show_tutorial_prompt"):
						hud.show_tutorial_prompt("PRESS [R] TO RETURN TO CHECKPOINT")
	else:
		_still_timer = 0.0

func die(cause: StringName) -> void:
	if not is_alive:
		return
	is_alive = false
	player_died.emit(cause)
	DebugFlags.log("player", "Player died from cause: %s" % str(cause))

	if motor != null:
		motor.input_enabled = false
		velocity = Vector2.ZERO

	if visual != null:
		visual.play_death()
	else:
		hide()

	var timer := get_tree().create_timer(death_time)
	timer.timeout.connect(func() -> void:
		if SceneRouter != null:
			SceneRouter.restart_level()
	)

func intercept_hit(hostile_hitbox: Area2D) -> bool:
	if combat != null:
		return combat.intercept_hit(hostile_hitbox)
	return false

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> bool:
	if health != null:
		return health.take_damage(amount, knockback)
	die(&"caught")
	return true
