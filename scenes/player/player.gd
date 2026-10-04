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

func _physics_process(_delta: float) -> void:
	if not is_alive:
		return
	if battery != null and pulse_charger != null and motor != null:
		battery.is_still = absf(velocity.x) < 5.0 and is_on_floor()
		battery.is_charging = pulse_charger.is_charging
		motor.is_charging = pulse_charger.is_charging


func _ready() -> void:
	add_to_group(&"player")
	# Layer 3: player; Masks: 1 (world), 2 (one_way), 5 (interactable)
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(3, true)
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, true)
	set_collision_mask_value(5, true)

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
