class_name BruteVisual
extends Node2D

@onready var poly: Polygon2D = $Silhouette
@onready var tell_label: Label = $TellLabel

var tell_timer: float = 0.0
var stun_timer: float = 0.0
var original_poly_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	if tell_label != null:
		tell_label.visible = false
	if poly != null:
		original_poly_pos = poly.position

func _process(delta: float) -> void:
	if tell_timer > 0.0:
		tell_timer -= delta
		if tell_timer <= 0.0:
			tell_timer = 0.0
			if tell_label != null:
				tell_label.visible = false

	if stun_timer > 0.0:
		stun_timer -= delta
		if poly != null:
			# Shake head left-right
			var offset_x: float = sin(stun_timer * 35.0) * 3.0
			poly.position = original_poly_pos + Vector2(offset_x, 0.0)
		if stun_timer <= 0.0:
			stun_timer = 0.0
			if poly != null:
				poly.position = original_poly_pos

func show_tell(type: StringName) -> void:
	if tell_label == null:
		return
	if type == &"exclamation":
		tell_label.text = "!"
		tell_label.modulate = Color(1.0, 0.1, 0.1, 1.0)
	elif type == &"question":
		tell_label.text = "?"
		tell_label.modulate = Color(1.0, 0.8, 0.2, 1.0)
	tell_label.visible = true
	tell_timer = 0.6

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
