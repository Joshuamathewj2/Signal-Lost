class_name HunterVisual
extends Node2D

@onready var poly: Polygon2D = $Silhouette
@onready var tell_label: Label = $TellLabel

var tell_timer: float = 0.0

func _ready() -> void:
	if tell_label != null:
		tell_label.visible = false

func _process(delta: float) -> void:
	if tell_timer > 0.0:
		tell_timer -= delta
		if tell_timer <= 0.0:
			tell_timer = 0.0
			if tell_label != null:
				tell_label.visible = false

func show_tell(type: StringName) -> void:
	if tell_label == null:
		return
	if type == &"question":
		tell_label.text = "?"
		tell_label.modulate = Color(1.0, 0.8, 0.2, 1.0)
	elif type == &"exclamation":
		tell_label.text = "!"
		tell_label.modulate = Color(1.0, 0.1, 0.1, 1.0)
	tell_label.visible = true
	tell_timer = 0.6

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
