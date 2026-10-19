class_name PlaygroundRoom
extends LevelRoot

const DOOR_TRANSITION_SCRIPT: Script = preload("res://scenes/level/door_transition.gd")

signal room_transition_requested(target_room: String, target_spawn: String)
## Every villain listed for this room in level.json is dead.
signal room_cleared(room_id: String)
signal boss_defeated(room_id: String)

@export var room_id: String = "room_01_hub"
@export var level_json_path: String = "res://data/level.json"

var room_data: Dictionary = {}
var doors_node: Node2D = null
## Set by the host before entering: a cleared room stays empty.
var skip_enemies: bool = false
var spawned_enemies: Array[Node2D] = []
var _alive: int = 0

func _ready() -> void:
	_load_room_config()
	if level_path.is_empty() and room_data.has("txt_file"):
		level_path = str(room_data["txt_file"])
	super._ready()
	_setup_doors()
	_spawn_room_enemies()

func _load_room_config() -> void:
	if not FileAccess.file_exists(level_json_path):
		return
	var f := FileAccess.open(level_json_path, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary and (parsed as Dictionary).has("rooms"):
		var rooms: Dictionary = (parsed as Dictionary)["rooms"]
		if rooms.has(room_id):
			room_data = rooms[room_id]

func _setup_doors() -> void:
	if not room_data.has("doors"):
		return
	doors_node = Node2D.new()
	doors_node.name = "Doors"
	add_child(doors_node)

	var doors_arr: Array = room_data["doors"] as Array
	for d in doors_arr:
		if not (d is Dictionary):
			continue
		var door_info: Dictionary = d as Dictionary
		var rect_data: Array = door_info.get("trigger_rect", [0, 0, 2, 2])
		if rect_data.size() < 4:
			continue
		var rx: float = float(rect_data[0]) * 32.0
		var ry: float = float(rect_data[1]) * 32.0
		var rw: float = float(rect_data[2]) * 32.0
		var rh: float = float(rect_data[3]) * 32.0

		var door_inst: Area2D = DOOR_TRANSITION_SCRIPT.new() as Area2D
		door_inst.name = str(door_info.get("name", "Door"))
		door_inst.set("target_room", str(door_info.get("target_room", "")))
		door_inst.set("target_spawn", str(door_info.get("target_spawn", "default")))
		door_inst.set("label", str(door_info.get("label", "")))
		door_inst.set("required_seals", int(door_info.get("requires_seals", 0)))
		door_inst.set("rect_size", Vector2(rw, rh))
		door_inst.set("outer_side", -1 if rx < 64.0 else 1)

		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(rw, rh)
		col.shape = shape
		col.position = Vector2(rw * 0.5, rh * 0.5)
		door_inst.position = Vector2(rx, ry)
		door_inst.add_child(col)

		door_inst.transition_requested.connect(func(t_room: String, t_spawn: String) -> void:
			room_transition_requested.emit(t_room, t_spawn)
		)

		doors_node.add_child(door_inst)

## Spawns room_data.enemies ([{type, position: [tile_x, tile_y]}]) and counts
## them down; the last death emits room_cleared (and boss_defeated for bosses).
func _spawn_room_enemies() -> void:
	if skip_enemies or not room_data.has("enemies"):
		return
	for e in room_data["enemies"]:
		if not (e is Dictionary):
			continue
		var info: Dictionary = e as Dictionary
		var tile: Array = info.get("position", [0, 0])
		var inst: Node2D = EntitySpawner.spawn_villain(str(info.get("type", "")), Vector2i(int(tile[0]), int(tile[1])), enemies, platform_graph)
		if inst == null:
			continue
		spawned_enemies.append(inst)
		_alive += 1
		if inst.has_signal("boss_defeated"):
			inst.connect("boss_defeated", func() -> void:
				boss_defeated.emit(room_id)
				_on_enemy_down(inst)
			)
		else:
			var hc: Node = inst.get_node_or_null("HealthComponent")
			if hc != null:
				hc.connect("died", func(_cause: StringName) -> void: _on_enemy_down(inst))
		# Lost to a pit / out-of-bounds cleanup without dying still counts.
		inst.tree_exiting.connect(func() -> void:
			if is_inside_tree() and not is_queued_for_deletion():
				_on_enemy_down(inst)
		)


var _downed: Dictionary = {}

func _on_enemy_down(inst: Node) -> void:
	if _downed.has(inst):
		return
	_downed[inst] = true
	_alive -= 1
	if _alive == 0:
		room_cleared.emit(room_id)


func get_spawn_pixel_position(spawn_id: String) -> Vector2:
	if room_data.has("spawns"):
		var spawns: Dictionary = room_data["spawns"] as Dictionary
		if spawns.has(spawn_id):
			var tile: Array = spawns[spawn_id] as Array
			return Vector2((float(tile[0]) + 0.5) * 32.0, (float(tile[1]) + 1.0) * 32.0)
		elif spawns.has("default"):
			var def_tile: Array = spawns["default"] as Array
			return Vector2((float(def_tile[0]) + 0.5) * 32.0, (float(def_tile[1]) + 1.0) * 32.0)
	if current_level_data != null:
		return Vector2((float(current_level_data.player_spawn.x) + 0.5) * 32.0, (float(current_level_data.player_spawn.y) + 1.0) * 32.0)
	return Vector2(100.0, 100.0)

func get_room_bounds() -> Rect2i:
	if current_level_data != null:
		return Rect2i(0, 0, current_level_data.width * 32, current_level_data.height * 32)
	if room_data.has("grid_size"):
		var sz: Array = room_data["grid_size"] as Array
		return Rect2i(0, 0, int(sz[0]) * 32, int(sz[1]) * 32)
	return Rect2i(0, 0, 1280, 720)
