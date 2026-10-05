class_name Smudge
extends Node2D

@onready var rect: ColorRect = $ColorRect

var target_enemy: Node2D = null
var current_tween: Tween = null

func _process(_delta: float) -> void:
	if not visible:
		return

	if target_enemy != null and is_instance_valid(target_enemy):
		global_position = target_enemy.global_position

	# Hide if enemy is revealed by pulse
	if PulseRegistry != null and PulseRegistry.reveal_at(global_position) > 0.25:
		visible = false

func show_at(pos: Vector2, enemy: Node2D = null) -> void:
	global_position = pos
	target_enemy = enemy
	visible = true

	if rect != null and rect.material is ShaderMaterial:
		var mat: ShaderMaterial = rect.material as ShaderMaterial
		mat.set_shader_parameter(&"opacity", 0.5)

		if current_tween != null and current_tween.is_valid():
			current_tween.kill()

		current_tween = create_tween()
		current_tween.tween_method(func(v: float) -> void:
			if rect != null and rect.material != null:
				(rect.material as ShaderMaterial).set_shader_parameter(&"opacity", v)
		, 0.5, 0.0, 1.2)
		current_tween.tween_callback(func() -> void:
			visible = false
		)
