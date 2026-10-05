class_name EntitySpawner
extends RefCounted

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const LISTENER_SCENE: PackedScene = preload("res://scenes/enemies/listener.tscn")

static var _warned_stubs: Dictionary = {}

static func spawn_entities(data: LevelData, root: Node2D, graph: PlatformGraph) -> Dictionary:
	var result: Dictionary = {
		"player": null,
		"enemies": []
	}

	var enemies_node: Node2D = root.get_node_or_null("Enemies") as Node2D
	if enemies_node == null:
		enemies_node = root

	var interactables_node: Node2D = root.get_node_or_null("Interactables") as Node2D
	if interactables_node == null:
		interactables_node = root

	# 1. Spawn Player
	var p_cell: Vector2i = data.player_spawn
	var p_pos := Vector2((float(p_cell.x) + 0.5) * 32.0, (float(p_cell.y) + 1.0) * 32.0)
	var player_inst: Player = PLAYER_SCENE.instantiate() as Player
	player_inst.position = p_pos
	root.add_child(player_inst)
	result["player"] = player_inst

	# 2. Extract bounds for enemies
	var bounds_per_row: Dictionary = {}
	if data.cells.has("|"):
		for bound_cell in data.cells["|"]:
			var r: int = bound_cell.y
			if not bounds_per_row.has(r):
				bounds_per_row[r] = []
			(bounds_per_row[r] as Array).append(float(bound_cell.x * 32))

	# 3. Spawn Listener enemies
	if data.cells.has("L"):
		for cell in data.cells["L"]:
			var e_pos := Vector2((float(cell.x) + 0.5) * 32.0, (float(cell.y) + 1.0) * 32.0)
			var listener_inst: EnemyBase = LISTENER_SCENE.instantiate() as EnemyBase
			listener_inst.position = e_pos
			listener_inst.set_meta("spawn_pos", e_pos)
			if listener_inst.mover != null:
				listener_inst.mover.graph = graph
				if bounds_per_row.has(cell.y):
					var b_arr: Array = bounds_per_row[cell.y]
					b_arr.sort()
					var b_floats: Array[float] = []
					for b in b_arr:
						b_floats.append(float(b))
					listener_inst.mover.bounds = b_floats
			enemies_node.add_child(listener_inst)
			(result["enemies"] as Array).append(listener_inst)

	# 4. Stub warnings for unimplemented entities
	for ch in data.cells.keys():
		if ch != "#" and ch != "=" and ch != "P" and ch != "L" and ch != "|" and ch != ".":
			if not _warned_stubs.has(ch):
				_warned_stubs[ch] = true
				push_warning("STUB: spawn " + ch)

	return result
