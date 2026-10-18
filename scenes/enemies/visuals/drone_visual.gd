class_name DroneVisual
extends Node2D

## DroneVisual
## Visual for the airborne Drone surveillance unit:
## Floating aerodynamic octagonal chassis, pulsating optic core, stabilizer fins,
## and a 0.6s laser telegraph sightline.

@onready var tell_label: Label = $TellLabel
@onready var chassis: Polygon2D = $Chassis
@onready var eye: Polygon2D = $Eye

var is_telegraphing: bool = false
var telegraph_target: Vector2 = Vector2.ZERO
var telegraph_progress: float = 0.0
var flash_tween: Tween = null
var hover_time: float = 0.0

func _ready() -> void:
	if tell_label != null:
		tell_label.visible = false

func _process(delta: float) -> void:
	hover_time += delta
	# Subtle hover bob
	position.y = sin(hover_time * 4.0) * 2.5
	if is_telegraphing:
		queue_redraw()

func _draw() -> void:
	if is_telegraphing:
		var rel_target := to_local(telegraph_target)
		var beam_alpha := clampf(telegraph_progress, 0.2, 1.0)
		var beam_width := 1.5 if telegraph_progress < 0.8 else 3.0
		var col := Color(1.0, 0.15, 0.15, beam_alpha)
		draw_line(Vector2.ZERO, rel_target, col, beam_width)
		draw_circle(rel_target, 3.0 * beam_alpha, Color(1.0, 0.3, 0.3, beam_alpha))

func start_telegraph(target_global: Vector2) -> void:
	is_telegraphing = true
	telegraph_target = target_global
	telegraph_progress = 0.0
	var tw := create_tween()
	tw.tween_property(self, "telegraph_progress", 1.0, 0.6)

func stop_telegraph() -> void:
	is_telegraphing = false
	telegraph_progress = 0.0
	queue_redraw()

func flash() -> void:
	if chassis == null:
		return
	if flash_tween != null and flash_tween.is_valid():
		flash_tween.kill()
	var orig_col := chassis.color
	chassis.color = Color.WHITE
	flash_tween = create_tween()
	flash_tween.tween_property(chassis, "color", orig_col, 0.12)

func set_alert(val: float) -> void:
	if eye != null:
		eye.color = Color(0.4 + 0.6 * val, 0.1 * (1.0 - val), 0.1 * (1.0 - val), 1.0)
