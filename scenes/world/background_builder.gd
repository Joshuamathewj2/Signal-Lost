class_name BackgroundBuilder
extends RefCounted

static func build(parent: Node2D, map_rect: Rect2, seed_val: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val

	var layer_configs: Array[Dictionary] = [
		{ "name": "FarLayer", "scroll": Vector2(0.35, 0.35), "z": -30, "color_key": &"far" },
		{ "name": "MidLayer", "scroll": Vector2(0.60, 0.60), "z": -20, "color_key": &"mid" },
		{ "name": "NearLayer", "scroll": Vector2(0.85, 0.85), "z": -10, "color_key": &"near" },
	]

	var tile_size: float = 32.0
	var step_x: float = tile_size * 3.0 # ~1 prop every 3 tiles horizontally

	for cfg in layer_configs:
		var p_layer: Parallax2D = Parallax2D.new()
		p_layer.name = cfg["name"]
		p_layer.scroll_scale = cfg["scroll"]
		p_layer.repeat_size = Vector2.ZERO
		p_layer.z_index = cfg["z"]
		parent.add_child(p_layer)

		var color: Color = Palette.color(cfg["color_key"]) if Palette != null else Color.GRAY

		var x: float = map_rect.position.x + rng.randf_range(10.0, step_x)
		while x < map_rect.end.x - 20.0:
			var y: float = map_rect.position.y + rng.randf_range(40.0, map_rect.size.y - 60.0)
			var prop: Node2D = BgPropFactory.make_random_prop(Vector2(x, y), color, rng, map_rect.size.y)
			p_layer.add_child(prop)
			x += rng.randf_range(step_x * 0.7, step_x * 1.3)
