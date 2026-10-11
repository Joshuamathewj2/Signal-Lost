class_name RippleRings
extends Node2D

const MAX_RIPPLES: int = 24
const RIPPLE_DURATION: float = 0.8

var _active_ripples: Array[Dictionary] = []

func _ready() -> void:
	var mat: CanvasItemMaterial = CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = mat

	if NoiseBus != null and not NoiseBus.noise_emitted.is_connected(_on_noise_emitted):
		NoiseBus.noise_emitted.connect(_on_noise_emitted)

func _on_noise_emitted(event: NoiseEvent) -> void:
	if event == null:
		return
	if event.source_type == NoiseEvent.NoiseType.PULSE:
		return

	var base_col: Color = Palette.color(&"white") if Palette != null else Color.WHITE
	if event.source_type == NoiseEvent.NoiseType.ENEMY:
		base_col = Palette.color(&"smudge") if Palette != null else Color(0.35, 0.0, 0.0, 1.0)

	var ripple: Dictionary = {
		"pos": event.position,
		"max_radius": clampf(event.radius, 10.0, 160.0),
		"age": 0.0,
		"color": base_col
	}

	_active_ripples.append(ripple)
	while _active_ripples.size() > MAX_RIPPLES:
		_active_ripples.pop_front()

func _process(delta: float) -> void:
	if _active_ripples.is_empty():
		return

	var i: int = _active_ripples.size() - 1
	while i >= 0:
		var r: Dictionary = _active_ripples[i]
		r["age"] = float(r.get("age", 0.0)) + delta
		if r["age"] >= RIPPLE_DURATION:
			_active_ripples.remove_at(i)
		i -= 1

	queue_redraw()

func _draw() -> void:
	for r in _active_ripples:
		var age: float = float(r.get("age", 0.0))
		var progress: float = clampf(age / RIPPLE_DURATION, 0.0, 1.0)
		var pos: Vector2 = r.get("pos", Vector2.ZERO)
		var rel_pos: Vector2 = pos - global_position
		var base_col: Color = r.get("color", Color.WHITE)
		var max_r: float = float(r.get("max_radius", 60.0))

		# 3 concentric expanding arcs
		var r1: float = max_r * progress
		var a1: float = 0.6 * (1.0 - progress)
		if r1 > 1.0 and a1 > 0.01:
			draw_arc(rel_pos, r1, 0.0, TAU, 32, Color(base_col.r, base_col.g, base_col.b, a1), 1.5)

		var r2: float = max_r * progress * 0.7
		var a2: float = 0.35 * (1.0 - progress)
		if r2 > 1.0 and a2 > 0.01:
			draw_arc(rel_pos, r2, 0.0, TAU, 28, Color(base_col.r, base_col.g, base_col.b, a2), 1.0)

		var r3: float = max_r * progress * 0.4
		var a3: float = 0.2 * (1.0 - progress)
		if r3 > 1.0 and a3 > 0.01:
			draw_arc(rel_pos, r3, 0.0, TAU, 24, Color(base_col.r, base_col.g, base_col.b, a3), 1.0)
