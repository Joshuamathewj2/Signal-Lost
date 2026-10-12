class_name HarmonicLantern
extends Area2D

## HarmonicLantern
## Suspended acoustic lantern tuned to a musical pitch.
## Must be struck with weapons in sequential order. Emits 96 px chime noise on NoiseBus.

signal struck(lantern: HarmonicLantern, pitch_index: int)
signal triggered(lantern: HarmonicLantern)

@export var pitch_index: int = 1 # 1: High, 2: Mid, 3: Low
@export var pitch_name: String = "High"
@export var cord_length: float = 24.0

var is_rung: bool = false
var swing_angle: float = 0.0
var swing_velocity: float = 0.0


func _ready() -> void:
	add_to_group(&"harmonic_lanterns")
	add_to_group(&"interactable")
	add_to_group(&"wave_reactive")

	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(5, true) # interactable layer
	set_collision_mask_value(3, true) # player layer
	set_collision_mask_value(6, true) # hitbox layer

	var cs: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs == null:
		cs = CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 16.0
		cs.shape = circle
		cs.position = Vector2(0.0, cord_length)
		add_child(cs)


func on_hit(_hitbox: HitboxComponent) -> void:
	ring()


func on_wavefront(_profile: PulseProfile, origin: Vector2) -> void:
	# Subtle swing impulse from sonar shockwave
	var dir: float = signf(global_position.x - origin.x)
	swing_velocity += dir * 2.5


func ring() -> void:
	is_rung = true
	swing_velocity = 8.0

	# Emits clink chime noise on NoiseBus (r = 96 px, loudness 0.8)
	if NoiseBus != null:
		NoiseBus.emit_noise(NoiseEvent.make(global_position + Vector2(0.0, cord_length), 96.0, 0.8, NoiseEvent.NoiseType.CLINK, self))

	if AudioManager != null:
		AudioManager.play_sfx(&"decoy_bounce", global_position)

	struck.emit(self, pitch_index)
	triggered.emit(self)
	queue_redraw()


func reset() -> void:
	is_rung = false
	swing_angle = 0.0
	swing_velocity = 0.0
	queue_redraw()


func _physics_process(delta: float) -> void:
	# Damped angular spring
	var spring_k: float = 40.0
	var damping: float = 3.5
	var accel: float = -spring_k * swing_angle - damping * swing_velocity
	swing_velocity += accel * delta
	swing_angle += swing_velocity * delta

	if absf(swing_angle) > 0.01 or absf(swing_velocity) > 0.01:
		queue_redraw()


func _draw() -> void:
	var anchor := Vector2.ZERO
	var bob_pos := Vector2(sin(swing_angle) * cord_length, cos(swing_angle) * cord_length)

	# Cord
	draw_line(anchor, bob_pos, Color(0.6, 0.6, 0.6, 0.8), 1.0)

	# Lantern Bell
	var col: Color = Color(0.2, 0.9, 1.0) if is_rung else Color.WHITE
	draw_circle(bob_pos, 12.0, Color(0.05, 0.05, 0.05, 0.95))
	draw_arc(bob_pos, 12.0, 0.0, TAU, 20, col, 1.5)

	# Concentric pitch indicator ring
	var inner_r: float = 4.0 + float(pitch_index) * 2.5
	draw_arc(bob_pos, inner_r, 0.0, TAU, 16, col * 0.7, 1.0)
