class_name LevelValidator
extends RefCounted

static func validate(data: LevelData) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []

	if data == null or data.grid.is_empty():
		errors.append("Empty level data")
		return { "errors": errors, "warnings": warnings }

	var w: int = data.width
	var h: int = data.height

	# 1. Dimensions check
	if w > 48:
		errors.append("Width %d exceeds max 48" % w)
	if h > 32:
		errors.append("Height %d exceeds max 32" % h)

	for r in range(h):
		if data.grid[r].length() != w:
			errors.append("Row %d has length %d, expected %d" % [r, data.grid[r].length(), w])

	var is_room: bool = data.headers.has("room")

	# Border check (campaign levels must have closed borders; rooms can have door passages)
	if not is_room:
		if not data.grid.is_empty() and data.grid[0].length() == w:
			for c in range(w):
				if data.grid[0][c] != "#":
					errors.append("Top border not solid at col %d" % c)
				if data.grid[h - 1].length() == w and data.grid[h - 1][c] != "#":
					errors.append("Bottom border not solid at col %d" % c)

		for r in range(h):
			if data.grid[r].length() == w:
				if data.grid[r][0] != "#":
					errors.append("Left border not solid at row %d" % r)
				if data.grid[r][w - 1] != "#":
					errors.append("Right border not solid at row %d" % r)

	# 2. Player and Exit checks
	var p_cells: Array = data.cells.get("P", [])
	if p_cells.size() != 1:
		errors.append("Expected exactly 1 'P', found %d" % p_cells.size())

	var e_cells: Array = data.cells.get("E", [])
	if is_room:
		if e_cells.size() > 1:
			errors.append("Expected at most 1 'E' in room, found %d" % e_cells.size())
	else:
		if e_cells.size() != 1:
			errors.append("Expected exactly 1 'E', found %d" % e_cells.size())

	# 3. Vertical runs of 2 for doors (D, R, >, <)
	for d_char in ["D", "R", ">", "<"]:
		var d_list: Array = data.cells.get(d_char, [])
		if not d_list.is_empty():
			if d_list.size() % 2 != 0:
				errors.append("Door '%s' cell count %d is not even" % [d_char, d_list.size()])
			for cell in d_list:
				var has_up: bool = (cell.y > 0 and cell.x < data.grid[cell.y - 1].length() and data.grid[cell.y - 1][cell.x] == d_char)
				var has_down: bool = (cell.y < h - 1 and cell.x < data.grid[cell.y + 1].length() and data.grid[cell.y + 1][cell.x] == d_char)
				if not (has_up or has_down):
					errors.append("Door '%s' at %s is isolated, expected vertical run of 2" % [d_char, str(cell)])

	# 4. Count of V == count of v
	var v_in: int = data.cells.get("V", []).size()
	var v_out: int = data.cells.get("v", []).size()
	if v_in != v_out:
		errors.append("Vent intake count %d != outlet count %d" % [v_in, v_out])

	# 5. Enemy distance from P >= 5 Manhattan
	if p_cells.size() == 1:
		var p_pos: Vector2i = data.player_spawn
		for e_char in ["L", "S", "H", "B", "A", "K", "Y"]:
			for e_cell in data.cells.get(e_char, []):
				var manhattan: int = abs(e_cell.x - p_pos.x) + abs(e_cell.y - p_pos.y)
				if manhattan < 5:
					errors.append("Enemy '%s' at %s too close to player spawn %s (dist %d < 5)" % [e_char, str(e_cell), str(p_pos), manhattan])

	# 6. Check all pickups and enemy spawns are NOT inside solid geometry
	for cat in ["F", "K", "C", "E", "L", "S", "H", "B", "A", "K", "Y"]:
		for cell in data.cells.get(cat, []):
			if cell.y < 0 or cell.y >= h or cell.x < 0 or cell.x >= w:
				errors.append("Entity '%s' at %s is out of level bounds" % [cat, str(cell)])
			elif data.grid[cell.y][cell.x] == "#":
				errors.append("Entity '%s' at %s is embedded inside solid geometry '#'" % [cat, str(cell)])

	# 6.5. Trap Safety & Placement Rules
	var trap_chars: Array[String] = ["^", "*", ")", "}", "\"", "!", "@", "Q", "%", "$"]
	if p_cells.size() == 1:
		var p_pos: Vector2i = data.player_spawn
		for t_char in trap_chars:
			for t_cell in data.cells.get(t_char, []):
				if t_cell == p_pos:
					errors.append("Trap '%s' at %s spawns directly on player spawn %s" % [t_char, str(t_cell), str(p_pos)])
				if t_cell == data.exit_cell:
					errors.append("Trap '%s' at %s spawns directly on exit terminal %s" % [t_char, str(t_cell), str(data.exit_cell)])
				var dist: int = abs(t_cell.x - p_pos.x) + abs(t_cell.y - p_pos.y)
				if dist < 2:
					errors.append("Trap '%s' at %s is too close to player spawn (dist %d < 2)" % [t_char, str(t_cell), dist])
				if t_cell.y < 0 or t_cell.y >= h or t_cell.x < 0 or t_cell.x >= w:
					errors.append("Trap '%s' at %s is out of level bounds" % [t_char, str(t_cell)])
				elif data.grid[t_cell.y][t_cell.x] == "#":
					errors.append("Trap '%s' at %s is embedded inside solid geometry '#'" % [t_char, str(t_cell)])

	# 7. Exit, Keycard & Fragment reachability on PlatformGraph
	if p_cells.size() == 1 and e_cells.size() == 1 and errors.is_empty():
		var graph: PlatformGraph = PlatformGraph.new()
		graph.build(data)

		var p_start := Vector2((float(data.player_spawn.x) + 0.5) * 32.0, (float(data.player_spawn.y) + 1.0) * 32.0)
		var p_exit := Vector2((float(data.exit_cell.x) + 0.5) * 32.0, (float(data.exit_cell.y) + 1.0) * 32.0)

		var k_cells: Array = data.cells.get("K", [])
		var has_plate: bool = not (data.cells.get("_", []) as Array).is_empty()

		# Open R doors if plate exists
		if has_plate:
			for r_pos in data.cells.get("R", []):
				graph.set_door_open(r_pos, true)

		# If there are keycards, verify player can reach each keycard
		if not k_cells.is_empty():
			for k_cell in k_cells:
				var p_key := Vector2((float(k_cell.x) + 0.5) * 32.0, (float(k_cell.y) + 1.0) * 32.0)
				var res_k: Dictionary = graph.find_path(p_start, p_key, true)
				if (res_k.get("points", PackedVector2Array()) as PackedVector2Array).is_empty():
					errors.append("Keycard at %s is not reachable from player spawn %s" % [str(k_cell), str(data.player_spawn)])

			# Once keycards are reached, doors D unlock
			for d_pos in data.cells.get("D", []):
				graph.set_door_open(d_pos, true)

			# Bidirectional Return Rule: from each keycard, assert player can reach exit
			for k_cell in k_cells:
				var p_key := Vector2((float(k_cell.x) + 0.5) * 32.0, (float(k_cell.y) + 1.0) * 32.0)
				var res_exit_from_k: Dictionary = graph.find_path(p_key, p_exit, true)
				if (res_exit_from_k.get("points", PackedVector2Array()) as PackedVector2Array).is_empty():
					errors.append("Exit cell at %s is not reachable from keycard %s (soft-lock)" % [str(data.exit_cell), str(k_cell)])

		# Validate Fragment reachability
		for f_cell in data.cells.get("F", []):
			var p_frag := Vector2((float(f_cell.x) + 0.5) * 32.0, (float(f_cell.y) + 1.0) * 32.0)
			var res_f: Dictionary = graph.find_path(p_start, p_frag, true)
			if (res_f.get("points", PackedVector2Array()) as PackedVector2Array).is_empty():
				errors.append("Fragment at %s is not reachable from player spawn %s" % [str(f_cell), str(data.player_spawn)])

		# Validate path to exit
		var res: Dictionary = graph.find_path(p_start, p_exit, true)
		if (res.get("points", PackedVector2Array()) as PackedVector2Array).is_empty():
			errors.append("Exit cell at %s is not reachable from player spawn %s" % [str(data.exit_cell), str(data.player_spawn)])

		# Anti-Pocket Trap Check: Verify landing cell at spawn has open exit
		var sp_ground_y: int = data.player_spawn.y
		while sp_ground_y < h - 1:
			var ch_below: String = data.grid[sp_ground_y + 1][data.player_spawn.x]
			if ch_below == "#" or ch_below == "=" or ch_below == "G":
				break
			sp_ground_y += 1
		
		var left_wall_h: int = 0
		var lx: int = data.player_spawn.x
		while lx > 0 and data.grid[sp_ground_y][lx] != "#":
			lx -= 1
		if data.grid[sp_ground_y][lx] == "#":
			var wy: int = sp_ground_y
			while wy >= 0 and data.grid[wy][lx] == "#":
				left_wall_h += 1
				wy -= 1

		var right_wall_h: int = 0
		var rx: int = data.player_spawn.x
		while rx < w - 1 and data.grid[sp_ground_y][rx] != "#":
			rx += 1
		if data.grid[sp_ground_y][rx] == "#":
			var wy: int = sp_ground_y
			while wy >= 0 and data.grid[wy][rx] == "#":
				right_wall_h += 1
				wy -= 1

		var pocket_w: int = (rx - 1) - (lx + 1) + 1
		var has_ladder_or_plat: bool = false
		for check_x in range(lx + 1, rx):
			for check_y in range(maxi(0, sp_ground_y - 4), sp_ground_y + 1):
				var pch: String = data.grid[check_y][check_x]
				if pch == "H" or pch == "=":
					has_ladder_or_plat = true
					break
			if has_ladder_or_plat:
				break

		if pocket_w < 12 and left_wall_h >= 3 and right_wall_h >= 3 and not has_ladder_or_plat:
			errors.append("Enclosed pocket trap at spawn (landing %s, w=%d, left_wall=%d, right_wall=%d > 2.7 max jump)" % [
				str(Vector2i(data.player_spawn.x, sp_ground_y)), pocket_w, left_wall_h, right_wall_h
			])

	return { "errors": errors, "warnings": warnings }
