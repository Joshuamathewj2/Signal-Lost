class_name SentryVisual
extends Node2D

const FONT: Font = preload("res://assets/fonts/Rajdhani-SemiBold.ttf")

@onready var head: Node2D = $Head

var is_laser_active: bool = false
var laser_target: Vector2 = Vector2.ZERO
var tell_label: Label = null
var tell_tween: Tween = null

func _ready() -> void:
	tell_label = Label.new()
	tell_label.add_theme_font_override(&"font", FONT)
	tell_label.add_theme_font_size_override(&"font_size", 14)
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	tell_label.material = mat
	tell_label.offset_left = -10.0
	tell_label.offset_top = -36.0
	tell_label.offset_right = 10.0
	tell_label.offset_bottom = -16.0
	tell_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tell_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tell_label.pivot_offset = Vector2(10.0, 10.0)
	tell_label.visible = false
	add_child(tell_label)

func set_aim_angle(rad: float) -> void:
	if head != null:
		head.rotation = rad

func recoil() -> void:
	if head != null:
		var dir := Vector2.RIGHT.rotated(head.rotation)
		head.position = -dir * 3.0
		var t := create_tween()
		t.tween_property(head, "position", Vector2.ZERO, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func set_laser(active: bool, target: Vector2) -> void:
	is_laser_active = active
	laser_target = target
	queue_redraw()

func _draw() -> void:
	if is_laser_active:
		var local_tgt: Vector2 = to_local(laser_target)
		draw_dashed_line(Vector2.ZERO, local_tgt, Color(1.0, 0.2, 0.2, 0.4), 1.0, 6.0)

func show_tell(type: StringName) -> void:
	if tell_label == null:
		return

	tell_label.text = "?" if type == &"question" else "!"
	tell_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	tell_label.scale = Vector2.ZERO
	tell_label.visible = true

	if tell_tween != null and tell_tween.is_valid():
		tell_tween.kill()

	tell_tween = create_tween()
	tell_tween.tween_property(tell_label, "scale", Vector2(1.3, 1.3), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tell_tween.tween_property(tell_label, "scale", Vector2(1.0, 1.0), 0.08)
	tell_tween.tween_interval(0.6)
	tell_tween.tween_property(tell_label, "modulate:a", 0.0, 0.2)
	tell_tween.tween_callback(func() -> void:
		if tell_label != null:
			tell_label.visible = false
	)

	flash()

func flash() -> void:
	var tween := create_tween()
	modulate = Color(2.0, 2.0, 2.0, 1.0)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)

func set_alert(_val: float) -> void:
	pass
