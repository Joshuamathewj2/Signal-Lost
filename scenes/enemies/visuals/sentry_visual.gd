class_name SentryVisual
extends Node2D

@onready var head: Node2D = $Head

var is_laser_active: bool = false
var laser_target: Vector2 = Vector2.ZERO

func set_aim_angle(rad: float) -> void:
	if head != null:
		head.rotation = rad

func set_laser(active: bool, target: Vector2) -> void:
	is_laser_active = active
	laser_target = target
	queue_redraw()

func _draw() -> void:
	if is_laser_active:
		var local_tgt: Vector2 = to_local(laser_target)
		draw_dashed_line(Vector2.ZERO, local_tgt, Color(1.0, 0.2, 0.2, 0.4), 1.0, 6.0)

func flash() -> void:
	var tween := create_tween()
	modulate = Color(2.0, 2.0, 2.0, 1.0)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)

func set_alert(_val: float) -> void:
	pass
