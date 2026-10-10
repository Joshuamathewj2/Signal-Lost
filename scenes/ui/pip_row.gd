class_name PipRow
extends HBoxContainer

@export var max_pips: int = 3
@export var current_pips: int = 3

var _pip_controls: Array[Control] = []

func _ready() -> void:
	add_theme_constant_override("separation", 6)
	_rebuild_pips()

func set_pips(current: int, maximum: int = -1) -> void:
	if maximum > 0:
		max_pips = maximum
	current_pips = clampi(current, 0, max_pips)
	_rebuild_pips()

func _rebuild_pips() -> void:
	# Clear existing children if count changed
	while _pip_controls.size() < max_pips:
		var pip := Control.new()
		pip.custom_minimum_size = Vector2(8, 8)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var idx: int = _pip_controls.size()
		pip.draw.connect(func() -> void: _draw_pip(pip, idx))
		add_child(pip)
		_pip_controls.append(pip)

	while _pip_controls.size() > max_pips:
		var removed: Control = _pip_controls.pop_back()
		if removed != null:
			removed.queue_free()

	for ctrl in _pip_controls:
		ctrl.queue_redraw()

func _draw_pip(pip: Control, index: int) -> void:
	var white_col: Color = Palette.color(&"white")
	var is_filled: bool = index < current_pips
	var pts := PackedVector2Array([
		Vector2(4.0, 0.0),
		Vector2(8.0, 4.0),
		Vector2(4.0, 8.0),
		Vector2(0.0, 4.0)
	])

	if is_filled:
		pip.draw_colored_polygon(pts, white_col)
	else:
		pts.append(pts[0])
		pip.draw_polyline(pts, white_col, 1.0)
