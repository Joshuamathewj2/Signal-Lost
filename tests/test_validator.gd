class_name TestValidator
extends RefCounted

const ParserScript = preload("res://scenes/level/level_parser.gd")
const ValidatorScript = preload("res://scenes/level/level_validator.gd")

const BROKEN_NO_EXIT: String = """########
#......#
#.P....#
########"""

const BROKEN_RAGGED: String = """########
#......#
#.P...E
########"""

const BROKEN_ENEMY_NEAR_SPAWN: String = """########
#......#
#.PL..E#
########"""

func run() -> Array[String]:
	var failures: Array[String] = []

	# 1. Validate all level files in res://levels/
	var dir := DirAccess.open("res://levels/")
	if dir != null:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".txt"):
				var full_path := "res://levels/" + file_name
				var data: LevelData = ParserScript.parse_file(full_path)
				if data == null:
					failures.append("Validator test could not parse: " + full_path)
				else:
					var report: Dictionary = ValidatorScript.validate(data)
					var errs: Array = report.get("errors", [])
					if not errs.is_empty():
						failures.append("Level '%s' failed validation: %s" % [file_name, str(errs)])
			file_name = dir.get_next()

	# 2. Synthetic map: no exit -> must fail validation
	var data_no_exit: LevelData = ParserScript.parse_text(BROKEN_NO_EXIT)
	var rep_no_exit: Dictionary = ValidatorScript.validate(data_no_exit)
	if (rep_no_exit.get("errors", []) as Array).is_empty():
		failures.append("Expected validation failure for map with no exit")

	# 3. Synthetic map: ragged -> must fail validation
	var data_ragged: LevelData = ParserScript.parse_text(BROKEN_RAGGED)
	var rep_ragged: Dictionary = ValidatorScript.validate(data_ragged)
	if (rep_ragged.get("errors", []) as Array).is_empty():
		failures.append("Expected validation failure for ragged map")

	# 4. Synthetic map: enemy near spawn (< 5 tiles) -> must fail validation
	var data_near: LevelData = ParserScript.parse_text(BROKEN_ENEMY_NEAR_SPAWN)
	var rep_near: Dictionary = ValidatorScript.validate(data_near)
	if (rep_near.get("errors", []) as Array).is_empty():
		failures.append("Expected validation failure for enemy spawn within 5 tiles of player")

	return failures
