class_name LevelSelectBox
extends Button

signal level_chosen(level_index: int)

@export var level_index: int = 1:
	set(val):
		level_index = val
		queue_redraw()

var is_unlocked: bool = false:
	set(val):
		is_unlocked = val
		disabled = not is_unlocked
		focus_mode = FOCUS_ALL if is_unlocked else FOCUS_NONE
		queue_redraw()

var medal: StringName = &"none":
	set(val):
		medal = val
		queue_redraw()

var fragments_count: int = 0:
	set(val):
		fragments_count = val
		queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(120.0, 80.0)
	flat = true
	focus_mode = FOCUS_ALL if is_unlocked else FOCUS_NONE
	mouse_filter = MOUSE_FILTER_STOP if is_unlocked else MOUSE_FILTER_IGNORE
	mouse_entered.connect(_on_state_changed)
	mouse_exited.connect(_on_state_changed)
	focus_entered.connect(_on_state_changed)
	focus_exited.connect(_on_state_changed)
	pressed.connect(_on_pressed)

func _on_state_changed() -> void:
	if AudioManager != null and has_focus() and is_unlocked:
		AudioManager.play_sfx(&"ui_move")
	queue_redraw()

func _on_pressed() -> void:
	if not is_unlocked:
		return
	if AudioManager != null:
		AudioManager.play_sfx(&"ui_select")
	level_chosen.emit(level_index)

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var bg_col := Color(0.04, 0.04, 0.04, 0.9)
	draw_rect(rect, bg_col, true)

	var border_col: Color
	if not is_unlocked:
		border_col = Color(0.24, 0.24, 0.24) # #3D3D3D
	elif has_focus() or is_hovered():
		border_col = Palette.color(&"danger") # #E00000
	else:
		border_col = Palette.color(&"actor_subtle")

	draw_rect(rect, border_col, false, 1.0)

	var text_col: Color = Color(0.24, 0.24, 0.24) if not is_unlocked else Color(0.9, 0.9, 0.9)
	var font: Font = get_theme_default_font()
	var font_size: int = 14

	# Title: LEVEL 01
	var title_text := "LEVEL %02d" % level_index
	var title_pos := Vector2(size.x * 0.5 - font.get_string_size(title_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x * 0.5, 20.0)
	draw_string(font, title_pos, title_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_col)

	# Medal glyph
	var center := Vector2(size.x * 0.5, size.y * 0.5)
	if is_unlocked:
		_draw_medal_glyph(center, text_col)

	# Bottom text: fragments or LOCKED
	var bot_text: String
	if not is_unlocked:
		bot_text = "LOCKED"
	else:
		bot_text = "%d/3" % fragments_count

	var bot_pos := Vector2(size.x * 0.5 - font.get_string_size(bot_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x * 0.5, size.y - 10.0)
	draw_string(font, bot_pos, bot_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_col)

func _draw_medal_glyph(center: Vector2, col: Color) -> void:
	var r: float = 7.0
	match medal:
		&"ghost":
			# Ghost Master: Solid filled circle with radiant acoustic halo ring
			draw_circle(center, r - 1.5, col)
			draw_arc(center, r + 2.5, 0.0, TAU, 24, col, 1.2, true)
		&"quiet":
			# Half filled circle: left filled, right hollow
			var pts: PackedVector2Array = [center]
			var steps: int = 12
			for i in range(steps + 1):
				var angle: float = PI * 0.5 + PI * float(i) / float(steps)
				pts.append(center + Vector2(cos(angle), sin(angle)) * r)
			pts.append(center)
			draw_colored_polygon(pts, col)
			draw_arc(center, r, -PI * 0.5, PI * 0.5, 12, col, 1.2, true)
		&"loud":
			# Hollow circle
			draw_arc(center, r, 0.0, TAU, 24, col, 1.2, true)
		_:
			# Unplayed clean dash
			draw_line(center + Vector2(-4.0, 0.0), center + Vector2(4.0, 0.0), Color(col.r, col.g, col.b, 0.35), 1.2)
