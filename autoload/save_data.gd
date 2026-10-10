extends Node

signal settings_changed

const SAVE_PATH: String = "user://save.cfg"

var _config: ConfigFile = ConfigFile.new()

func _ready() -> void:
	load_data()
	apply_all_settings()

func load_data() -> void:
	var err := _config.load(SAVE_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		DebugFlags.log(&"save", "Failed to load save file: %d" % err)

func get_setting(key: String, default_value: Variant) -> Variant:
	return _config.get_value("settings", key, default_value)

func set_setting(key: String, value: Variant) -> void:
	_config.set_value("settings", key, value)
	_config.save(SAVE_PATH)
	settings_changed.emit()

func has_save() -> bool:
	return _config.has_section("levels") or _config.has_section("level_1") or int(_config.get_value("progress", "continue_level", 0)) > 1

func get_highest_unlocked_level() -> int:
	var highest := 1
	for i in range(1, 9):
		if is_level_unlocked(i):
			highest = i
	return highest

func get_continue_level() -> int:
	var cont: int = int(_config.get_value("progress", "continue_level", 1))
	return maxi(cont, get_highest_unlocked_level())

func set_continue_level(level_index: int) -> void:
	_config.set_value("progress", "continue_level", level_index)
	_config.save(SAVE_PATH)

func is_level_unlocked(level_index: int) -> bool:
	if level_index <= 1:
		return true
	var sec := "level_%d" % level_index
	return bool(_config.get_value(sec, "unlocked", false))

func get_level_data(level_index: int) -> Dictionary:
	var sec := "level_%d" % level_index
	return {
		"unlocked": is_level_unlocked(level_index),
		"best_time": float(_config.get_value(sec, "best_time", 999999.0)),
		"best_medal": StringName(_config.get_value(sec, "best_medal", &"none")),
		"fragments": int(_config.get_value(sec, "fragments", 0)),
		"fragments_mask": int(_config.get_value(sec, "fragments_mask", 0)),
	}

func clear_level_data(level_index: int) -> void:
	var sec := "level_%d" % level_index
	if _config.has_section(sec):
		_config.erase_section(sec)
		_config.save(SAVE_PATH)

static func medal_rank(medal: StringName) -> int:
	match medal:
		&"ghost":
			return 3
		&"quiet":
			return 2
		&"loud":
			return 1
		_:
			return 0

func save_level_result(level_index: int, run_stats: Dictionary) -> Dictionary:
	var sec := "level_%d" % level_index
	var old_time: float = float(_config.get_value(sec, "best_time", 999999.0))
	var old_medal: StringName = StringName(_config.get_value(sec, "best_medal", &"none"))
	var old_frags: int = int(_config.get_value(sec, "fragments", 0))

	var new_time: float = float(run_stats.get("time", 0.0))
	var new_medal: StringName = StringName(run_stats.get("medal", &"loud"))
	var new_frags: int = (run_stats.get("fragments", []) as Array).size()

	var frags_arr: Array = run_stats.get("fragments", [])
	var new_mask: int = 0
	for f in frags_arr:
		new_mask |= (1 << int(f))
	var old_mask: int = int(_config.get_value(sec, "fragments_mask", 0))
	var best_mask: int = old_mask | new_mask

	var is_new_best_time: bool = new_time < old_time or old_time >= 999998.0
	var is_new_best_medal: bool = medal_rank(new_medal) > medal_rank(old_medal)

	var best_time: float = minf(old_time, new_time)
	var best_medal: StringName = new_medal if is_new_best_medal else old_medal
	var best_frags: int = maxi(old_frags, new_frags)

	_config.set_value(sec, "unlocked", true)
	_config.set_value(sec, "best_time", best_time)
	_config.set_value(sec, "best_medal", str(best_medal))
	_config.set_value(sec, "fragments", best_frags)
	_config.set_value(sec, "fragments_mask", best_mask)

	# Unlock next level
	var next_sec := "level_%d" % (level_index + 1)
	_config.set_value(next_sec, "unlocked", true)

	var current_cont: int = get_continue_level()
	if level_index + 1 > current_cont and level_index + 1 <= 8:
		set_continue_level(level_index + 1)

	_config.save(SAVE_PATH)

	return {
		"is_new_best_time": is_new_best_time,
		"is_new_best_medal": is_new_best_medal,
		"best_time": best_time,
		"best_medal": best_medal,
		"medal": new_medal,
	}

func apply_all_settings() -> void:
	var m_vol: float = float(get_setting("master_volume", 80))
	var m_idx: int = AudioServer.get_bus_index(&"Master")
	if m_idx != -1:
		AudioServer.set_bus_volume_db(m_idx, linear_to_db(m_vol / 100.0) if m_vol > 0.0 else -80.0)

	var mu_vol: float = float(get_setting("music_volume", 70))
	var mu_idx: int = AudioServer.get_bus_index(&"Music")
	if mu_idx != -1:
		AudioServer.set_bus_volume_db(mu_idx, linear_to_db(mu_vol / 100.0) if mu_vol > 0.0 else -80.0)

	var s_vol: float = float(get_setting("sfx_volume", 80))
	var s_idx: int = AudioServer.get_bus_index(&"SFX")
	if s_idx != -1:
		AudioServer.set_bus_volume_db(s_idx, linear_to_db(s_vol / 100.0) if s_vol > 0.0 else -80.0)

	var cb: bool = bool(get_setting("colorblind_mode", false))
	if Palette != null:
		Palette.set_colorblind(cb)

	var fs: bool = bool(get_setting("fullscreen", false))
	if fs:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	var perf: bool = bool(get_setting("performance_mode", false))
	if GameConfig != null and GameConfig.has_method("set_sonar_quality"):
		GameConfig.set_sonar_quality(0 if perf else 1)

	settings_changed.emit()
