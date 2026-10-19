class_name PlaygroundHost
extends Node2D

@export var level_json_path: String = "res://data/level.json"
@export var initial_room: String = "room_01_hub"

const PLAYGROUND_ROOM_SCRIPT: Script = preload("res://scripts/level/playground_room.gd")

var current_room: Node2D = null
var current_room_id: String = ""
var level_data: Dictionary = {}
var is_transitioning: bool = false
var fade_layer: CanvasLayer = null
var fade_rect: ColorRect = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_fade_overlay()
	_load_config()
	load_room(initial_room, "default")

func _setup_fade_overlay() -> void:
	fade_layer = CanvasLayer.new()
	fade_layer.layer = 100
	add_child(fade_layer)
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade_rect)

func _load_config() -> void:
	if not FileAccess.file_exists(level_json_path):
		push_error("PlaygroundHost: level_json_path not found: " + level_json_path)
		return
	var f := FileAccess.open(level_json_path, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		level_data = parsed as Dictionary

func load_room(room_id: String, spawn_id: String = "default") -> void:
	if not level_data.has("rooms"):
		return
	var rooms: Dictionary = level_data["rooms"] as Dictionary
	if not rooms.has(room_id):
		push_error("PlaygroundHost: unknown room_id: " + room_id)
		return

	var r_info: Dictionary = rooms[room_id] as Dictionary
	var scene_file: String = str(r_info.get("scene_file", ""))
	if not ResourceLoader.exists(scene_file):
		push_error("PlaygroundHost: scene_file does not exist: " + scene_file)
		return

	var room_scene: PackedScene = load(scene_file) as PackedScene
	if room_scene == null:
		push_error("PlaygroundHost: failed to load " + scene_file)
		return

	if current_room != null and is_instance_valid(current_room):
		current_room.queue_free()
		current_room = null

	var new_room: Node2D = room_scene.instantiate() as Node2D
	if "room_id" in new_room:
		new_room.set("room_id", room_id)
	add_child(new_room)
	current_room = new_room
	current_room_id = room_id

	if new_room.has_signal("room_transition_requested"):
		new_room.connect("room_transition_requested", Callable(self, "_on_room_transition_requested"))

	# Position player at spawn
	var p: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	if p != null:
		var spawn_pos: Vector2 = new_room.get_spawn_pixel_position(spawn_id)
		p.global_position = spawn_pos
		if "velocity" in p:
			p.set("velocity", Vector2.ZERO)
		var health = p.get_node_or_null("Health")
		if health != null and health.has_signal("died"):
			if not health.died.is_connected(_on_player_died):
				health.died.connect(_on_player_died)

	# Camera limits
	var cam_rig = new_room.get("camera_rig")
	if cam_rig != null and new_room.has_method("get_room_bounds"):
		cam_rig.set_limits(new_room.call("get_room_bounds"))

	# Update HUD
	var hud: Node = get_tree().get_first_node_in_group(&"hud")
	if hud != null and hud.has_method("show_tutorial_prompt"):
		var r_name: String = str(r_info.get("name", room_id.to_upper()))
		hud.show_tutorial_prompt(r_name)

func _on_room_transition_requested(target_room: String, target_spawn: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade_rect, "color:a", 1.0, 0.12)
	tween.tween_callback(func() -> void:
		load_room(target_room, target_spawn)
	)
	tween.tween_property(fade_rect, "color:a", 0.0, 0.12)
	tween.tween_callback(func() -> void:
		is_transitioning = false
	)

func _on_player_died() -> void:
	# Respawn at checkpoint after short delay
	await get_tree().create_timer(1.5).timeout
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade_rect, "color:a", 1.0, 0.2)
	tween.tween_callback(func() -> void:
		load_room(current_room_id, "default")
	)
	tween.tween_property(fade_rect, "color:a", 0.0, 0.2)
