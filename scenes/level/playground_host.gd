class_name PlaygroundHost
extends Node2D

## PlaygroundHost
## Runs Chapter II "The Undercroft" (data/level.json): loads one room at a time,
## carries the hero's HP through doors, remembers cleared rooms (a cleared seal
## room stays empty), counts seals, deaths and time, respawns the hero at the
## door they came in by, and ends the chapter when the Leviathan falls.

signal seal_broken(room_id: String, seals: int)
signal chapter_completed(stats: Dictionary)

const CHAPTER_COMPLETE_SCRIPT: Script = preload("res://scenes/ui/chapter_complete.gd")

@export var level_json_path: String = "res://data/level.json"
@export var initial_room: String = "room_01_hub"

var current_room: Node2D = null
var current_room_id: String = ""
var current_spawn_id: String = "default"
var level_data: Dictionary = {}
var is_transitioning: bool = false
var fade_layer: CanvasLayer = null
var fade_rect: ColorRect = null

var cleared_rooms: Dictionary = {}
var deaths: int = 0
var elapsed: float = 0.0
var completed: bool = false
var _carried_hp: int = -1
var _status_label: Label = null
var _intro_shown: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"chapter_host")
	_setup_fade_overlay()
	_setup_status_ui()
	_load_config()
	load_room(initial_room, "default")


func _exit_tree() -> void:
	# Hand the shared HUD back to the campaign untouched.
	var hud: Node = get_tree().get_first_node_in_group(&"hud") if is_inside_tree() else null
	var label: Node = hud.get("level_label") if hud != null else null
	if label != null:
		(label as CanvasItem).visible = true


func _process(delta: float) -> void:
	if not completed and not get_tree().paused:
		elapsed += delta
	if _status_label != null:
		_status_label.text = "SEALS %d / %d    %s" % [seal_count(), seals_required(), format_time(elapsed)]


static func format_time(t: float) -> String:
	return "%02d:%02d" % [int(t) / 60, int(t) % 60]


func _setup_fade_overlay() -> void:
	fade_layer = CanvasLayer.new()
	fade_layer.layer = 100
	add_child(fade_layer)
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade_rect)


func _setup_status_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 21
	add_child(layer)
	_status_label = Label.new()
	_status_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_status_label.position = Vector2(-340.0, 24.0)
	_status_label.size = Vector2(316.0, 28.0)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status_label.add_theme_font_override(&"font", preload("res://assets/fonts/Rajdhani-SemiBold.ttf"))
	_status_label.add_theme_font_size_override(&"font_size", 20)
	_status_label.add_theme_color_override(&"font_color", Color(0.95, 0.2, 0.2, 0.95))
	_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_status_label)


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


# --- Seals ---------------------------------------------------------------------

func seals_required() -> int:
	return int(level_data.get("seals_required", 0))


func seal_count() -> int:
	var n: int = 0
	var rooms: Dictionary = level_data.get("rooms", {})
	for rid in cleared_rooms:
		if bool((rooms.get(rid, {}) as Dictionary).get("seal", false)):
			n += 1
	return n


func _on_room_cleared(room_id: String) -> void:
	if cleared_rooms.has(room_id):
		return
	cleared_rooms[room_id] = true
	var r_info: Dictionary = (level_data.get("rooms", {}) as Dictionary).get(room_id, {})
	if not bool(r_info.get("seal", false)):
		return
	var n: int = seal_count()
	seal_broken.emit(room_id, n)
	var msg: String = "SEAL BROKEN - %d / %d" % [n, seals_required()]
	if n >= seals_required():
		msg = "ALL SEALS BROKEN - THE SANCTUM IS OPEN"
	_prompt(msg)
	get_tree().call_group(&"camera_rig", &"add_trauma", 0.3)
	if AudioManager != null:
		AudioManager.play_sfx(&"terminal_restore")
	# Breaking a seal restores one HP: a small reward for clearing a room.
	var p: Node = _room_player(current_room) if current_room != null else null
	if p != null:
		var hc: HealthComponent = p.get_node_or_null("HealthComponent") as HealthComponent
		if hc != null:
			hc.heal(1)


# --- Rooms ---------------------------------------------------------------------

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
	if "skip_enemies" in new_room:
		new_room.set("skip_enemies", cleared_rooms.has(room_id))
	add_child(new_room)
	current_room = new_room
	current_room_id = room_id
	current_spawn_id = spawn_id

	if new_room.has_signal("room_transition_requested"):
		new_room.connect("room_transition_requested", Callable(self, "_on_room_transition_requested"))
	if new_room.has_signal("room_cleared"):
		new_room.connect("room_cleared", Callable(self, "_on_room_cleared"))
	if new_room.has_signal("boss_defeated"):
		new_room.connect("boss_defeated", Callable(self, "_on_boss_defeated"))

	# Position player at spawn, carrying HP through doors. The old room is only
	# queued for deletion, so look for the hero inside the new room.
	var p: Node2D = _room_player(new_room)
	if p != null:
		var spawn_pos: Vector2 = new_room.get_spawn_pixel_position(spawn_id)
		p.global_position = spawn_pos
		if "velocity" in p:
			p.set("velocity", Vector2.ZERO)
		var hc: HealthComponent = p.get_node_or_null("HealthComponent") as HealthComponent
		if hc != null and _carried_hp > 0:
			hc.current_health = mini(_carried_hp, hc.max_health)
			hc.health_changed.emit(hc.current_health, hc.max_health)
		var cam_rig: Node2D = new_room.get("camera_rig") as Node2D
		if cam_rig != null:
			# Snap instead of panning across the room from the default spawn.
			cam_rig.set("target", p)
			cam_rig.set("target_y", spawn_pos.y)
			cam_rig.global_position = spawn_pos
			var cam: Camera2D = cam_rig.get("camera") as Camera2D
			if cam != null:
				cam.call_deferred("reset_smoothing")

	# Camera limits
	var cam_rig2 = new_room.get("camera_rig")
	if cam_rig2 != null and new_room.has_method("get_room_bounds"):
		cam_rig2.set_limits(new_room.call("get_room_bounds"))

	_bind_boss_bar(new_room)
	_update_room_label(str(r_info.get("name", room_id)))

	if not _intro_shown and level_data.has("intro"):
		_intro_shown = true
		_prompt(str(level_data["intro"]).replace("\n", " - "))
	elif not cleared_rooms.has(room_id):
		_prompt(str(r_info.get("intro", r_info.get("name", room_id.to_upper()))))
	else:
		_prompt(str(r_info.get("name", room_id)).to_upper() + " - SEAL BROKEN")


func _room_player(room: Node) -> Node2D:
	for n in room.get_children():
		if n.is_in_group(&"player"):
			return n as Node2D
	return get_tree().get_first_node_in_group(&"player") as Node2D


func _bind_boss_bar(room: Node) -> void:
	var boss: Node2D = null
	if "spawned_enemies" in room:
		for e in room.get("spawned_enemies"):
			if is_instance_valid(e) and (e as Node).is_in_group(&"boss"):
				boss = e
	var hud: Node = get_tree().get_first_node_in_group(&"hud")
	var bar: Node = hud.find_child("BossHealthBar", true, false) if hud != null else null
	if bar == null:
		return
	if boss != null and bar.has_method("bind_boss"):
		bar.call("bind_boss", boss)
		var title: Label = bar.get_node_or_null("TitleLabel") as Label
		if title != null:
			title.text = "THE LEVIATHAN"
		(bar as CanvasItem).modulate.a = 1.0
	else:
		(bar as CanvasItem).visible = false


## HUD bottom label: the room's name (hidden while a boss bar uses that spot).
func _update_room_label(room_name: String) -> void:
	var hud: Node = get_tree().get_first_node_in_group(&"hud")
	var label: Node = hud.get("level_label") if hud != null else null
	if label == null:
		return
	if label.has_method("set_level_name"):
		label.call("set_level_name", room_name)
	(label as CanvasItem).visible = get_tree().get_first_node_in_group(&"boss") == null or completed


func _prompt(text: String) -> void:
	var hud: Node = get_tree().get_first_node_in_group(&"hud")
	if hud != null and hud.has_method("show_tutorial_prompt"):
		hud.call("show_tutorial_prompt", text)


func _remember_hp() -> void:
	var p: Node = _room_player(current_room) if current_room != null else null
	var hc: HealthComponent = p.get_node_or_null("HealthComponent") as HealthComponent if p != null else null
	_carried_hp = hc.current_health if hc != null and hc.is_alive() else -1


func _on_room_transition_requested(target_room: String, target_spawn: String) -> void:
	if is_transitioning or completed:
		return
	is_transitioning = true
	_remember_hp()

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


## Called by SceneRouter.restart_level() (hero death / pause-menu restart):
## the current room reloads at the door the hero came in by, at full health.
func respawn() -> void:
	if completed:
		return
	deaths += 1
	_carried_hp = -1
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade_rect, "color:a", 1.0, 0.2)
	tween.tween_callback(func() -> void:
		load_room(current_room_id, current_spawn_id)
	)
	tween.tween_property(fade_rect, "color:a", 0.0, 0.2)


# --- Victory ---------------------------------------------------------------------

func _on_boss_defeated(_room_id: String) -> void:
	if completed:
		return
	completed = true
	_prompt("THE LEVIATHAN FALLS")
	var stats: Dictionary = {
		"chapter": int(level_data.get("chapter", 2)),
		"time": elapsed,
		"deaths": deaths,
		"seals": seal_count(),
	}
	var save_res: Dictionary = {}
	if SaveData != null and SaveData.has_method("save_chapter_result"):
		save_res = SaveData.save_chapter_result(int(stats["chapter"]), stats)
	chapter_completed.emit(stats)
	get_tree().create_timer(3.0).timeout.connect(func() -> void:
		if not is_inside_tree():
			return
		var screen: Control = CHAPTER_COMPLETE_SCRIPT.new() as Control
		var layer := CanvasLayer.new()
		layer.layer = 90
		add_child(layer)
		layer.add_child(screen)
		screen.call("setup", stats, save_res)
	)
