class_name EdgeLineFactory
extends RefCounted

static var _flat_reveal_shader: Shader = preload("res://shaders/flat_reveal.gdshader")
static var _edge_line_shader: Shader = preload("res://shaders/edge_line.gdshader")
static var _white_tex: ImageTexture = null

static func _get_white_tex() -> ImageTexture:
	if _white_tex != null:
		return _white_tex
	var img: Image = Image.create(2, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_white_tex = ImageTexture.create_from_image(img)
	return _white_tex

static func make_edge(a: Vector2, b: Vector2, is_top: bool, rng: RandomNumberGenerator) -> Node2D:
	var root: Node2D = Node2D.new()
	root.name = "Edge"

	var total_len: float = a.distance_to(b)
	if total_len < 1.0:
		return root

	var dir: Vector2 = (b - a).normalized()
	var perp: Vector2 = Vector2(-dir.y, dir.x)
	var step_len: float = 6.0
	var n_steps: int = maxi(int(total_len / step_len), 1)

	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 0.08

	var points: PackedVector2Array = PackedVector2Array()
	points.append(a)

	for i in range(1, n_steps):
		var p_base: Vector2 = a + dir * (float(i) * step_len)
		var noise_val: float = noise.get_noise_1d(float(i) * step_len) * 1.6
		var rand_val: float = rng.randf_range(-0.6, 0.6)
		var jitter: float = noise_val + rand_val

		# Occasional notch (every ~20-60 px)
		if rng.randf() < 0.12:
			jitter += rng.randf_range(0.8, 1.8)

		points.append(p_base + perp * jitter)

	points.append(b)

	# 1. Main solid Line2D
	var main_line: Line2D = Line2D.new()
	main_line.name = "MainLine"
	main_line.points = points
	main_line.width = 2.5 if is_top else 1.5
	main_line.default_color = Color.WHITE
	main_line.light_mask = 1
	main_line.joint_mode = Line2D.LINE_JOINT_ROUND
	main_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	main_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	main_line.antialiased = false

	var mat_main: ShaderMaterial = ShaderMaterial.new()
	mat_main.shader = _flat_reveal_shader
	main_line.material = mat_main
	root.add_child(main_line)

	# 2. Glow Line2D (width x3, edge_line shader)
	var glow_line: Line2D = Line2D.new()
	glow_line.name = "GlowLine"
	glow_line.points = points
	glow_line.width = (2.5 if is_top else 1.5) * 3.0
	glow_line.default_color = Color.WHITE
	glow_line.light_mask = 1
	glow_line.texture_mode = Line2D.LINE_TEXTURE_TILE
	glow_line.texture = _get_white_tex()

	var mat_glow: ShaderMaterial = ShaderMaterial.new()
	mat_glow.shader = _edge_line_shader
	mat_glow.set_shader_parameter(&"tint", Color(1.0, 1.0, 1.0, 0.25))
	glow_line.material = mat_glow
	root.add_child(glow_line)

	# 3. Specks and grass tufts on top edges
	if is_top:
		var d_cur: float = rng.randf_range(6.0, 18.0)
		while d_cur < total_len - 4.0:
			if rng.randf() < 0.40:
				var pt: Vector2 = a + dir * d_cur
				if rng.randf() < 0.5:
					# Grass tuft: 2-3 Line2D strokes, 2-5 px tall, +/-25 deg
					var tuft: Node2D = Node2D.new()
					tuft.position = pt
					tuft.light_mask = 1
					var strokes: int = rng.randi_range(2, 3)
					for s in range(strokes):
						var stroke: Line2D = Line2D.new()
						stroke.light_mask = 1
						stroke.width = 1.0
						stroke.default_color = Color.WHITE
						var h: float = rng.randf_range(2.0, 5.0)
						var ang: float = rng.randf_range(-0.436, 0.436)
						var end_pt: Vector2 = Vector2(sin(ang) * h, -cos(ang) * h)
						stroke.points = PackedVector2Array([Vector2.ZERO, end_pt])
						var sm: ShaderMaterial = ShaderMaterial.new()
						sm.shader = _flat_reveal_shader
						stroke.material = sm
						tuft.add_child(stroke)
					root.add_child(tuft)
				else:
					# Debris dot: 2x2 polygon
					var dot: Polygon2D = Polygon2D.new()
					dot.position = pt
					dot.light_mask = 1
					var dot_color: Color = Color.WHITE if rng.randf() < 0.5 else Color(0.7, 0.7, 0.7, 1.0)
					dot.color = dot_color
					dot.polygon = PackedVector2Array([Vector2(-1, -2), Vector2(1, -2), Vector2(1, 0), Vector2(-1, 0)])
					var sm_dot: ShaderMaterial = ShaderMaterial.new()
					sm_dot.shader = _flat_reveal_shader
					dot.material = sm_dot
					root.add_child(dot)
			d_cur += rng.randf_range(6.0, 18.0)

	return root
