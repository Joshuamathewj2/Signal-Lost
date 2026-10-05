class_name TestLevelParser
extends RefCounted

const ParserScript = preload("res://scenes/level/level_parser.gd")
const SolidMergerScript = preload("res://scenes/level/solid_merger.gd")

const LEVEL_01_SAMPLE: String = """;name=Level 1
;decoys=0
;seed=101
;music=calm
########################################
#......................................#
#......................................#
#......................................#
#......................................#
#..........................F...........#
#.......................=======........#
#......................................#
#...................###................#
#.P.......###.......###.............E..#
########################################"""

func run() -> Array[String]:
	var failures: Array[String] = []

	# 1. Test parsing level_test.txt from file
	var test_data: LevelData = ParserScript.parse_file("res://levels/level_test.txt")
	if test_data == null:
		failures.append("Failed to load and parse res://levels/level_test.txt")
		return failures

	if test_data.name != "Test Facility":
		failures.append("Expected name 'Test Facility', got '%s'" % test_data.name)
	if test_data.decoys != 2:
		failures.append("Expected decoys 2, got %d" % test_data.decoys)
	if test_data.seed != 42:
		failures.append("Expected seed 42, got %d" % test_data.seed)
	if test_data.width != 20:
		failures.append("Expected width 20, got %d" % test_data.width)
	if test_data.height != 8:
		failures.append("Expected height 8, got %d" % test_data.height)
	if test_data.player_spawn != Vector2i(2, 6):
		failures.append("Expected spawn (2,6), got %s" % str(test_data.player_spawn))
	if test_data.exit_cell != Vector2i(17, 6):
		failures.append("Expected exit (17,6), got %s" % str(test_data.exit_cell))

	# Verify every character key in cells dictionary
	var expected_chars: Array[String] = ["#", "=", "P", "E", "F", "K", "D", "R", "_", ">", "<", "G", "~", "V", "v", "M", "L", "S", "H", "B", "|", "C", "?"]
	for ch in expected_chars:
		if not test_data.cells.has(ch) or (test_data.cells[ch] as Array).is_empty():
			failures.append("Expected character '%s' in test_data.cells" % ch)

	# 2. Test Level 1 text parsing
	var l1_data: LevelData = ParserScript.parse_text(LEVEL_01_SAMPLE)
	if l1_data == null:
		failures.append("Failed to parse LEVEL_01_SAMPLE string")
		return failures

	if l1_data.width != 40:
		failures.append("Expected Level 1 width 40, got %d" % l1_data.width)
	if l1_data.height != 11:
		failures.append("Expected Level 1 height 11, got %d" % l1_data.height)
	if l1_data.player_spawn != Vector2i(2, 9):
		failures.append("Expected Level 1 spawn (2,9), got %s" % str(l1_data.player_spawn))
	if l1_data.exit_cell != Vector2i(36, 9):
		failures.append("Expected Level 1 exit (36,9), got %s" % str(l1_data.exit_cell))
	if l1_data.name != "Level 1":
		failures.append("Expected Level 1 name 'Level 1', got '%s'" % l1_data.name)
	# 3. Test SolidMerger on Level 1
	var solid_rects: Array[Rect2i] = SolidMergerScript.merge(l1_data.grid, "#")
	if solid_rects.size() > 12:
		failures.append("Expected Level 1 solids <= 12 rects, got %d" % solid_rects.size())

	return failures
