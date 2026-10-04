extends Node

signal settings_changed

const SAVE_PATH: String = "user://save.cfg"

var _config: ConfigFile = ConfigFile.new()

func _ready() -> void:
	load_data()

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
