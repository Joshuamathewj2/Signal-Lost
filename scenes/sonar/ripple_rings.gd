class_name RippleRings
extends Node2D

var ripples: Array[Dictionary] = []

func _ready() -> void:
	var mat: CanvasItemMaterial = CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = mat

	if NoiseBus != null:
		NoiseBus.noise_emitted.connect(_on_noise_emitted)

func _on_noise_emitted(event: NoiseEvent) -> void:
	if event.type == NoiseEvent.NoiseType.PULSE:
		return

	var base_col: Color = Palette.color(&"white") if Palette != null else Color.WHITE
	if event.type == NoiseEvent.NoiseType.ENEMY:
		base_col = Palette.color(&"smudge") if Palette != null else Color(0.35, 0.0, 0.0, 1.0)

	var ripple: Dictionary = {
		"pos": event.origin,
		"max_radius": minf(event.radius, 120.0),
		"age": 0.0,
		"color": base_col
	}

	ripples.append(ripple)
	if ripples.size() > 16:
		ripples.pop_front()

func _process(delta: float) -> void:
	var i: int = ripples.size() - 1
	while i >= 0:
		ripples[i]["age"] += delta
		if ripples[i]["age"] >= 0.8:
			ripples.remove_at(i)
		i -= 1
	queue_redraw()

func _draw() -> void:
	for r in ripples:
		var progress: float = clampf(r["age"] / 0.8, 0.0, 1.0)
		var rel_pos: Vector2 = r["pos"] - global_position
		var base_col: Color = r["color"]

		# 3 concentric expanding arcs
		var r1: float = r["max_radius"] * progress
		var a1: float = 0.6 * (1.0 - progress)
		if r1 > 1.0 and a1 > 0.01:
			draw_arc(rel_pos, r1, 0.0, TAU, 32, Color(base_col.r, base_col.g, base_col.b, a1), 1.0)

		var r2: float = r["max_radius"] * progress * 0.7
		var a2: float = 0.35 * (1.0 - progress)
		if r2 > 1.0 and a2 > 0.01:
			draw_arc(rel_pos, r2, 0.0, TAU, 28, Color(base_col.r, base_col.g, base_col.b, a2), 1.0)

		var r3: float = r["max_radius"] * progress * 0.4
		var a3: float = 0.2 * (1.0 - progress)
		if r3 > 1.0 and a3 > 0.01:
			draw_arc(rel_pos, r3, 0.0, TAU, 24, Color(base_col.r, base_col.g, base_col.b, a3), 1.0)
