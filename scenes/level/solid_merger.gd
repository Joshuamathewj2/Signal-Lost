class_name SolidMerger
extends RefCounted

static func merge(grid: PackedStringArray, target_char: String = "#") -> Array[Rect2i]:
	var result: Array[Rect2i] = []
	if grid.is_empty():
		return result

	var height: int = grid.size()
	var width: int = grid[0].length()

	# 1. Extract horizontal spans row by row
	# active_rects: Array[Rect2i]
	var active_rects: Array[Rect2i] = []

	for r in range(height):
		var row_str: String = grid[r]
		var row_spans: Array[Rect2i] = []

		var in_span: bool = false
		var span_start: int = 0

		for c in range(width):
			var matches: bool = (c < row_str.length() and row_str[c] == target_char)
			if matches:
				if not in_span:
					in_span = true
					span_start = c
			else:
				if in_span:
					in_span = false
					row_spans.append(Rect2i(span_start, r, c - span_start, 1))

		if in_span:
			row_spans.append(Rect2i(span_start, r, width - span_start, 1))

		# 2. Try to vertically merge spans into active_rects
		var next_active: Array[Rect2i] = []
		var span_merged: Array[bool] = []
		for _i in range(row_spans.size()):
			span_merged.append(false)

		for active in active_rects:
			var merged: bool = false
			for s_idx in range(row_spans.size()):
				if not span_merged[s_idx]:
					var span: Rect2i = row_spans[s_idx]
					if span.position.x == active.position.x and span.size.x == active.size.x and span.position.y == active.position.y + active.size.y:
						# Extend active rect downward
						active.size.y += 1
						next_active.append(active)
						span_merged[s_idx] = true
						merged = true
						break
			if not merged:
				result.append(active)

		# Add unmerged spans as new active rects
		for s_idx in range(row_spans.size()):
			if not span_merged[s_idx]:
				next_active.append(row_spans[s_idx])

		active_rects = next_active

	for remaining in active_rects:
		result.append(remaining)

	return result
