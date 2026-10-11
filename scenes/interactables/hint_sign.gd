class_name HintSign
extends Node2D

const FLAT_REVEAL_SHADER: Shader = preload("res://shaders/flat_reveal.gdshader")

@export var hint_text: String = "HOLD [K] / LMB"

var _material: ShaderMaterial = null

func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = FLAT_REVEAL_SHADER
	_material.set_shader_parameter(&"tint", Color.WHITE)
	material = _material
	queue_redraw()

func set_text(text: String) -> void:
	hint_text = text
	queue_redraw()

const RAJDHANI_FONT: Font = preload("res://assets/fonts/Rajdhani-SemiBold.ttf")

func _draw() -> void:
	var font: Font = RAJDHANI_FONT
	var font_size: int = 15
	var text_sz: Vector2 = font.get_string_size(hint_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)

	var pad_x: float = 8.0
	var pad_y: float = 6.0
	var w: float = text_sz.x + pad_x * 2.0
	var h: float = text_sz.y + pad_y * 2.0
	var rect := Rect2(-w * 0.5, -h * 0.5, w, h)

	# Black background
	draw_rect(rect, Color(0.04, 0.04, 0.04, 0.95), true)
	# 1 px white border
	draw_rect(rect, Palette.color(&"white"), false, 1.0)

	# Text
	var text_pos := Vector2(-text_sz.x * 0.5, text_sz.y * 0.3)
	draw_string(font, text_pos, hint_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Palette.color(&"white"))
