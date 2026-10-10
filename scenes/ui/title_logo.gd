class_name TitleLogo
extends Control

@onready var ring_back: Control = $RingBack
@onready var signal_label: Label = $TitleGroup/SignalLabel
@onready var lost_label: Label = $TitleGroup/LostLabel

var glitch_material: ShaderMaterial = null
var wipe_tween: Tween = null
var glitch_tween: Tween = null

var glitch_timer: float = 3.5
var next_glitch: float = 4.0

var ring_timer: float = 0.0
var ring_radius: float = 0.0
var ring_alpha: float = 0.0
var ring_tween: Tween = null

func _ready() -> void:
	custom_minimum_size = Vector2(580, 110)

	if ring_back != null:
		ring_back.draw.connect(_on_ring_back_draw)

	var mat_res: Shader = load("res://shaders/title_glitch.gdshader") as Shader
	if mat_res != null:
		glitch_material = ShaderMaterial.new()
		glitch_material.shader = mat_res
		glitch_material.set_shader_parameter(&"reveal", 0.0)
		glitch_material.set_shader_parameter(&"glitch", 0.0)
		glitch_material.set_shader_parameter(&"wipe_center", Vector2(0.5, 0.5))

		if signal_label != null:
			signal_label.material = glitch_material
		if lost_label != null:
			var mat_lost: ShaderMaterial = glitch_material.duplicate()
			mat_lost.set_shader_parameter(&"wipe_center", Vector2(0.0, 0.5))
			lost_label.material = mat_lost
			# For signal label, wipe expands from right seam
			glitch_material.set_shader_parameter(&"wipe_center", Vector2(1.0, 0.5))

	# 1.2s sonar wipe on entrance
	trigger_wipe()

func trigger_wipe() -> void:
	if wipe_tween != null and wipe_tween.is_valid():
		wipe_tween.kill()
	wipe_tween = create_tween()
	wipe_tween.tween_method(func(v: float) -> void:
		_set_uniform(&"reveal", v)
	, 0.0, 1.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_trigger_sonar_ring()

func _set_uniform(param: StringName, value: Variant) -> void:
	if signal_label != null and signal_label.material is ShaderMaterial:
		(signal_label.material as ShaderMaterial).set_shader_parameter(param, value)
	if lost_label != null and lost_label.material is ShaderMaterial:
		(lost_label.material as ShaderMaterial).set_shader_parameter(param, value)

func _process(delta: float) -> void:
	# Glitch spike every 3-6 s
	glitch_timer += delta
	if glitch_timer >= next_glitch:
		glitch_timer = 0.0
		next_glitch = randf_range(3.0, 6.0)
		_trigger_glitch_spike()

	# Sonar ring behind title every 4 s
	ring_timer += delta
	if ring_timer >= 4.0:
		ring_timer = 0.0
		_trigger_sonar_ring()

	if ring_back != null and ring_alpha > 0.01:
		ring_back.queue_redraw()

func _trigger_glitch_spike() -> void:
	if glitch_tween != null and glitch_tween.is_valid():
		glitch_tween.kill()
	glitch_tween = create_tween()
	glitch_tween.tween_method(func(v: float) -> void:
		_set_uniform(&"glitch", v)
	, 1.0, 1.0, 0.08)
	glitch_tween.tween_method(func(v: float) -> void:
		_set_uniform(&"glitch", v)
	, 1.0, 0.0, 0.04)

func _trigger_sonar_ring() -> void:
	if ring_tween != null and ring_tween.is_valid():
		ring_tween.kill()
	ring_radius = 0.0
	ring_alpha = 0.85
	ring_tween = create_tween()
	ring_tween.parallel().tween_property(self, "ring_radius", 260.0, 1.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	ring_tween.parallel().tween_property(self, "ring_alpha", 0.0, 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	ring_tween.tween_callback(func() -> void:
		if ring_back != null:
			ring_back.queue_redraw()
	)

func _on_ring_back_draw() -> void:
	if ring_back == null or ring_alpha <= 0.01:
		return
	var center := size * 0.5
	ring_back.draw_arc(center, ring_radius, 0.0, TAU, 64, Color(1, 1, 1, ring_alpha), 1.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_INTERNAL_PROCESS:
		if ring_back != null and ring_alpha > 0.01:
			ring_back.queue_redraw()
