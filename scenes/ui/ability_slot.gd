class_name AbilitySlot
extends Control

@export var ability_name: String = "decoy"
@export var key_badge_text: String = "F"
@export var is_locked: bool = false
@export var is_active: bool = true

func _ready() -> void:
	custom_minimum_size = Vector2(44, 44)

func set_locked(locked: bool) -> void:
	is_locked = locked
	queue_redraw()

func set_active(active: bool) -> void:
	is_active = active
	queue_redraw()

func _draw() -> void:
	var danger_col: Color = Palette.color(&"danger")
	var track_col: Color = Palette.color(&"track")
	var bg_col: Color = Palette.color(&"bg")

	var icon_col: Color = danger_col if (not is_locked and is_active) else track_col
	var badge_col: Color = danger_col if (not is_locked and is_active) else track_col

	# 1. Silhouette of ability
	if ability_name == "decoy":
		# Beacon base
		draw_rect(Rect2(12, 34, 20, 4), icon_col, true)
		var ped := PackedVector2Array([Vector2(14, 34), Vector2(17, 26), Vector2(27, 26), Vector2(30, 34)])
		draw_colored_polygon(ped, icon_col)
		# Mast
		draw_rect(Rect2(20, 15, 4, 11), icon_col, true)
		# Bulb head
		draw_circle(Vector2(22, 15), 4.5, icon_col)
		# Antenna tip
		draw_line(Vector2(22, 10), Vector2(22, 6), icon_col, 1.5)
	else:
		# EMP / Secondary slot
		draw_arc(Vector2(22, 22), 12.0, 0.0, TAU, 24, icon_col, 1.0)
		var bolt := PackedVector2Array([
			Vector2(24, 13),
			Vector2(19, 21),
			Vector2(25, 21),
			Vector2(20, 31)
		])
		draw_polyline(bolt, icon_col, 1.5)

	# 2. KeyBadge: 14x14 top-right box
	var badge_rect := Rect2(30, 0, 14, 14)
	draw_rect(badge_rect, bg_col, true)
	draw_rect(Rect2(30.5, 0.5, 13, 13), badge_col, false, 1.0)

	var font: Font = get_theme_font("font")
	if font == null:
		font = ThemeDB.fallback_font
	if font != null:
		draw_string(font, Vector2(30, 11), key_badge_text, HORIZONTAL_ALIGNMENT_CENTER, 14, 11, badge_col)
