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

	if pulse_charger != null:
		pulse_charger.pulse_released.connect(func(profile: PulseProfile, _pos: Vector2) -> void:
			GameState.register_pulse(profile)
		)

const DECOY_BEACON_SCENE: PackedScene = preload("res://scenes/interactables/decoy_beacon.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if not is_alive:
		return
	if event.is_action_pressed("ability_primary"):
		throw_decoy()

func throw_decoy() -> void:
	if GameState == null or GameState.decoy_count <= 0:
		return
	GameState.decoy_count -= 1
	var beacon: DecoyBeacon = DECOY_BEACON_SCENE.instantiate() as DecoyBeacon
	beacon.global_position = global_position + Vector2(0.0, -12.0)
	var facing_dir: float = float(motor.facing) if motor != null else 1.0
	beacon.velocity = Vector2(facing_dir * 380.0 * 0.7071, -380.0 * 0.7071)
	get_parent().add_child(beacon)

func _physics_process(_delta: float) -> void:
	if not is_alive:
		return

	if global_position.y > map_bottom + 200.0:
		die(&"fell")
		return

	if battery != null and pulse_charger != null and motor != null:
		battery.is_still = absf(velocity.x) < 5.0 and is_on_floor()
		battery.is_charging = pulse_charger.is_charging
		motor.is_charging = pulse_charger.is_charging

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
