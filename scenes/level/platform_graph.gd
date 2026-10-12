class_name PlatformGraph
extends RefCounted

enum EdgeType {
	WALK = 0,
	JUMP = 1,
	DROP = 2
}

var astar_all: AStar2D = AStar2D.new()
var astar_no_jump: AStar2D = AStar2D.new()
var width: int = 0
var height: int = 0
var standable_cells: Dictionary = {} # Vector2i -> int (id)
var edge_types: Dictionary = {} # Vector2i(from_id, to_id) -> int (EdgeType)
var node_positions: Dictionary = {} # int (id) -> Vector2

func build(data: LevelData, custom_solid_fn: Callable = Callable()) -> void:
	astar_all.clear()
	astar_no_jump.clear()
	standable_cells.clear()
	edge_types.clear()
	node_positions.clear()

	width = data.width
	height = data.height

	if data.grid.is_empty():
		return

	var is_solid_fn: Callable = custom_solid_fn
	if not is_solid_fn.is_valid():
		is_solid_fn = func(c: int, r: int) -> bool:
			if c < 0 or c >= width or r < 0 or r >= height:
				return true
			var ch: String = data.grid[r][c]
			return ch == "#" or ch == "D" or ch == "R"

	var is_ground_fn := func(c: int, r: int) -> bool:
		if c < 0 or c >= width or r < 0 or r >= height:
			return false
		var ch: String = data.grid[r][c]
		return ch == "#" or ch == "=" or ch == "G" or ch == "D" or ch == "R"

	# 1. Register standable cells (empty or door cell with ground below)
	for r in range(height - 1):
		for c in range(width):
			var ch: String = data.grid[r][c]
			var is_door: bool = (ch == "D" or ch == "R")
			if (not is_solid_fn.call(c, r) or is_door) and is_ground_fn.call(c, r + 1):
				var cell := Vector2i(c, r)
				var id: int = r * width + c
				var pos := Vector2((float(c) + 0.5) * 32.0, (float(r) + 1.0) * 32.0)
				standable_cells[cell] = id
				node_positions[id] = pos
				astar_all.add_point(id, pos)
				astar_no_jump.add_point(id, pos)
				if is_door:
					astar_all.set_point_disabled(id, true)
					astar_no_jump.set_point_disabled(id, true)

	# 2. Add edges
	for cell in standable_cells.keys():
		var id: int = standable_cells[cell]
		var c: int = cell.x
		var r: int = cell.y

		# 2.1 WALK: horizontal neighbours (c ± 1, r)
		for dc in [-1, 1]:
			var nc: int = c + dc
			var n_cell := Vector2i(nc, r)
			var n_is_door: bool = false
			if nc >= 0 and nc < width:
				var nch: String = data.grid[r][nc]
				n_is_door = (nch == "D" or nch == "R")
			if standable_cells.has(n_cell) and (not is_solid_fn.call(nc, r) or n_is_door):
				var ch_cur: String = data.grid[r][c]
				var ch_nxt: String = data.grid[r][nc]
				var blocked: bool = false
				if (ch_cur == ">" or ch_nxt == ">") and dc < 0:
					blocked = true
				elif (ch_cur == "<" or ch_nxt == "<") and dc > 0:
					blocked = true
				if not blocked and r > 0:
					var ch_cur_above: String = data.grid[r - 1][c]
					var ch_nxt_above: String = data.grid[r - 1][nc]
					if (ch_cur_above == ">" or ch_nxt_above == ">") and dc < 0:
						blocked = true
					elif (ch_cur_above == "<" or ch_nxt_above == "<") and dc > 0:
						blocked = true
				if not blocked:
					var nid: int = standable_cells[n_cell]
					_add_edge(id, nid, EdgeType.WALK, 1.0, false)

		# 2.2 DROP: walk off edge left/right and fall down 1..8 tiles
		for dc in [-1, 1]:
			var nc: int = c + dc
			if not is_solid_fn.call(nc, r):
				# Probe down
				for dy in range(1, 9):
					var nr: int = r + dy
					if nr >= height or is_solid_fn.call(nc, nr):
						break
					var drop_cell := Vector2i(nc, nr)
					if standable_cells.has(drop_cell):
						var nid: int = standable_cells[drop_cell]
						_add_edge(id, nid, EdgeType.DROP, float(dy) * 1.1, false)
						break

		# 2.3 One-way drop-through straight down if standing on '='
		if r + 1 < height and data.grid[r + 1][c] == "=":
			for dy in range(2, 9):
				var nr: int = r + dy
				if nr >= height or is_solid_fn.call(c, nr):
					break
				var drop_cell := Vector2i(c, nr)
				if standable_cells.has(drop_cell):
					var nid: int = standable_cells[drop_cell]
					_add_edge(id, nid, EdgeType.DROP, float(dy) * 1.0, false)
					break

		# 2.4 JUMP: rise 0..2, |dx| 1..3
		for rise in range(0, 3):
			var tr: int = r - rise
			if tr < 0:
				continue
			# Check overhead clearance at jump start
			var clear_start: bool = true
			for cy in range(1, rise + 2):
				if is_solid_fn.call(c, r - cy):
					clear_start = false
					break
			if not clear_start:
				continue

			for dx in [-3, -2, -1, 1, 2, 3]:
				var tc: int = c + dx
				if tc < 0 or tc >= width:
					continue
				var target_cell := Vector2i(tc, tr)
				if not standable_cells.has(target_cell):
					continue
				# Check overhead clearance at jump target
				if is_solid_fn.call(tc, tr - 1):
					continue
				# Check mid-air clearance at apex
				var apex_y: int = tr - 1
				var mid_c: int = c + int(round(float(dx) * 0.5))
				if is_solid_fn.call(mid_c, apex_y):
					continue

				var nid: int = standable_cells[target_cell]
				var dist_cost: float = Vector2(float(dx), float(rise)).length() * 1.3
				_add_edge(id, nid, EdgeType.JUMP, dist_cost, false)

	# 2.5 LADDERS (H): Connect bottom standable node to top standable node
	if data.cells.has("H"):
		for cell in data.cells["H"]:
			var c: int = cell.x
			for stand_c in standable_cells.keys():
				if abs(stand_c.x - c) <= 1:
					var id1: int = standable_cells[stand_c]
					for stand_c2 in standable_cells.keys():
						if abs(stand_c2.x - c) <= 1 and stand_c2.y < stand_c.y and (stand_c.y - stand_c2.y) <= 10:
							var id2: int = standable_cells[stand_c2]
							_add_edge(id1, id2, EdgeType.WALK, float(stand_c.y - stand_c2.y) * 1.0, true)

func _add_edge(from_id: int, to_id: int, type: EdgeType, weight: float, both_ways: bool) -> void:
	edge_types[Vector2i(from_id, to_id)] = int(type)
	if not astar_all.has_point(from_id) or not astar_all.has_point(to_id):
		return

	var conns: PackedInt64Array = astar_all.get_point_connections(from_id)
	if not conns.has(to_id):
		astar_all.connect_points(from_id, to_id, both_ways)
		astar_all.set_point_weight_scale(to_id, weight)

	if type != EdgeType.JUMP:
		if astar_no_jump.has_point(from_id) and astar_no_jump.has_point(to_id):
			var no_conns: PackedInt64Array = astar_no_jump.get_point_connections(from_id)
			if not no_conns.has(to_id):
				astar_no_jump.connect_points(from_id, to_id, both_ways)
				astar_no_jump.set_point_weight_scale(to_id, weight)

	if both_ways:
		edge_types[Vector2i(to_id, from_id)] = int(type)

func nearest_node(px: Vector2) -> int:
	return astar_all.get_closest_point(px)

func find_path(from_px: Vector2, to_px: Vector2, can_jump: bool = true) -> Dictionary:
	var astar: AStar2D = astar_all if can_jump else astar_no_jump
	var id_from: int = astar.get_closest_point(from_px)
	var id_to: int = astar.get_closest_point(to_px)

	if id_from == -1 or id_to == -1:
		return { "points": PackedVector2Array(), "types": [], "ids": [] }

	var id_path: PackedInt64Array = astar.get_id_path(id_from, id_to)
	if id_path.is_empty():
		return { "points": PackedVector2Array(), "types": [], "ids": [] }

	var pts: PackedVector2Array = PackedVector2Array()
	var types: Array[int] = []
	var ids: Array[int] = []

	for i in range(id_path.size()):
		var cur_id: int = int(id_path[i])
		ids.append(cur_id)
		pts.append(node_positions.get(cur_id, from_px))
		if i == 0:
			types.append(int(EdgeType.WALK))
		else:
			var prev_id: int = int(id_path[i - 1])
			var t: int = edge_types.get(Vector2i(prev_id, cur_id), int(EdgeType.WALK))
			types.append(t)

	return { "points": pts, "types": types, "ids": ids }

func path_length(a_px: Vector2, b_px: Vector2) -> float:
	var res: Dictionary = find_path(a_px, b_px, true)
	var pts: PackedVector2Array = res.get("points", PackedVector2Array())
	if pts.size() < 2:
		return 0.0
	var total: float = 0.0
	for i in range(pts.size() - 1):
		total += pts[i].distance_to(pts[i + 1])
	return total

func set_door_open(cell: Vector2i, open: bool) -> void:
	for dy in [0, 1, -1]:
		var id: int = (cell.y + dy) * width + cell.x
		if astar_all.has_point(id):
			astar_all.set_point_disabled(id, not open)
		if astar_no_jump.has_point(id):
			astar_no_jump.set_point_disabled(id, not open)

func set_standable(cell: Vector2i, standable: bool) -> void:
	var id: int = cell.y * width + cell.x
	if astar_all.has_point(id):
		astar_all.set_point_disabled(id, not standable)
	if astar_no_jump.has_point(id):
		astar_no_jump.set_point_disabled(id, not standable)
