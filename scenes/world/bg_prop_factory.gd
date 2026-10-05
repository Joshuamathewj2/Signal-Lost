class_name BgPropFactory
extends RefCounted

static var _flat_reveal_shader: Shader = preload("res://shaders/flat_reveal.gdshader")

static func _make_mat(color: Color) -> ShaderMaterial:
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = _flat_reveal_shader
	mat.set_shader_parameter(&"tint", color)
	return mat

static func make_pipe_run(pos: Vector2, length: float, color: Color, rng: RandomNumberGenerator) -> Node2D:
	var root: Node2D = Node2D.new()
	root.position = pos
	var mat: ShaderMaterial = _make_mat(color)

	var pipe_w: float = rng.randf_range(6.0, 10.0)
	var pipe: Line2D = Line2D.new()
	pipe.points = PackedVector2Array([Vector2.ZERO, Vector2(length, 0)])
	pipe.width = pipe_w
	pipe.default_color = color
	pipe.light_mask = 2
	pipe.material = mat
	root.add_child(pipe)

	# Flanges every 60-100 px
	var x: float = rng.randf_range(30.0, 60.0)
	while x < length - 20.0:
		var flange: Polygon2D = Polygon2D.new()
		flange.polygon = PackedVector2Array([
			Vector2(x - 2, -pipe_w * 0.75),
			Vector2(x + 2, -pipe_w * 0.75),
			Vector2(x + 2, pipe_w * 0.75),
			Vector2(x - 2, pipe_w * 0.75)
		])
		flange.color = color
		flange.light_mask = 2
		flange.material = mat
		root.add_child(flange)
		x += rng.randf_range(60.0, 100.0)

	return root

static func make_pillar(pos: Vector2, height: float, color: Color, rng: RandomNumberGenerator) -> Node2D:
	var root: Node2D = Node2D.new()
	root.position = pos
	var mat: ShaderMaterial = _make_mat(color)

	var w: float = rng.randf_range(24.0, 40.0)
	var poly: Polygon2D = Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-w * 0.5, 0),
		Vector2(w * 0.5, 0),
		Vector2(w * 0.5, height),
		Vector2(-w * 0.5, height)
	])
	poly.color = color
	poly.light_mask = 2
	poly.material = mat
	root.add_child(poly)

	# Rivet dots along sides
	var y: float = 16.0
	while y < height - 16.0:
		for sign_x in [-1.0, 1.0]:
			var rivet: Polygon2D = Polygon2D.new()
			var rx: float = sign_x * (w * 0.5 - 4.0)
			rivet.polygon = PackedVector2Array([
				Vector2(rx - 1, y - 1),
				Vector2(rx + 1, y - 1),
				Vector2(rx + 1, y + 1),
				Vector2(rx - 1, y + 1)
			])
			rivet.color = color
			rivet.light_mask = 2
			rivet.material = mat
			root.add_child(rivet)
		y += rng.randf_range(24.0, 40.0)

	return root

static func make_gantry(pos: Vector2, length: float, color: Color, _rng: RandomNumberGenerator) -> Node2D:
	var root: Node2D = Node2D.new()
	root.position = pos
	var mat: ShaderMaterial = _make_mat(color)

	var h: float = 18.0
	var top_line: Line2D = Line2D.new()
	top_line.points = PackedVector2Array([Vector2.ZERO, Vector2(length, 0)])
	top_line.width = 2.0
	top_line.default_color = color
	top_line.light_mask = 2
	top_line.material = mat
	root.add_child(top_line)

	var bot_line: Line2D = Line2D.new()
	bot_line.points = PackedVector2Array([Vector2(0, h), Vector2(length, h)])
	bot_line.width = 2.0
	bot_line.default_color = color
	bot_line.light_mask = 2
	bot_line.material = mat
	root.add_child(bot_line)

	# Zigzag truss
	var truss: Line2D = Line2D.new()
	var truss_pts: PackedVector2Array = PackedVector2Array()
	var step: float = 16.0
	var x: float = 0.0
	var is_top: bool = true
	while x <= length:
		truss_pts.append(Vector2(x, 0.0 if is_top else h))
		is_top = not is_top
		x += step
	truss.points = truss_pts
	truss.width = 1.0
	truss.default_color = color
	truss.light_mask = 2
	truss.material = mat
	root.add_child(truss)

	return root

static func make_hanging_cable(p1: Vector2, p2: Vector2, color: Color, rng: RandomNumberGenerator) -> Node2D:
	var root: Node2D = Node2D.new()
	var mat: ShaderMaterial = _make_mat(color)

	var cable: Line2D = Line2D.new()
	cable.width = 1.5
	cable.default_color = color
	cable.light_mask = 2
	cable.material = mat

	var sag: float = rng.randf_range(20.0, 60.0)
	var pts: PackedVector2Array = PackedVector2Array()
	var num_pts: int = 12
	for i in range(num_pts + 1):
		var t: float = float(i) / float(num_pts)
		var base_pt: Vector2 = p1.lerp(p2, t)
		var catenary_sag: float = 4.0 * sag * t * (1.0 - t)
		pts.append(Vector2(base_pt.x, base_pt.y + catenary_sag))

	cable.points = pts
	root.add_child(cable)
	return root

static func make_hanging_lamp(pos: Vector2, drop: float, color: Color, _rng: RandomNumberGenerator) -> Node2D:
	var root: Node2D = Node2D.new()
	root.position = pos
	var mat: ShaderMaterial = _make_mat(color)

	var cord: Line2D = Line2D.new()
	cord.points = PackedVector2Array([Vector2.ZERO, Vector2(0, drop)])
	cord.width = 1.0
	cord.default_color = color
	cord.light_mask = 2
	cord.material = mat
	root.add_child(cord)

	var shade: Polygon2D = Polygon2D.new()
	shade.polygon = PackedVector2Array([
		Vector2(-8, drop + 6),
		Vector2(8, drop + 6),
		Vector2(4, drop),
		Vector2(-4, drop)
	])
	shade.color = color
	shade.light_mask = 2
	shade.material = mat
	root.add_child(shade)

	return root

static func make_vent_grate(pos: Vector2, color: Color, _rng: RandomNumberGenerator) -> Node2D:
	var root: Node2D = Node2D.new()
	root.position = pos
	var mat: ShaderMaterial = _make_mat(color)

	var frame: Polygon2D = Polygon2D.new()
	frame.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(36, 0), Vector2(36, 28), Vector2(0, 28)
	])
	frame.color = color
	frame.light_mask = 2
	frame.material = mat
	root.add_child(frame)

	for i in range(5):
		var y: float = 4.0 + float(i) * 5.0
		var slat: Line2D = Line2D.new()
		slat.points = PackedVector2Array([Vector2(4, y), Vector2(32, y)])
		slat.width = 2.0
		slat.default_color = Color(color.r * 0.6, color.g * 0.6, color.b * 0.6, 1.0)
		slat.light_mask = 2
		slat.material = mat
		root.add_child(slat)

	return root

static func make_machine_block(pos: Vector2, size: Vector2, color: Color, rng: RandomNumberGenerator) -> Node2D:
	var root: Node2D = Node2D.new()
	root.position = pos
	var mat: ShaderMaterial = _make_mat(color)

	var poly: Polygon2D = Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2.ZERO, Vector2(size.x, 0), Vector2(size.x, size.y), Vector2(0, size.y)
	])
	poly.color = color
	poly.light_mask = 2
	poly.material = mat
	root.add_child(poly)

	# Panel seams
	if size.x > 30 and size.y > 30:
		var seam: Line2D = Line2D.new()
		var seam_x: float = size.x * rng.randf_range(0.35, 0.65)
		seam.points = PackedVector2Array([Vector2(seam_x, 4), Vector2(seam_x, size.y - 4)])
		seam.width = 1.0
		seam.default_color = Color(color.r * 0.7, color.g * 0.7, color.b * 0.7, 1.0)
		seam.light_mask = 2
		seam.material = mat
		root.add_child(seam)

	return root

static func make_random_prop(pos: Vector2, color: Color, rng: RandomNumberGenerator, max_height: float = 720.0) -> Node2D:
	var choice: int = rng.randi_range(0, 6)
	match choice:
		0:
			return make_pipe_run(pos, rng.randf_range(80.0, 200.0), color, rng)
		1:
			return make_pillar(pos, minf(rng.randf_range(120.0, 300.0), max_height), color, rng)
		2:
			return make_gantry(pos, rng.randf_range(100.0, 220.0), color, rng)
		3:
			var p2: Vector2 = pos + Vector2(rng.randf_range(60.0, 160.0), rng.randf_range(-20.0, 20.0))
			return make_hanging_cable(pos, p2, color, rng)
		4:
			return make_hanging_lamp(pos, rng.randf_range(30.0, 80.0), color, rng)
		5:
			return make_vent_grate(pos, color, rng)
		_:
			return make_machine_block(pos, Vector2(rng.randf_range(40.0, 80.0), rng.randf_range(30.0, 70.0)), color, rng)
