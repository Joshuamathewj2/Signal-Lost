class_name LevelBuilder
extends RefCounted

static var _flat_reveal_shader: Shader = preload("res://shaders/flat_reveal.gdshader")

static func build(data: LevelData, root: Node2D) -> Dictionary:
	var solids_body: StaticBody2D = StaticBody2D.new()
	solids_body.name = "Solids"
	solids_body.collision_layer = 0
	solids_body.collision_mask = 0
	solids_body.set_collision_layer_value(1, true)
	root.add_child(solids_body)

	var one_ways_body: StaticBody2D = StaticBody2D.new()
	one_ways_body.name = "OneWays"
	one_ways_body.collision_layer = 0
	one_ways_body.collision_mask = 0
	one_ways_body.set_collision_layer_value(2, true)
	root.add_child(one_ways_body)

	# 1. Build solid rectangles
	var solid_rects: Array[Rect2i] = SolidMerger.merge(data.grid, "#")
	for rect in solid_rects:
		var px_pos: Vector2 = Vector2(rect.position.x * 32, rect.position.y * 32)
		var px_sz: Vector2 = Vector2(rect.size.x * 32, rect.size.y * 32)
		var center: Vector2 = px_pos + px_sz * 0.5

		# Collision shape
		var col: CollisionShape2D = CollisionShape2D.new()
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = px_sz
		col.shape = shape
		col.position = center
		solids_body.add_child(col)

		# Polygon2D (illuminated when in light, pitch black in shadow/unlit)
		var poly: Polygon2D = Polygon2D.new()
		poly.light_mask = 1
		poly.color = Color.WHITE
		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = _flat_reveal_shader
		mat.set_shader_parameter(&"tint", Color(0.12, 0.14, 0.18, 1.0))
		poly.material = mat
		poly.polygon = PackedVector2Array([
			px_pos,
			px_pos + Vector2(px_sz.x, 0),
			px_pos + px_sz,
			px_pos + Vector2(0, px_sz.y)
		])
		solids_body.add_child(poly)

		# Occluder
		var occ: LightOccluder2D = LightOccluder2D.new()
		occ.occluder_light_mask = 1
		var occ_poly: OccluderPolygon2D = OccluderPolygon2D.new()
		occ_poly.cull_mode = OccluderPolygon2D.CULL_DISABLED
		occ_poly.polygon = poly.polygon
		occ.occluder = occ_poly
		solids_body.add_child(occ)

	# 2. Build one-way platforms
	var ow_rects: Array[Rect2i] = SolidMerger.merge(data.grid, "=")
	for rect in ow_rects:
		var px_pos: Vector2 = Vector2(rect.position.x * 32, rect.position.y * 32)
		var px_w: float = rect.size.x * 32.0

		var col: CollisionShape2D = CollisionShape2D.new()
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = Vector2(px_w, 8.0)
		col.shape = shape
		col.one_way_collision = true
		col.one_way_collision_margin = 4.0
		col.position = px_pos + Vector2(px_w * 0.5, 4.0)
		one_ways_body.add_child(col)

	# 3. Build edge lines
	var edge_lines: Node2D = EdgeBuilder.build(data, root)

	return {
		"solids": solids_body,
		"one_ways": one_ways_body,
		"edge_lines": edge_lines,
		"solid_rects": solid_rects,
		"ow_rects": ow_rects
	}
