class_name Lantern
extends Node2D

@export var cell: Vector2i = Vector2i.ZERO

@onready var pivot: Node2D = $Pivot
@onready var lamp: Polygon2D = $Pivot/Lamp

var theta: float = 0.0
var omega: float = 0.0
const K_SPRING: float = 18.0
const C_DAMPING: float = 1.6

var clink_cooldown: float = 0.0

func _ready() -> void:
	add_to_group(&"wave_reactive")

func _physics_process(delta: float) -> void:
	if clink_cooldown > 0.0:
		clink_cooldown -= delta

	# Damped angular spring: alpha = -k * theta - c * omega
	var alpha: float = -K_SPRING * theta - C_DAMPING * omega
	omega += alpha * delta
	theta += omega * delta

	if pivot != null:
		pivot.rotation = theta

	if absf(omega) > 2.0 and clink_cooldown <= 0.0:
		clink_cooldown = 1.5
		var lamp_pos: Vector2 = lamp.global_position if lamp != null else global_position
		var noise_ev := NoiseEvent.make(lamp_pos, 96.0, 1.0, NoiseEvent.NoiseType.CLINK, self)
		NoiseBus.emit_noise_event(noise_ev)

func on_wavefront(profile: PulseProfile, origin: Vector2) -> void:
	var dx: float = global_position.x - origin.x
	var dir_sign: float = 1.0 if dx >= 0.0 else -1.0

	var impulse: float = 0.6
	if profile.id == &"scream":
		impulse = 4.0
	elif profile.id == &"normal":
		impulse = 1.8
	elif profile.id == &"whisper":
		impulse = 0.6

	omega += impulse * dir_sign
