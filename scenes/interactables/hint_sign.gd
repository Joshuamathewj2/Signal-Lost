class_name HintSign
extends Node2D

const FLAT_REVEAL_SHADER: Shader = preload("res://shaders/flat_reveal.gdshader")
const RAJDHANI_FONT: Font = preload("res://assets/fonts/Rajdhani-SemiBold.ttf")

@export var hint_text: String = "HOLD [K] / LMB"

var _material: ShaderMaterial = null
var _player_nearby: bool = false

func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = FLAT_REVEAL_SHADER
	_material.set_shader_parameter(&"tint", Color.WHITE)
	material = _material
	queue_redraw()

func set_text(text: String) -> void:
	hint_text = text
	queue_redraw()

func _process(_delta: float) -> void:
	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		return
	var dist: float = global_position.distance_to(player.global_position)
	var nearby: bool = dist <= 96.0
	if nearby != _player_nearby:
		_player_nearby = nearby
		if _player_nearby:
			var hud: Node = get_tree().get_first_node_in_group(&"hud")
			if hud != null and hud.has_method("show_tutorial_prompt"):
				hud.call("show_tutorial_prompt", hint_text)
		queue_redraw()

func _draw() -> void:
	# Compact in-world terminal beacon: sleek 8px diamond with acoustic glyph
	var col := Palette.color(&"white")
	var r: float = 8.0
	var pts := PackedVector2Array([
		Vector2(0, -r),
		Vector2(r, 0),
		Vector2(0, r),
		Vector2(-r, 0)
	])
	draw_colored_polygon(pts, Color(0.04, 0.04, 0.04, 0.95))
	draw_polyline(pts, col, 1.2)
	draw_line(Vector2(-r, 0), Vector2(0, -r), col, 1.2)

	# Question mark glyph inside
	var font: Font = RAJDHANI_FONT
	var sz := font.get_string_size("?", HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
	draw_string(font, Vector2(-sz.x * 0.5, sz.y * 0.35), "?", HORIZONTAL_ALIGNMENT_CENTER, -1, 13, col)

	if _player_nearby:
		var wave_r: float = 12.0 + sin(Time.get_ticks_msec() * 0.006) * 3.0
		draw_arc(Vector2.ZERO, wave_r, 0.0, TAU, 16, col * 0.5, 1.0)
