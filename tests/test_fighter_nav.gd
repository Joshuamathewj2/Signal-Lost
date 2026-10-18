extends RefCounted

## Fighter stats + capability-limited PlatformGraph pathing (Step 0B).

const LEVEL: String = """;name=nav test
########################################
#......................................#
#..###.................................#
#......................................#
#..........................##########..#
#.....................######.........E.#
#.P..................#######...........#
##########...#########################.#
##########...##########################.
##########...###########################
########################################
"""


func run() -> Array[String]:
	var failures: Array[String] = []

	# --- stats from JSON ---
	var d: Dictionary = DataLoader.load_json("res://data/enemies/test_fighter.json")
	var st: FighterStats = FighterStats.new().apply_dict(d, "test_fighter")
	if absf(st.jump_apex() - 84.0) > 0.01:
		failures.append("jump_height 84 should give apex 84, got %.2f" % st.jump_apex())
	var hero: FighterStats = FighterStats.new().apply_game_config(GameConfig.data)
	if absf(hero.jump_apex() - 560.0 * 560.0 / 3600.0) > 0.01:
		failures.append("hero apex mismatch %.2f" % hero.jump_apex())

	# --- capability-limited paths ---
	var data: LevelData = LevelParser.parse_text(LEVEL)
	var g := PlatformGraph.new()
	g.build(data)
	var start := Vector2(2.5 * 32.0, 7.0 * 32.0)      # left floor
	var across := Vector2(16.5 * 32.0, 7.0 * 32.0)    # right of the 3-wide pit (cols 10..12)
	var high := Vector2(23.5 * 32.0, 5.0 * 32.0)      # 2 tiles up from the right floor

	var capable: Dictionary = g.find_path_capable(start, across, st.jump_apex() - 8.0, st.max_gap + 32.0)
	if not _reaches(capable, across):
		failures.append("capable fighter could not path across the 3-wide pit")
	elif not _has_long_jump(capable, 96.0):
		failures.append("pit crossing did not use an extended (>3 tile) jump edge")

	var weak: Dictionary = g.find_path_capable(across, high, 24.0, 64.0)
	if _reaches(weak, high):
		failures.append("a 24 px jumper should not climb the 1-tile steps")
	var strong: Dictionary = g.find_path_capable(across, high, st.jump_apex() - 8.0, st.max_gap + 32.0)
	if not _reaches(strong, high):
		failures.append("an 84 px jumper should climb a 2-tile ledge")

	# Legacy A* untouched: never uses edges beyond 3 tiles across / 2 up.
	var legacy: Dictionary = g.find_path(start, high, true)
	var pts: PackedVector2Array = legacy["points"]
	for i in range(1, pts.size()):
		if absf(pts[i].x - pts[i - 1].x) > 96.5 or pts[i - 1].y - pts[i].y > 64.5:
			failures.append("legacy path used an extended edge %s -> %s" % [pts[i - 1], pts[i]])
			break

	# --- JumpLink: opens a jump the automatic graph does not generate ---
	# Floating island (cols 3..5, stand row 1) is 5 tiles above the floor.
	var floor_pt := Vector2(4.5 * 32.0, 7.0 * 32.0)
	var island := Vector2(4.5 * 32.0, 2.0 * 32.0)
	var before: bool = _reaches(g.find_path_capable(floor_pt, island, 200.0, 320.0), island)
	g.add_link(floor_pt, island, true)
	var after: bool = _reaches(g.find_path_capable(floor_pt, island, 200.0, 320.0), island)
	var too_weak: bool = _reaches(g.find_path_capable(floor_pt, island, 120.0, 320.0), island)
	if too_weak:
		failures.append("a 120 px jumper must not use a 160 px JumpLink")
	if before or not after:
		failures.append("JumpLink should enable the far jump (before=%s after=%s)" % [before, after])
	return failures


func _reaches(res: Dictionary, goal: Vector2) -> bool:
	var pts: PackedVector2Array = res.get("points", PackedVector2Array())
	return not pts.is_empty() and pts[pts.size() - 1].distance_to(goal) < 17.0


func _has_long_jump(res: Dictionary, min_run: float) -> bool:
	var pts: PackedVector2Array = res["points"]
	var types: Array = res["types"]
	for i in range(1, pts.size()):
		if int(types[i]) == PlatformGraph.EdgeType.JUMP and absf(pts[i].x - pts[i - 1].x) > min_run:
			return true
	return false
