class_name BruteVisual
extends Node2D

const FONT: Font = preload("res://assets/fonts/Rajdhani-SemiBold.ttf")

@onready var poly: Polygon2D = $Silhouette
@onready var tell_label: Label = $TellLabel

var tell_tween: Tween = null
var stun_timer: float = 0.0
var original_poly_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	if tell_label != null:
		tell_label.visible = false
		tell_label.add_theme_font_override(&"font", FONT)
		tell_label.add_theme_font_size_override(&"font_size", 14)
		var mat := CanvasItemMaterial.new()
		mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		tell_label.material = mat
		tell_label.pivot_offset = Vector2(10.0, 10.0)

	if poly != null:
		original_poly_pos = poly.position

func _process(delta: float) -> void:
	if stun_timer > 0.0:
		stun_timer -= delta
		if poly != null:
			# Head shake ±8° at 10 Hz (sin(t * 2 * PI * 10))
			poly.rotation = sin(stun_timer * TAU * 10.0) * deg_to_rad(8.0)
		if stun_timer <= 0.0:
			stun_timer = 0.0
			if poly != null:
				poly.rotation = 0.0
				poly.position = original_poly_pos

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

func show_stun(duration: float = 1.2) -> void:
	stun_timer = duration

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
