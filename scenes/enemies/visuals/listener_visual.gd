class_name ListenerVisual
extends Node2D

const FONT: Font = preload("res://assets/fonts/Rajdhani-SemiBold.ttf")

@onready var poly: Polygon2D = $Silhouette
@onready var antenna: Line2D = $Antenna
@onready var antenna_tip: Polygon2D = $AntennaTip
@onready var tell_label: Label = $TellLabel

var tell_tween: Tween = null
var spin_tween: Tween = null
var anim_time: float = 0.0

func _ready() -> void:
	if tell_label != null:
		tell_label.visible = false
		tell_label.add_theme_font_override(&"font", FONT)
		tell_label.add_theme_font_size_override(&"font_size", 14)
		var mat := CanvasItemMaterial.new()
		mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		tell_label.material = mat
		tell_label.pivot_offset = Vector2(10.0, 10.0)

func _process(delta: float) -> void:
	anim_time += delta
	# Slight antenna wobble
	if antenna != null and (spin_tween == null or not spin_tween.is_valid()):
		antenna.rotation = sin(anim_time * 2.5) * deg_to_rad(6.0)

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

	# Spin dish 360° on alert
	if antenna != null:
		if spin_tween != null and spin_tween.is_valid():
			spin_tween.kill()
		spin_tween = create_tween()
		spin_tween.tween_property(antenna, "rotation", antenna.rotation + TAU, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func set_alert(val: float) -> void:
	if poly != null and poly.material is ShaderMaterial:
		(poly.material as ShaderMaterial).set_shader_parameter(&"alert", clampf(val, 0.0, 1.0))

func flash() -> void:
	if poly != null and poly.material is ShaderMaterial:
		var mat: ShaderMaterial = poly.material as ShaderMaterial
		mat.set_shader_parameter(&"flash", 1.0)
		var t: Tween = create_tween()
		t.tween_method(func(v: float) -> void:
			if poly != null and poly.material != null:
				(poly.material as ShaderMaterial).set_shader_parameter(&"flash", v)
		, 1.0, 0.0, 0.2)
