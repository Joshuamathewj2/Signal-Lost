class_name LevelParser
extends RefCounted

static func parse_file(path: String) -> LevelData:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("LevelParser: cannot open file: " + path)
		return null
	var text: String = file.get_as_text()
	return parse_text(text)

static func parse_text(text: String) -> LevelData:
	var data := LevelData.new()
	var lines: PackedStringArray = text.split("\n")
	var grid_rows: PackedStringArray = PackedStringArray()

	for raw_line in lines:
		var line: String = raw_line.strip_edges(false, true)
		if line.begins_with(";"):
			var header_content: String = line.substr(1).strip_edges()
			var eq_idx: int = header_content.find("=")
			if eq_idx != -1:
				var key: String = header_content.substr(0, eq_idx).strip_edges()
				var val: String = header_content.substr(eq_idx + 1).strip_edges()
				data.headers[key] = val
				match key:
					"name":
						data.name = val
					"decoys":
						data.decoys = int(val)
					"seed":
						data.seed = int(val)
		elif line.is_empty():
			continue
		else:
			grid_rows.append(line)

	if grid_rows.is_empty():
		push_error("LevelParser: empty grid")
		return data

	data.height = grid_rows.size()
	data.width = grid_rows[0].length()
	data.grid = grid_rows

	for r in range(data.height):
		var row_str: String = grid_rows[r]
		if row_str.length() != data.width:
			push_error("LevelParser: ragged row %d has length %d, expected %d" % [r, row_str.length(), data.width])
		for c in range(row_str.length()):
			var ch: String = row_str[c]
			if ch != ".":
				if not data.cells.has(ch):
					var arr: Array[Vector2i] = []
					data.cells[ch] = arr
				(data.cells[ch] as Array[Vector2i]).append(Vector2i(c, r))
				if ch == "P":
					data.player_spawn = Vector2i(c, r)
				elif ch == "E":
					data.exit_cell = Vector2i(c, r)

	return data
