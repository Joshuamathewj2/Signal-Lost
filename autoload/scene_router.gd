extends Node

signal level_loaded(level_root: Node)

var current_scene_path: String = ""

func goto_scene(path: String) -> void:
	current_scene_path = path
	DebugFlags.log(&"router", "goto_scene: %s" % path)

func restart_level() -> void:
	DebugFlags.log(&"router", "restart_level")

func load_level(index: int) -> void:
	GameState.level_index = index
	DebugFlags.log(&"router", "load_level %d" % index)

func next_level() -> void:
	load_level(GameState.level_index + 1)
