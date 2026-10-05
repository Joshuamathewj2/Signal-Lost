class_name EdgeBuilder
extends RefCounted

static func build(data: LevelData, parent: Node2D) -> Node2D:
	var edge_lines: Node2D = Node2D.new()
	edge_lines.name = "EdgeLines"
	parent.add_child(edge_lines)

	if data.grid.is_empty():
		return edge_lines

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = data.seed

	var height: int = data.height
	var width: int = data.width

	var is_solid_fn := func(c: int, r: int) -> bool:
		if c < 0 or c >= width or r < 0 or r >= height:
			return true
		return data.grid[r][c] == "#"

	# 1. Top edges on solid cells
	for r in range(height):
		var in_span: bool = false
		var span_start: int = 0
		for c in range(width):
			var has_edge: bool = is_solid_fn.call(c, r) and not is_solid_fn.call(c, r - 1)
			if has_edge:
				if not in_span:
					in_span = true
					span_start = c
			else:
				if in_span:
					in_span = false
					var p0 := Vector2(span_start * 32, r * 32)
					var p1 := Vector2(c * 32, r * 32)
					edge_lines.add_child(EdgeLineFactory.make_edge(p0, p1, true, rng))
		if in_span:
			var p0 := Vector2(span_start * 32, r * 32)
			var p1 := Vector2(width * 32, r * 32)
			edge_lines.add_child(EdgeLineFactory.make_edge(p0, p1, true, rng))

	# 2. Bottom edges on solid cells
	for r in range(height):
		var in_span: bool = false
		var span_start: int = 0
		for c in range(width):
			var has_edge: bool = is_solid_fn.call(c, r) and not is_solid_fn.call(c, r + 1)
			if has_edge:
				if not in_span:
					in_span = true
					span_start = c
			else:
				if in_span:
					in_span = false
					var p0 := Vector2(span_start * 32, (r + 1) * 32)
					var p1 := Vector2(c * 32, (r + 1) * 32)
					edge_lines.add_child(EdgeLineFactory.make_edge(p0, p1, false, rng))
		if in_span:
			var p0 := Vector2(span_start * 32, (r + 1) * 32)
			var p1 := Vector2(width * 32, (r + 1) * 32)
			edge_lines.add_child(EdgeLineFactory.make_edge(p0, p1, false, rng))

	# 3. Left edges on solid cells
	for c in range(width):
		var in_span: bool = false
		var span_start: int = 0
		for r in range(height):
			var has_edge: bool = is_solid_fn.call(c, r) and not is_solid_fn.call(c - 1, r)
			if has_edge:
				if not in_span:
					in_span = true
					span_start = r
			else:
				if in_span:
					in_span = false
					var p0 := Vector2(c * 32, span_start * 32)
					var p1 := Vector2(c * 32, r * 32)
					edge_lines.add_child(EdgeLineFactory.make_edge(p0, p1, false, rng))
		if in_span:
			var p0 := Vector2(c * 32, span_start * 32)
			var p1 := Vector2(c * 32, height * 32)
			edge_lines.add_child(EdgeLineFactory.make_edge(p0, p1, false, rng))

	# 4. Right edges on solid cells
	for c in range(width):
		var in_span: bool = false
		var span_start: int = 0
		for r in range(height):
			var has_edge: bool = is_solid_fn.call(c, r) and not is_solid_fn.call(c + 1, r)
			if has_edge:
				if not in_span:
					in_span = true
					span_start = r
			else:
				if in_span:
					in_span = false
					var p0 := Vector2((c + 1) * 32, span_start * 32)
					var p1 := Vector2((c + 1) * 32, r * 32)
					edge_lines.add_child(EdgeLineFactory.make_edge(p0, p1, false, rng))
		if in_span:
			var p0 := Vector2((c + 1) * 32, span_start * 32)
			var p1 := Vector2((c + 1) * 32, height * 32)
			edge_lines.add_child(EdgeLineFactory.make_edge(p0, p1, false, rng))

	# 5. One-way platforms top edges
	for r in range(height):
		var in_span: bool = false
		var span_start: int = 0
		for c in range(width):
			var has_ow: bool = (c < data.grid[r].length() and data.grid[r][c] == "=")
			if has_ow:
				if not in_span:
					in_span = true
					span_start = c
			else:
				if in_span:
					in_span = false
					var p0 := Vector2(span_start * 32, r * 32)
					var p1 := Vector2(c * 32, r * 32)
					edge_lines.add_child(EdgeLineFactory.make_edge(p0, p1, true, rng))
		if in_span:
			var p0 := Vector2(span_start * 32, r * 32)
			var p1 := Vector2(width * 32, r * 32)
			edge_lines.add_child(EdgeLineFactory.make_edge(p0, p1, true, rng))

	return edge_lines
