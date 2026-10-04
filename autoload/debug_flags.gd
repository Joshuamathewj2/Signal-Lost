extends Node

var overlay_visible: bool = false
var page: int = 0
var lights_off: bool = false

func log(cat: StringName, msg: String) -> void:
	if OS.is_debug_build():
		print("[%s] %s" % [cat, msg])

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_toggle"):
		overlay_visible = not overlay_visible
		self.log(&"debug", "overlay " + ("on" if overlay_visible else "off"))
	elif event.is_action_pressed(&"debug_next_page"):
		page = (page + 1) % 3
		self.log(&"debug", "page " + str(page))

