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
	return _config.has_section("levels") or int(_config.get_value("progress", "continue_level", 0)) > 1

func get_continue_level() -> int:
	return int(_config.get_value("progress", "continue_level", 1))

func set_continue_level(level_index: int) -> void:
	_config.set_value("progress", "continue_level", level_index)
	_config.save(SAVE_PATH)

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
