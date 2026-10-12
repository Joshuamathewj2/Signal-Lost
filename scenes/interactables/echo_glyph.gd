class_name EchoGlyph
extends Node2D

## EchoGlyph
## Ancient acoustic wall runes revealed selectively by sonar pulse tiers:
## - Whisper: Cyan (Color(0.2, 0.9, 1.0))
## - Normal:  White (Color(1.0, 1.0, 1.0))
## - Scream:  Red   (Color(1.0, 0.25, 0.25))
## Incorrect tiers produce blurred low-alpha gibberish.

signal glyph_revealed(glyph: EchoGlyph, tier: StringName)

@export var required_tier: StringName = &"whisper"
@export var clue_text: String = ">>>"
@export var glyph_id: StringName = &"glyph_1"
@export var fade_duration: float = 4.0

var is_revealed: bool = false
var reveal_alpha: float = 0.0
var reveal_color: Color = Color.WHITE
var is_correct_tier: bool = false


func _ready() -> void:
	add_to_group(&"wave_reactive")
	add_to_group(&"echo_glyphs")


func on_wavefront(profile: PulseProfile, _origin: Vector2) -> void:
	if profile == null:
		return

	var pulse_tier: StringName = profile.id
	if pulse_tier == required_tier:
		is_revealed = true
		is_correct_tier = true
		reveal_alpha = 1.0
		match pulse_tier:
			&"whisper":
				reveal_color = Color(0.2, 0.9, 1.0) # Cyan
			&"normal":
				reveal_color = Color(1.0, 1.0, 1.0) # White
			&"scream":
				reveal_color = Color(1.0, 0.25, 0.25) # Danger Red
			_:
				reveal_color = Color.WHITE
		glyph_revealed.emit(self, pulse_tier)
	else:
		# Wrong tier: show dim blurred gibberish
		is_correct_tier = false
		reveal_alpha = 0.4
		reveal_color = Color(0.5, 0.5, 0.5, 0.4)

	queue_redraw()


func _process(delta: float) -> void:
	if reveal_alpha > 0.0:
		reveal_alpha = maxf(0.0, reveal_alpha - (delta / fade_duration))
		queue_redraw()


func _draw() -> void:
	if reveal_alpha <= 0.01:
		return

	var draw_col: Color = reveal_color
	draw_col.a *= reveal_alpha

	# Outer concentric rune circles
	draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 24, draw_col, 1.5)
	if is_correct_tier:
		draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 28, draw_col * 0.7, 1.0)
		# 4 tick marks
		for i in range(4):
			var ang: float = float(i) * (PI * 0.5)
			var p1: Vector2 = Vector2(cos(ang), sin(ang)) * 16.0
			var p2: Vector2 = Vector2(cos(ang), sin(ang)) * 22.0
			draw_line(p1, p2, draw_col, 1.5)

	# Central glyph pattern or clue text
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 14
	var text_to_draw: String = clue_text if is_correct_tier else "#?%!"
	var text_size: Vector2 = font.get_string_size(text_to_draw, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, Vector2(-text_size.x * 0.5, text_size.y * 0.35), text_to_draw, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, draw_col)
