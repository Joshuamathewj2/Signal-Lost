extends Node

signal level_loaded(level_root: Node)

const LEVEL_ROOT_SCENE: PackedScene = preload("res://scenes/level/level_root.tscn")
const PLAYGROUND_HOST_SCENE: PackedScene = preload("res://scenes/level/playground_host.tscn")
const ATLAS_PREVIEW_SCENE: PackedScene = preload("res://tools/AtlasPreview.tscn")
const COMBAT_ARENA_SCENE: PackedScene = preload("res://scenes/test/combat_test_arena.tscn")

var current_level_index: int = 1
var current_level_root: Node = null
var is_transitioning: bool = false
var fade_rect: ColorRect = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		restart_level()
	elif OS.is_debug_build() and event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_F3:
			next_level()

func _ensure_fade_rect() -> ColorRect:
	if fade_rect != null and is_instance_valid(fade_rect):
		return fade_rect
	var menus: CanvasLayer = get_tree().root.get_node_or_null("Main/Menus") as CanvasLayer
	if menus != null:
		fade_rect = ColorRect.new()
		fade_rect.color = Color(0, 0, 0, 0)
		fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		menus.add_child(fade_rect)
	return fade_rect

func load_level(index: int) -> void:
	if is_transitioning:
		return
	var path := "res://levels/level_%02d.txt" % index
	if not FileAccess.file_exists(path):
		DebugFlags.log(&"router", "Level file not found: %s" % path)
		return

	current_level_index = index
	GameState.level_index = index
	DebugFlags.log(&"router", "load_level %d (%s)" % [index, path])

	var f_rect: ColorRect = _ensure_fade_rect()
	if f_rect != null:
		is_transitioning = true
		var tween := create_tween()
		tween.tween_property(f_rect, "color:a", 1.0, 0.12)
		tween.tween_callback(func() -> void:
			_spawn_level_instant(path)
		)
		tween.tween_property(f_rect, "color:a", 0.0, 0.13)
		tween.tween_callback(func() -> void:
			is_transitioning = false
		)
	else:
		_spawn_level_instant(path)

func restart_level() -> void:
	# Chapter II rooms respawn in place instead of reloading a campaign level.
	if current_level_root != null and is_instance_valid(current_level_root) and current_level_root.has_method("respawn"):
		current_level_root.call("respawn")
		return
	var path := "res://levels/level_%02d.txt" % current_level_index
	if not FileAccess.file_exists(path):
		path = "res://levels/level_test.txt"
	DebugFlags.log(&"router", "restart_level %d" % current_level_index)
	_spawn_level_instant(path)

func next_level() -> void:
	load_level(current_level_index + 1)

func return_to_main_menu() -> void:
	if current_level_root != null and is_instance_valid(current_level_root):
		current_level_root.queue_free()
		current_level_root = null
	var main_node: Node = get_tree().root.get_node_or_null("Main")
	if main_node != null and main_node.has_method("show_main_menu"):
		main_node.call("show_main_menu")

func load_playground(room_id: String = "room_01_hub") -> void:
	if is_transitioning:
		return
	var f_rect: ColorRect = _ensure_fade_rect()
	if f_rect != null:
		is_transitioning = true
		var tween := create_tween()
		tween.tween_property(f_rect, "color:a", 1.0, 0.12)
		tween.tween_callback(func() -> void:
			_spawn_scene_instant(PLAYGROUND_HOST_SCENE, {"initial_room": room_id})
		)
		tween.tween_property(f_rect, "color:a", 0.0, 0.13)
		tween.tween_callback(func() -> void:
			is_transitioning = false
		)
	else:
		_spawn_scene_instant(PLAYGROUND_HOST_SCENE, {"initial_room": room_id})

func load_atlas_preview() -> void:
	_spawn_scene_instant(ATLAS_PREVIEW_SCENE)

func load_combat_arena() -> void:
	_spawn_scene_instant(COMBAT_ARENA_SCENE)

func _spawn_scene_instant(scene: PackedScene, props: Dictionary = {}) -> void:
	var host: Node = get_tree().root.get_node_or_null("Main/LevelHost")
	if host == null:
		host = get_tree().current_scene
	if host == null:
		host = get_tree().root
	if host == null:
		return

	if current_level_root != null and is_instance_valid(current_level_root):
		current_level_root.queue_free()
		current_level_root = null

	var menus: Node = get_tree().root.get_node_or_null("Main/Menus")
	if menus != null:
		for child in menus.get_children():
			if child != null and child != fade_rect and child.name != "PauseMenu" and not (child is PauseMenu):
				child.queue_free()

	var new_root: Node = scene.instantiate()
	for k in props.keys():
		if k in new_root:
			new_root.set(k, props[k])
	host.add_child(new_root)
	current_level_root = new_root
	if new_root.has_signal("level_loaded"):
		level_loaded.emit(new_root)

func _spawn_level_instant(path: String) -> void:
	var host: Node = get_tree().root.get_node_or_null("Main/LevelHost")
	if host == null:
		host = get_tree().current_scene
	if host == null:
		host = get_tree().root
	if host == null:
		return

	if current_level_root != null and is_instance_valid(current_level_root):
		current_level_root.queue_free()
		current_level_root = null

	var menus: Node = get_tree().root.get_node_or_null("Main/Menus")
	if menus != null:
		for child in menus.get_children():
			if child != null and child != fade_rect and child.name != "PauseMenu" and not (child is PauseMenu):
				child.queue_free()

	var new_root = LEVEL_ROOT_SCENE.instantiate()
	if new_root == null:
		push_error("SceneRouter: failed to instantiate LEVEL_ROOT_SCENE")
		return
	new_root.set("level_path", path)
	host.add_child(new_root)
	current_level_root = new_root
	level_loaded.emit(new_root)
