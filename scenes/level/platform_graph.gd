class_name PlatformGraph
extends RefCounted

enum EdgeType {
	WALK = 0,
	JUMP = 1,
	DROP = 2
}

## A* with per-edge cost multipliers (jumps cost more than walking the same
## distance, so capable fighters only jump where it actually saves the route).
class EdgeCostAStar extends AStar2D:
	var penalties: Dictionary = {} # Vector2i(from, to) -> multiplier

	func _compute_cost(from_id: int, to_id: int) -> float:
		return get_point_position(from_id).distance_to(get_point_position(to_id)) * float(penalties.get(Vector2i(from_id, to_id), 1.0))

	func _estimate_cost(from_id: int, end_id: int) -> float:
		return get_point_position(from_id).distance_to(get_point_position(end_id))

const JUMP_COST_MULT: float = 1.8

var astar_all: AStar2D = AStar2D.new()
var astar_no_jump: AStar2D = AStar2D.new()
var width: int = 0
var height: int = 0
var standable_cells: Dictionary = {} # Vector2i -> int (id)
var edge_types: Dictionary = {} # Vector2i(from_id, to_id) -> int (EdgeType)
var node_positions: Dictionary = {} # int (id) -> Vector2
var edges: Array[Dictionary] = [] # {from, to, type, weight, both, rise_px, run_px}
var _capable_cache: Dictionary = {} # Vector2i(max_rise_px, max_run_px) -> AStar2D
var _best_types: Dictionary = {} # Vector2i(from, to) -> EdgeType, WALK > DROP > JUMP

func build(data: LevelData, custom_solid_fn: Callable = Callable()) -> void:
	astar_all.clear()
	astar_no_jump.clear()
	standable_cells.clear()
	edge_types.clear()
	node_positions.clear()
	edges.clear()
	_capable_cache.clear()
	_best_types.clear()

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

		# 2.4b EXTENDED JUMP candidates (rise 0..3, |dx| 4..6, plus rise 3 short hops).
		# Never added to the legacy A* graphs; only find_path_capable() uses them
		# when the fighter's JSON jump height / max gap allows it.
		for rise in range(0, 4):
			var tr: int = r - rise
			if tr < 1:
				continue
			var dxs: Array = [-6, -5, -4, 4, 5, 6]
			if rise == 3:
				dxs.append_array([-3, -2, -1, 1, 2, 3])
			for dx in dxs:
				var tc: int = c + dx
				if tc < 0 or tc >= width:
					continue
				var target_cell := Vector2i(tc, tr)
				if not standable_cells.has(target_cell):
					continue
				var clear: bool = true
				var top_r: int = mini(r, tr)
				var step: int = 1 if dx > 0 else -1
				var col: int = c
				while clear:
					for cy in [top_r - 1, top_r - 2]:
						if cy >= 0 and is_solid_fn.call(col, cy):
							clear = false
					if col == tc:
						break
					col += step
				if clear:
					_add_extended_edge(id, standable_cells[target_cell], Vector2(float(dx), float(rise)).length() * 1.3)

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
	if node_positions.has(from_id) and node_positions.has(to_id):
		var a: Vector2 = node_positions[from_id]
		var b: Vector2 = node_positions[to_id]
		edges.append({"from": from_id, "to": to_id, "type": int(type), "weight": weight, "both": both_ways,
				"rise_px": maxf(a.y - b.y, 0.0), "run_px": absf(b.x - a.x)})
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

func _add_extended_edge(from_id: int, to_id: int, weight: float) -> void:
	var key := Vector2i(from_id, to_id)
	if edge_types.has(key):
		return
	edge_types[key] = int(EdgeType.JUMP)
	var a: Vector2 = node_positions[from_id]
	var b: Vector2 = node_positions[to_id]
	edges.append({"from": from_id, "to": to_id, "type": int(EdgeType.JUMP), "weight": weight, "both": false,
			"rise_px": maxf(a.y - b.y, 0.0), "run_px": absf(b.x - a.x), "extended": true})


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
		for g in _capable_cache.values():
			if (g as AStar2D).has_point(id):
				(g as AStar2D).set_point_disabled(id, not open)

func set_standable(cell: Vector2i, standable: bool) -> void:
	var id: int = cell.y * width + cell.x
	if astar_all.has_point(id):
		astar_all.set_point_disabled(id, not standable)
	if astar_no_jump.has_point(id):
		astar_no_jump.set_point_disabled(id, not standable)
	for g in _capable_cache.values():
		if (g as AStar2D).has_point(id):
			(g as AStar2D).set_point_disabled(id, not standable)


## JumpLink: hand-authored jump between two feet positions (Marker2D JumpLink or
## data/level.json "jump_links"). Becomes a JUMP edge usable by capable fighters.
func add_link(from_px: Vector2, to_px: Vector2, both_ways: bool) -> bool:
	var a: int = astar_all.get_closest_point(from_px)
	var b: int = astar_all.get_closest_point(to_px)
	if a == -1 or b == -1 or a == b:
		return false
	_add_edge(a, b, EdgeType.JUMP, 1.0, both_ways)
	if both_ways:
		var pa: Vector2 = node_positions[a]
		var pb: Vector2 = node_positions[b]
		edges.append({"from": b, "to": a, "type": int(EdgeType.JUMP), "weight": 1.0, "both": false,
				"rise_px": maxf(pb.y - pa.y, 0.0), "run_px": absf(pa.x - pb.x)})
	_capable_cache.clear()
	_best_types.clear()
	return true


## Path for a fighter that can rise at most `max_rise_px` and cross at most
## `max_run_px` horizontally in one jump (from its FighterStats). Same result
## format as find_path(). Graphs are cached per capability.
func find_path_capable(from_px: Vector2, to_px: Vector2, max_rise_px: float, max_run_px: float) -> Dictionary:
	var key := Vector2i(int(max_rise_px), int(max_run_px))
	if not _capable_cache.has(key):
		_capable_cache[key] = _build_capable(max_rise_px, max_run_px)
	var astar: AStar2D = _capable_cache[key]
	var empty := { "points": PackedVector2Array(), "types": [], "ids": [] }
	var id_from: int = astar.get_closest_point(from_px)
	var id_to: int = astar.get_closest_point(to_px)
	if id_from == -1 or id_to == -1:
		return empty
	var id_path: PackedInt64Array = astar.get_id_path(id_from, id_to)
	if id_path.is_empty():
		return empty
	var pts := PackedVector2Array()
	var types: Array[int] = []
	var ids: Array[int] = []
	for i in range(id_path.size()):
		var cur_id: int = int(id_path[i])
		ids.append(cur_id)
		pts.append(node_positions.get(cur_id, from_px))
		types.append(int(EdgeType.WALK) if i == 0 else int(_best_types.get(Vector2i(int(id_path[i - 1]), cur_id), int(EdgeType.WALK))))
	return { "points": pts, "types": types, "ids": ids }


## The legacy builder lets a rise-0 JUMP overwrite a WALK between neighbours in
## edge_types (legacy enemies hop along paths). Capable paths prefer the
## cheapest way to traverse a pair: WALK, then DROP, then JUMP.
func _rebuild_best_types() -> void:
	_best_types.clear()
	var rank: Dictionary = {int(EdgeType.WALK): 0, int(EdgeType.DROP): 1, int(EdgeType.JUMP): 2}
	for e in edges:
		var t: int = int(e["type"])
		for key in ([Vector2i(int(e["from"]), int(e["to"])), Vector2i(int(e["to"]), int(e["from"]))] if bool(e["both"]) else [Vector2i(int(e["from"]), int(e["to"]))]):
			if not _best_types.has(key) or int(rank[t]) < int(rank[int(_best_types[key])]):
				_best_types[key] = t


func _build_capable(max_rise_px: float, max_run_px: float) -> AStar2D:
	if _best_types.is_empty():
		_rebuild_best_types()
	var g := EdgeCostAStar.new()
	for id in astar_all.get_point_ids():
		# Neutral point weights: costs come from EdgeCostAStar (legacy builder leaves
		# arbitrary per-point scales from whichever edge was added last).
		g.add_point(id, astar_all.get_point_position(id), 1.0)
		g.set_point_disabled(id, astar_all.is_point_disabled(id))
	for e in edges:
		if int(e["type"]) == int(EdgeType.JUMP):
			if float(e["rise_px"]) > max_rise_px or float(e["run_px"]) > max_run_px:
				continue
		var f: int = int(e["from"])
		var t: int = int(e["to"])
		if g.has_point(f) and g.has_point(t) and not g.are_points_connected(f, t, bool(e["both"])):
			g.connect_points(f, t, bool(e["both"]))
		for key in [Vector2i(f, t), Vector2i(t, f)]:
			if int(_best_types.get(key, int(EdgeType.WALK))) == int(EdgeType.JUMP):
				g.penalties[key] = JUMP_COST_MULT
	return g
