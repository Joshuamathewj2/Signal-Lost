class_name BgPropFactory
extends RefCounted

## BgPropFactory
## Procedural generator for atmospheric feudal-cyberpunk background silhouettes:
## Shoji screen lattices, industrial cranes, massive stone pillars, steel gantries,
## spinning ventilation fans, steam vents, and swaying catenary cables.

const FAN_SCENE: PackedScene = preload("res://scenes/props/fan_prop.tscn")
const STEAM_VENT_SCENE: PackedScene = preload("res://scenes/props/steam_vent.tscn")
const CABLE_SCENE: PackedScene = preload("res://scenes/props/cable_prop.tscn")

static func _make_mat() -> CanvasItemMaterial:
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return mat

# 1. Shoji Screen Frames (feudal lattice partitions)
static func make_shoji_screen(pos: Vector2, size: Vector2, color: Color, _rng: RandomNumberGenerator) -> Node2D:
	var root: Node2D = Node2D.new()
	root.position = pos
	var mat := _make_mat()

	# Translucent backing paper
	var backing := Polygon2D.new()
	backing.polygon = PackedVector2Array([
		Vector2.ZERO, Vector2(size.x, 0),
		Vector2(size.x, size.y), Vector2(0, size.y)
	])
	backing.color = Color(color.r * 0.7, color.g * 0.7, color.b * 0.7, 0.45)
	backing.material = mat
	root.add_child(backing)

	# Outer Wooden/Steel Border Frame
	var border := Line2D.new()
	border.points = PackedVector2Array([
		Vector2.ZERO, Vector2(size.x, 0),
		Vector2(size.x, size.y), Vector2(0, size.y),
		Vector2.ZERO
	])
	border.width = 2.5
	border.default_color = color
	border.material = mat
	root.add_child(border)

	# Vertical Lattice Muntins
	var col_w: float = 24.0
	var cx: float = col_w
	while cx < size.x - 4.0:
		var v_line := Line2D.new()
		v_line.points = PackedVector2Array([Vector2(cx, 0), Vector2(cx, size.y)])
		v_line.width = 1.0
		v_line.default_color = Color(color.r * 0.9, color.g * 0.9, color.b * 0.9, 0.85)
		v_line.material = mat
		root.add_child(v_line)
		cx += col_w

	# Horizontal Lattice Muntins
	var row_h: float = 20.0
	var ry: float = row_h
	while ry < size.y - 4.0:
		var h_line := Line2D.new()
		h_line.points = PackedVector2Array([Vector2(0, ry), Vector2(size.x, ry)])
		h_line.width = 1.0
		h_line.default_color = Color(color.r * 0.9, color.g * 0.9, color.b * 0.9, 0.85)
		h_line.material = mat
		root.add_child(h_line)
		ry += row_h

	return root

# 2. Massive Stone Monolith Pillars
static func make_pillar(pos: Vector2, height: float, color: Color, rng: RandomNumberGenerator) -> Node2D:
	var root: Node2D = Node2D.new()
	root.position = pos
	var mat := _make_mat()

	var w: float = rng.randf_range(48.0, 80.0)

	# Main Pillar Body
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-w * 0.5, 0), Vector2(w * 0.5, 0),
		Vector2(w * 0.5, height), Vector2(-w * 0.5, height)
	])
	poly.color = color
	poly.material = mat
	root.add_child(poly)

	# Capital Bevel at top
	var cap := Polygon2D.new()
	cap.polygon = PackedVector2Array([
		Vector2(-w * 0.5 - 6.0, 0), Vector2(w * 0.5 + 6.0, 0),
		Vector2(w * 0.5 + 2.0, 10.0), Vector2(-w * 0.5 - 2.0, 10.0)
	])
	cap.color = Color(color.r * 1.25, color.g * 1.25, color.b * 1.25, 1.0)
	cap.material = mat
	root.add_child(cap)

	# Base Bevel at bottom
	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([
		Vector2(-w * 0.5 - 2.0, height - 10.0), Vector2(w * 0.5 + 2.0, height - 10.0),
		Vector2(w * 0.5 + 8.0, height), Vector2(-w * 0.5 - 8.0, height)
	])
	base.color = Color(color.r * 1.2, color.g * 1.2, color.b * 1.2, 1.0)
	base.material = mat
	root.add_child(base)

	# Central Accent Groove
	var groove := Line2D.new()
	groove.points = PackedVector2Array([Vector2(0, 14.0), Vector2(0, height - 14.0)])
	groove.width = 2.0
	groove.default_color = Color(color.r * 0.6, color.g * 0.6, color.b * 0.6, 1.0)
	groove.material = mat
	root.add_child(groove)

	return root

# 3. Industrial Cranes (construction boom cranes)
static func make_crane(pos: Vector2, color: Color, rng: RandomNumberGenerator) -> Node2D:
	var root: Node2D = Node2D.new()
	root.position = pos
	var mat := _make_mat()

	var mast_h: float = rng.randf_range(160.0, 260.0)
	var jib_len: float = rng.randf_range(140.0, 240.0)
	var rear_len: float = jib_len * 0.35

	# Vertical Truss Mast
	var mast_w: float = 14.0
	var mast_l := Line2D.new()
	mast_l.points = PackedVector2Array([Vector2(-mast_w * 0.5, 0), Vector2(-mast_w * 0.5, mast_h)])
	mast_l.width = 2.0
	mast_l.default_color = color
	mast_l.material = mat
	root.add_child(mast_l)

	var mast_r := Line2D.new()
	mast_r.points = PackedVector2Array([Vector2(mast_w * 0.5, 0), Vector2(mast_w * 0.5, mast_h)])
	mast_r.width = 2.0
	mast_r.default_color = color
	mast_r.material = mat
	root.add_child(mast_r)

	# Mast Cross-Bracing
	var step_y: float = 18.0
	var cy: float = 0.0
	while cy < mast_h:
		var brace := Line2D.new()
		brace.points = PackedVector2Array([Vector2(-mast_w * 0.5, cy), Vector2(mast_w * 0.5, cy + step_y)])
		brace.width = 1.0
		brace.default_color = Color(color.r * 0.8, color.g * 0.8, color.b * 0.8, 1.0)
		brace.material = mat
		root.add_child(brace)
		cy += step_y

	# Crane Jib (horizontal boom)
	var jib := Line2D.new()
	jib.points = PackedVector2Array([Vector2(-rear_len, 0), Vector2(jib_len, 0)])
	jib.width = 2.5
	jib.default_color = color
	jib.material = mat
	root.add_child(jib)

	# Crane Apex Tower & Stay Cables
	var apex_h: float = -28.0
	var cable_stay := Line2D.new()
	cable_stay.points = PackedVector2Array([
		Vector2(-rear_len, 0), Vector2(0, apex_h),
		Vector2(jib_len * 0.5, 0), Vector2(0, apex_h),
		Vector2(jib_len * 0.85, 0)
	])
	cable_stay.width = 1.0
	cable_stay.default_color = Color(color.r * 0.85, color.g * 0.85, color.b * 0.85, 1.0)
	cable_stay.material = mat
	root.add_child(cable_stay)

	# Counterweight Block
	var cw := Polygon2D.new()
	cw.polygon = PackedVector2Array([
		Vector2(-rear_len, 0), Vector2(-rear_len + 22.0, 0),
		Vector2(-rear_len + 22.0, 16.0), Vector2(-rear_len, 16.0)
	])
	cw.color = Color(color.r * 1.2, color.g * 1.2, color.b * 1.2, 1.0)
	cw.material = mat
	root.add_child(cw)

	return root

# 4. Feudal-Industrial Megastructure Skyline
static func make_skyline(pos: Vector2, width: float, color: Color, rng: RandomNumberGenerator) -> Node2D:
	var root: Node2D = Node2D.new()
	root.position = pos
	var mat := _make_mat()

	var cx: float = 0.0
	while cx < width:
		var b_w: float = rng.randf_range(36.0, 72.0)
		var b_h: float = rng.randf_range(80.0, 200.0)

		# Stepped Cyber-Tower
		var tower := Polygon2D.new()
		tower.polygon = PackedVector2Array([
			Vector2(cx, 0), Vector2(cx + b_w, 0),
			Vector2(cx + b_w, -b_h), Vector2(cx, -b_h)
		])
		tower.color = color
		tower.material = mat
		root.add_child(tower)

		# Pagoda-style eaves on every 3rd tower
		if rng.randf() < 0.45:
			var eave := Polygon2D.new()
			eave.polygon = PackedVector2Array([
				Vector2(cx - 8.0, -b_h), Vector2(cx + b_w + 8.0, -b_h),
				Vector2(cx + b_w + 4.0, -b_h - 6.0), Vector2(cx - 4.0, -b_h - 6.0)
			])
			eave.color = Color(color.r * 1.3, color.g * 1.3, color.b * 1.3, 1.0)
			eave.material = mat
			root.add_child(eave)

		# Antenna mast
		if rng.randf() < 0.5:
			var ant := Line2D.new()
			ant.points = PackedVector2Array([Vector2(cx + b_w * 0.5, -b_h), Vector2(cx + b_w * 0.5, -b_h - rng.randf_range(16.0, 36.0))])
			ant.width = 1.0
			ant.default_color = Color(color.r * 1.2, color.g * 1.2, color.b * 1.2, 1.0)
			ant.material = mat
			root.add_child(ant)

		cx += b_w + rng.randf_range(8.0, 24.0)

	return root

# 5. Open-Truss Steel Gantries
static func make_gantry(pos: Vector2, length: float, color: Color, _rng: RandomNumberGenerator) -> Node2D:
	var root: Node2D = Node2D.new()
	root.position = pos
	var mat := _make_mat()

	var h: float = 20.0
	var top_line := Line2D.new()
	top_line.points = PackedVector2Array([Vector2.ZERO, Vector2(length, 0)])
	top_line.width = 2.0
	top_line.default_color = color
	top_line.material = mat
	root.add_child(top_line)

	var bot_line := Line2D.new()
	bot_line.points = PackedVector2Array([Vector2(0, h), Vector2(length, h)])
	bot_line.width = 2.0
	bot_line.default_color = color
	bot_line.material = mat
	root.add_child(bot_line)

	# Diagonal Cross-Truss
	var truss := Line2D.new()
	var truss_pts := PackedVector2Array()
	var step: float = 18.0
	var x: float = 0.0
	var is_top: bool = true
	while x <= length:
		truss_pts.append(Vector2(x, 0.0 if is_top else h))
		is_top = not is_top
		x += step
	truss.points = truss_pts
	truss.width = 1.0
	truss.default_color = Color(color.r * 0.85, color.g * 0.85, color.b * 0.85, 1.0)
	truss.material = mat
	root.add_child(truss)

	# Handrail
	var rail := Line2D.new()
	rail.points = PackedVector2Array([Vector2(0, -8.0), Vector2(length, -8.0)])
	rail.width = 1.0
	rail.default_color = Color(color.r * 0.8, color.g * 0.8, color.b * 0.8, 1.0)
	rail.material = mat
	root.add_child(rail)

	return root

# 6. Pipe Runs with Flanges & Drops
static func make_pipe_run(pos: Vector2, length: float, color: Color, rng: RandomNumberGenerator) -> Node2D:
	var root: Node2D = Node2D.new()
	root.position = pos
	var mat := _make_mat()

	var pipe_w: float = rng.randf_range(8.0, 14.0)
	var pipe := Line2D.new()
	pipe.points = PackedVector2Array([Vector2.ZERO, Vector2(length, 0)])
	pipe.width = pipe_w
	pipe.default_color = color
	pipe.material = mat
	root.add_child(pipe)

	# Flanges along pipe
	var x: float = rng.randf_range(30.0, 60.0)
	while x < length - 20.0:
		var flange := Polygon2D.new()
		flange.polygon = PackedVector2Array([
			Vector2(x - 3, -pipe_w * 0.75), Vector2(x + 3, -pipe_w * 0.75),
			Vector2(x + 3, pipe_w * 0.75), Vector2(x - 3, pipe_w * 0.75)
		])
		flange.color = Color(color.r * 1.3, color.g * 1.3, color.b * 1.3, 1.0)
		flange.material = mat
		root.add_child(flange)
		x += rng.randf_range(60.0, 100.0)

	return root

# 7. Animated Wall Ventilation Fan
static func make_spinning_fan(pos: Vector2, size_r: float, color: Color, rng: RandomNumberGenerator) -> Node2D:
	var fan_inst: Node2D = FAN_SCENE.instantiate() as Node2D
	fan_inst.position = pos
	if "radius" in fan_inst:
		fan_inst.set("radius", size_r)
	if "prop_color" in fan_inst:
		fan_inst.set("prop_color", color)
	if "rotation_speed" in fan_inst:
		fan_inst.set("rotation_speed", rng.randf_range(160.0, 320.0))
	return fan_inst

# 8. Animated Steam Vent
static func make_steam_pipe(pos: Vector2, color: Color, rng: RandomNumberGenerator) -> Node2D:
	var root: Node2D = Node2D.new()
	root.position = pos
	var mat := _make_mat()

	var pipe_h: float = rng.randf_range(24.0, 48.0)
	var pipe := Line2D.new()
	pipe.points = PackedVector2Array([Vector2(0, pipe_h), Vector2(0, 0)])
	pipe.width = 10.0
	pipe.default_color = color
	pipe.material = mat
	root.add_child(pipe)

	var vent_inst: Node2D = STEAM_VENT_SCENE.instantiate() as Node2D
	vent_inst.position = Vector2.ZERO
	root.add_child(vent_inst)
	return root

# 9. Swaying Hanging Cables
static func make_hanging_cable(p1: Vector2, p2: Vector2, color: Color, rng: RandomNumberGenerator) -> Node2D:
	var cable_inst: Node2D = CABLE_SCENE.instantiate() as Node2D
	cable_inst.position = p1
	if "p1" in cable_inst:
		cable_inst.set("p1", Vector2.ZERO)
	if "p2" in cable_inst:
		cable_inst.set("p2", p2 - p1)
	if "base_sag" in cable_inst:
		cable_inst.set("base_sag", rng.randf_range(20.0, 50.0))
	if "cable_color" in cable_inst:
		cable_inst.set("cable_color", color)
	return cable_inst

# 10. Machine Blocks
static func make_machine_block(pos: Vector2, size: Vector2, color: Color, rng: RandomNumberGenerator) -> Node2D:
	var root: Node2D = Node2D.new()
	root.position = pos
	var mat := _make_mat()

	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2.ZERO, Vector2(size.x, 0),
		Vector2(size.x, size.y), Vector2(0, size.y)
	])
	poly.color = color
	poly.material = mat
	root.add_child(poly)

	# Seam Line
	var seam := Line2D.new()
	seam.points = PackedVector2Array([Vector2(size.x * 0.5, 4), Vector2(size.x * 0.5, size.y - 4)])
	seam.width = 1.0
	seam.default_color = Color(color.r * 0.7, color.g * 0.7, color.b * 0.7, 1.0)
	seam.material = mat
	root.add_child(seam)

	return root

static func make_random_prop(pos: Vector2, color: Color, rng: RandomNumberGenerator, max_height: float = 720.0) -> Node2D:
	var choice: int = rng.randi_range(0, 7)
	match choice:
		0:
			return make_shoji_screen(pos, Vector2(rng.randf_range(80.0, 140.0), rng.randf_range(120.0, 200.0)), color, rng)
		1:
			return make_pillar(pos, minf(rng.randf_range(160.0, 360.0), max_height), color, rng)
		2:
			return make_gantry(pos, rng.randf_range(120.0, 260.0), color, rng)
		3:
			var p2 := pos + Vector2(rng.randf_range(80.0, 180.0), rng.randf_range(-10.0, 20.0))
			return make_hanging_cable(pos, p2, color, rng)
		4:
			return make_spinning_fan(pos, rng.randf_range(18.0, 28.0), color, rng)
		5:
			return make_pipe_run(pos, rng.randf_range(90.0, 220.0), color, rng)
		6:
			return make_steam_pipe(pos, color, rng)
		_:
			return make_machine_block(pos, Vector2(rng.randf_range(50.0, 90.0), rng.randf_range(40.0, 80.0)), color, rng)
