class_name TestPlatformGraph
extends RefCounted

const ParserScript = preload("res://scenes/level/level_parser.gd")
const GraphScript = preload("res://scenes/level/platform_graph.gd")

const LEVEL_01_TEXT: String = """;name=Level 1
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

const LEVEL_02_TEXT: String = """;name=Level 2
;decoys=0
;seed=202
;music=calm
########################################
#......................................#
#......................................#
#......................................#
#..........F...........................#
#.......===========...=========........#
#......................................#
#...====...............................#
#.P.................L...............E..#
########################################"""

const SYNTHETIC_3_HIGH: String = """#######
#.....#
#..#..#
#..#..#
#..#..#
#.P#E.#
#######"""

func run() -> Array[String]:
	var failures: Array[String] = []

	# 1. Level 1 spawn -> exit path exists
	var l1_data: LevelData = ParserScript.parse_text(LEVEL_01_TEXT)
	var g1 = GraphScript.new()
	g1.build(l1_data)

	var p1_start: Vector2 = Vector2((float(l1_data.player_spawn.x) + 0.5) * 32.0, (float(l1_data.player_spawn.y) + 1.0) * 32.0)
	var p1_exit: Vector2 = Vector2((float(l1_data.exit_cell.x) + 0.5) * 32.0, (float(l1_data.exit_cell.y) + 1.0) * 32.0)

	var res1: Dictionary = g1.find_path(p1_start, p1_exit, true)
	var pts1: PackedVector2Array = res1.get("points", PackedVector2Array())
	if pts1.is_empty():
		failures.append("Expected valid path from spawn to exit in Level 1")

	# 2. Level 2 path uses >= 1 JUMP
	var l2_data: LevelData = ParserScript.parse_text(LEVEL_02_TEXT)
	var g2 = GraphScript.new()
	g2.build(l2_data)

	var p2_start: Vector2 = Vector2((float(l2_data.player_spawn.x) + 0.5) * 32.0, (float(l2_data.player_spawn.y) + 1.0) * 32.0)
	var p2_catwalk: Vector2 = Vector2(10.5 * 32.0, 5.0 * 32.0)

	var res2: Dictionary = g2.find_path(p2_start, p2_catwalk, true)
	var types2: Array = res2.get("types", [])
	var jump_count: int = 0
	for t in types2:
		if int(t) == int(GraphScript.EdgeType.JUMP):
			jump_count += 1

	if jump_count == 0:
		failures.append("Expected >= 1 JUMP edge in Level 2 path to upper catwalk, got %d" % jump_count)

	# 3. Jump of 3 tiles up doesn't exist in synthetic map
	var l3_data: LevelData = ParserScript.parse_text(SYNTHETIC_3_HIGH)
	var g3 = GraphScript.new()
	g3.build(l3_data)

	var p3_start: Vector2 = Vector2((float(l3_data.player_spawn.x) + 0.5) * 32.0, (float(l3_data.player_spawn.y) + 1.0) * 32.0)
	var p3_top: Vector2 = Vector2(3.5 * 32.0, 2.0 * 32.0) # top of 3-high wall

	var res3: Dictionary = g3.find_path(p3_start, p3_top, true)
	var pts3: PackedVector2Array = res3.get("points", PackedVector2Array())
	if not pts3.is_empty():
		failures.append("Expected no path for 3-high vertical wall jump in synthetic map")

	return failures
