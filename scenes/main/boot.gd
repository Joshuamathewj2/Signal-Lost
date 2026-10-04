extends Node

func _ready() -> void:
	DebugFlags.log(&"boot", "SIGNAL LOST v1.0 running on Godot " + Engine.get_version_info().string)
