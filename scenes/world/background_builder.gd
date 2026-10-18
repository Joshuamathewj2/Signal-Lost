class_name BackgroundBuilder
extends RefCounted

## BackgroundBuilder
## Builds layered atmospheric feudal-cyberpunk parallax backgrounds (3 planes: z -30, -20, -10)
## with distinct architectural roles:
## - FarLayer: Colossal stone monoliths, tower cranes, distant citadel skyline.
## - MidLayer: Shoji screen lattices, steel gantries, spinning ventilation fans, machinery.
## - NearLayer: Conduits, steam vents, swaying hanging cables.

static func build(parent: Node2D, map_rect: Rect2, seed_val: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val

	var layer_configs: Array[Dictionary] = [
		{ "name": "FarLayer", "scroll": Vector2(0.25, 0.25), "z": -30, "color_key": &"far", "role": "far" },
		{ "name": "MidLayer", "scroll": Vector2(0.55, 0.55), "z": -20, "color_key": &"mid", "role": "mid" },
		{ "name": "NearLayer", "scroll": Vector2(0.80, 0.80), "z": -10, "color_key": &"near", "role": "near" },
	]

	# Extended bounds to prevent edge popping during camera scroll
	var span_x_start: float = map_rect.position.x - 300.0
	var span_x_end: float = map_rect.position.x + map_rect.size.x * 1.5 + 400.0
	var map_h: float = maxf(map_rect.size.y, 1080.0) + 300.0

	for cfg in layer_configs:
		if cfg["name"] == "NearLayer" and GameConfig != null and GameConfig.sonar_quality == 0:
			continue # ARCH §14 degrade order: parallax near layer off in LOW quality

		var p_layer: Parallax2D = Parallax2D.new()
		p_layer.name = cfg["name"]
		p_layer.scroll_scale = cfg["scroll"]
		p_layer.repeat_size = Vector2.ZERO
		p_layer.z_index = cfg["z"]
		parent.add_child(p_layer)

		var color: Color = Palette.color(cfg["color_key"]) if Palette != null else Color.GRAY
		var role: String = cfg["role"]

		match role:
			"far":
				_build_far_layer(p_layer, span_x_start, span_x_end, map_rect.position.y, map_h, color, rng)
			"mid":
				_build_mid_layer(p_layer, span_x_start, span_x_end, map_rect.position.y, map_h, color, rng)
			"near":
				_build_near_layer(p_layer, span_x_start, span_x_end, map_rect.position.y, map_h, color, rng)


static func _build_far_layer(layer: Node2D, x_start: float, x_end: float, y_base: float, h: float, color: Color, rng: RandomNumberGenerator) -> void:
	# 1. Distant Megacity / Citadel Skyline along the base
	var skyline: Node2D = BgPropFactory.make_skyline(Vector2(x_start, y_base + h), x_end - x_start, Color(color.r * 0.8, color.g * 0.8, color.b * 0.8, 1.0), rng)
	layer.add_child(skyline)

	# 2. Colossal Stone Monolith Pillars spanning full height
	var x: float = x_start + rng.randf_range(40.0, 100.0)
	while x < x_end:
		var pillar: Node2D = BgPropFactory.make_pillar(Vector2(x, y_base), h + 100.0, color, rng)
		layer.add_child(pillar)
		x += rng.randf_range(160.0, 260.0)

	# 3. Massive Industrial Cranes
	var crane_x: float = x_start + rng.randf_range(120.0, 240.0)
	while crane_x < x_end - 100.0:
		var crane_y: float = y_base + rng.randf_range(60.0, h * 0.5)
		var crane: Node2D = BgPropFactory.make_crane(Vector2(crane_x, crane_y), color, rng)
		layer.add_child(crane)
		crane_x += rng.randf_range(320.0, 480.0)


static func _build_mid_layer(layer: Node2D, x_start: float, x_end: float, y_base: float, h: float, color: Color, rng: RandomNumberGenerator) -> void:
	var x: float = x_start + rng.randf_range(20.0, 60.0)
	while x < x_end:
		var y: float = y_base + rng.randf_range(40.0, h - 140.0)
		var prop_type: int = rng.randi_range(0, 3)

		match prop_type:
			0, 1:
				# Shoji Screen Lattice Partitions
				var shoji_sz := Vector2(rng.randf_range(90.0, 140.0), rng.randf_range(120.0, 180.0))
				var shoji: Node2D = BgPropFactory.make_shoji_screen(Vector2(x, y), shoji_sz, color, rng)
				layer.add_child(shoji)
			2:
				# Industrial Catwalks / Gantries
				var gantry: Node2D = BgPropFactory.make_gantry(Vector2(x, y), rng.randf_range(140.0, 240.0), color, rng)
				layer.add_child(gantry)
			_:
				# Spinning Wall Fans & Machinery
				var fan: Node2D = BgPropFactory.make_spinning_fan(Vector2(x, y), rng.randf_range(20.0, 30.0), color, rng)
				layer.add_child(fan)

		x += rng.randf_range(110.0, 180.0)


static func _build_near_layer(layer: Node2D, x_start: float, x_end: float, y_base: float, h: float, color: Color, rng: RandomNumberGenerator) -> void:
	var x: float = x_start + rng.randf_range(30.0, 80.0)
	while x < x_end:
		var y: float = y_base + rng.randf_range(50.0, h - 100.0)
		var prop_type: int = rng.randi_range(0, 3)

		match prop_type:
			0:
				# Pipe Runs
				var pipe: Node2D = BgPropFactory.make_pipe_run(Vector2(x, y), rng.randf_range(100.0, 220.0), color, rng)
				layer.add_child(pipe)
			1:
				# Swaying Hanging Cables
				var p2 := Vector2(x, y) + Vector2(rng.randf_range(90.0, 180.0), rng.randf_range(-15.0, 25.0))
				var cable: Node2D = BgPropFactory.make_hanging_cable(Vector2(x, y), p2, color, rng)
				layer.add_child(cable)
			2:
				# Steam Vents
				var steam: Node2D = BgPropFactory.make_steam_pipe(Vector2(x, y), color, rng)
				layer.add_child(steam)
			_:
				# Machine Blocks
				var mach: Node2D = BgPropFactory.make_machine_block(Vector2(x, y), Vector2(rng.randf_range(50.0, 90.0), rng.randf_range(40.0, 70.0)), color, rng)
				layer.add_child(mach)

		x += rng.randf_range(90.0, 160.0)
