class_name WorldReticle
extends Node2D

enum Type {
	PROJECTILE = 0,
	NOISE_ORIGIN = 1,
	DECOY = 2
}

@export var reticle_type: Type = Type.PROJECTILE
@export var radius: float = 10.0

var pulse_time: float = 0.0
var noise_timer: float = 0.0
var is_active: bool = true
var enemy_ref: Node2D = null

func setup_noise(target_pos: Vector2, enemy: Node2D = null) -> void:
	reticle_type = Type.NOISE_ORIGIN
	global_position = target_pos
	enemy_ref = enemy
	noise_timer = 1.0
	is_active = true
	visible = true

func deactivate() -> void:
	is_active = false
	visible = false

func _process(delta: float) -> void:
	if reticle_type == Type.NOISE_ORIGIN:
		if not is_active:
			visible = false
			return

		pulse_time += delta
		noise_timer = maxf(0.0, noise_timer - delta)

		# Pulses r 10 -> 14 at 2 Hz
		radius = 12.0 + 2.0 * sin(pulse_time * 2.0 * TAU)

		# Shown when enemy is revealed or 1 s after the noise
		var enemy_revealed: bool = false
		if enemy_ref != null and is_instance_valid(enemy_ref) and PulseRegistry != null:
			enemy_revealed = PulseRegistry.reveal_at(enemy_ref.global_position) > 0.25
		elif enemy_ref != null and not is_instance_valid(enemy_ref):
			queue_free()
			return

		visible = enemy_revealed or noise_timer > 0.0

	queue_redraw()

func _draw() -> void:
	var white_col: Color = Palette.color(&"white")
	var danger_col: Color = Palette.color(&"danger")
	var tick_col: Color = danger_col if reticle_type == Type.PROJECTILE else white_col

	# 1 px white circle r = radius
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, white_col, 1.0)

	# 4 cardinal tick marks (length 3 px)
	draw_line(Vector2(0.0, -radius), Vector2(0.0, -radius - 3.0), tick_col, 1.0)
	draw_line(Vector2(0.0, radius), Vector2(0.0, radius + 3.0), tick_col, 1.0)
	draw_line(Vector2(-radius, 0.0), Vector2(-radius - 3.0, 0.0), tick_col, 1.0)
	draw_line(Vector2(radius, 0.0), Vector2(radius + 3.0, 0.0), tick_col, 1.0)
