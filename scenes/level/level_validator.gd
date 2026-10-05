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
	if w > 40:
		errors.append("Width %d exceeds max 40" % w)
	if h > 22:
		errors.append("Height %d exceeds max 22" % h)

	for r in range(h):
		if data.grid[r].length() != w:
			errors.append("Row %d has length %d, expected %d" % [r, data.grid[r].length(), w])

	# Border check
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

	# 2. Exactly one P and one E
	var p_cells: Array = data.cells.get("P", [])
	if p_cells.size() != 1:
		errors.append("Expected exactly 1 'P', found %d" % p_cells.size())

	var e_cells: Array = data.cells.get("E", [])
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
		for e_char in ["L", "S", "H", "B"]:
			for e_cell in data.cells.get(e_char, []):
				var manhattan: int = abs(e_cell.x - p_pos.x) + abs(e_cell.y - p_pos.y)
				if manhattan < 5:
					errors.append("Enemy '%s' at %s too close to player spawn %s (dist %d < 5)" % [e_char, str(e_cell), str(p_pos), manhattan])

	# 6. Exit reachability on PlatformGraph
	if p_cells.size() == 1 and e_cells.size() == 1 and errors.is_empty():
		var graph: PlatformGraph = PlatformGraph.new()
		graph.build(data)

		var p_start := Vector2((float(data.player_spawn.x) + 0.5) * 32.0, (float(data.player_spawn.y) + 1.0) * 32.0)
		var p_exit := Vector2((float(data.exit_cell.x) + 0.5) * 32.0, (float(data.exit_cell.y) + 1.0) * 32.0)

		# Initial path test
		var res: Dictionary = graph.find_path(p_start, p_exit, true)
		if (res.get("points", PackedVector2Array()) as PackedVector2Array).is_empty():
			# Check if doors can be opened via keys/plates
			var has_k: bool = not (data.cells.get("K", []) as Array).is_empty()
			var has_plate: bool = not (data.cells.get("_", []) as Array).is_empty()

			# Open D doors if K exists
			if has_k:
				for d_pos in data.cells.get("D", []):
					graph.set_door_open(d_pos, true)
			# Open R doors if plate exists
			if has_plate:
				for r_pos in data.cells.get("R", []):
					graph.set_door_open(r_pos, true)

			var res2: Dictionary = graph.find_path(p_start, p_exit, true)
			if (res2.get("points", PackedVector2Array()) as PackedVector2Array).is_empty():
				errors.append("Exit cell at %s is not reachable from player spawn %s" % [str(data.exit_cell), str(data.player_spawn)])

	return { "errors": errors, "warnings": warnings }
