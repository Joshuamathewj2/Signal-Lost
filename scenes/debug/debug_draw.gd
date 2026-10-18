class_name DebugDraw
extends Node2D

class DrawItem:
	var type: StringName
	var a: Vector2
	var b: Vector2
	var radius: float
	var text: String
	var points: PackedVector2Array
	var color: Color
	var ttl: float

var _items: Array[DrawItem] = []

func _ready() -> void:
	z_index = 100

func circle(pos: Vector2, r: float, color: Color, ttl: float = 0.0) -> void:
	var it := DrawItem.new()
	it.type = &"circle"
	it.a = pos
	it.radius = r
	it.color = color
	it.ttl = ttl
	_items.append(it)
	queue_redraw()

func line(a: Vector2, b: Vector2, color: Color, ttl: float = 0.0) -> void:
	var it := DrawItem.new()
	it.type = &"line"
	it.a = a
	it.b = b
	it.color = color
	it.ttl = ttl
	_items.append(it)
	queue_redraw()

func rect(r: Rect2, color: Color, ttl: float = 0.0) -> void:
	var it := DrawItem.new()
	it.type = &"rect"
	it.a = r.position
	it.b = r.size
	it.color = color
	it.ttl = ttl
	_items.append(it)
	queue_redraw()

func text(pos: Vector2, s: String, ttl: float = 0.0) -> void:
	var it := DrawItem.new()
	it.type = &"text"
	it.a = pos
	it.text = s
	it.color = Color.WHITE
	it.ttl = ttl
	_items.append(it)
	queue_redraw()

func polyline(points: PackedVector2Array, color: Color, ttl: float = 0.0) -> void:
	var it := DrawItem.new()
	it.type = &"polyline"
	it.points = points
	it.color = color
	it.ttl = ttl
	_items.append(it)
	queue_redraw()

func _process(delta: float) -> void:
	if _items.is_empty():
		return

	var i := 0
	var changed := false
	while i < _items.size():
		var it := _items[i]
		if it.ttl > 0.0:
			it.ttl -= delta
			if it.ttl <= 0.0:
				_items.remove_at(i)
				changed = true
				continue
		else:
			# ttl <= 0 means 1 frame only
			_items.remove_at(i)
			changed = true
			continue
		i += 1

	if changed or not _items.is_empty():
		queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var font_size := ThemeDB.fallback_font_size

	for it in _items:
		match it.type:
			&"circle":
				draw_arc(it.a, it.radius, 0.0, TAU, 32, it.color, 1.0)
			&"line":
				draw_line(it.a, it.b, it.color, 1.0)
			&"rect":
				draw_rect(Rect2(it.a, it.b), it.color, false, 1.5)
			&"polyline":
				if it.points.size() >= 2:
					draw_polyline(it.points, it.color, 1.0)
			&"text":
				draw_string(font, it.a, it.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, it.color)
