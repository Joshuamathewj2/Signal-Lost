class_name EntitySpawner
extends RefCounted

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const LISTENER_SCENE: PackedScene = preload("res://scenes/enemies/listener.tscn")
const SENTRY_SCENE: PackedScene = preload("res://scenes/enemies/sentry.tscn")
const HUNTER_SCENE: PackedScene = preload("res://scenes/enemies/hunter.tscn")
const BRUTE_SCENE: PackedScene = preload("res://scenes/enemies/brute.tscn")

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

	# 2. Spawn Interactables via InteractableSpawner
	InteractableSpawner.spawn_interactables(data, interactables_node, graph)

	# 3. Extract bounds for patrol enemies
	var bounds_per_row: Dictionary = {}
	if data.cells.has("|"):
		for bound_cell in data.cells["|"]:
			var b_vec: Vector2i = bound_cell
			var r: int = b_vec.y
			if not bounds_per_row.has(r):
				bounds_per_row[r] = []
			(bounds_per_row[r] as Array).append(float(b_vec.x * 32))

	# 4. Spawn Listener enemies (L)
	if data.cells.has("L"):
		for cell in data.cells["L"]:
			var cell_vec: Vector2i = cell
			var l_pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, (float(cell_vec.y) + 1.0) * 32.0)
			var listener_inst: EnemyBase = LISTENER_SCENE.instantiate() as EnemyBase
			listener_inst.position = l_pos
			listener_inst.set_meta("spawn_pos", l_pos)
			_setup_mover(listener_inst, graph, bounds_per_row, cell_vec.y)
			enemies_node.add_child(listener_inst)
			(result["enemies"] as Array).append(listener_inst)

	# 5. Spawn Sentry enemies (S)
	if data.cells.has("S"):
		for cell in data.cells["S"]:
			var cell_vec: Vector2i = cell
			var s_pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, (float(cell_vec.y) + 1.0) * 32.0)
			var sentry_inst: EnemyBase = SENTRY_SCENE.instantiate() as EnemyBase
			sentry_inst.position = s_pos
			sentry_inst.set_meta("spawn_pos", s_pos)
			enemies_node.add_child(sentry_inst)
			(result["enemies"] as Array).append(sentry_inst)

	# 6. Spawn Hunter enemies (H)
	if data.cells.has("H"):
		for cell in data.cells["H"]:
			var cell_vec: Vector2i = cell
			var h_pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, (float(cell_vec.y) + 1.0) * 32.0)
			var hunter_inst: EnemyBase = HUNTER_SCENE.instantiate() as EnemyBase
			hunter_inst.position = h_pos
			hunter_inst.set_meta("spawn_pos", h_pos)
			_setup_mover(hunter_inst, graph, bounds_per_row, cell_vec.y)
			enemies_node.add_child(hunter_inst)
			(result["enemies"] as Array).append(hunter_inst)

	# 7. Spawn Brute enemies (B)
	if data.cells.has("B"):
		for cell in data.cells["B"]:
			var cell_vec: Vector2i = cell
			var b_pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, (float(cell_vec.y) + 1.0) * 32.0)
			var brute_inst: EnemyBase = BRUTE_SCENE.instantiate() as EnemyBase
			brute_inst.position = b_pos
			brute_inst.set_meta("spawn_pos", b_pos)
			_setup_mover(brute_inst, graph, bounds_per_row, cell_vec.y)
			enemies_node.add_child(brute_inst)
			(result["enemies"] as Array).append(brute_inst)

	# 8. Stub warnings for unimplemented entities
	for ch in data.cells.keys():
		if ch != "#" and ch != "=" and ch != "P" and ch != "L" and ch != "|" and ch != "." and ch != "F" and ch != "K" and ch != "E" and ch != "D" and ch != "R" and ch != "_" and ch != ">" and ch != "<" and ch != "G" and ch != "~" and ch != "V" and ch != "v" and ch != "M" and ch != "S" and ch != "H" and ch != "B" and ch != "C" and ch != "?":
			if not _warned_stubs.has(ch):
				_warned_stubs[ch] = true
				push_warning("STUB: spawn " + ch)

	return result

static func _setup_mover(enemy: EnemyBase, graph: PlatformGraph, bounds_per_row: Dictionary, row_y: int) -> void:
	if enemy.mover == null:
		return
	enemy.mover.graph = graph
	if bounds_per_row.has(row_y):
		var b_arr: Array = bounds_per_row[row_y]
		b_arr.sort()
		var b_floats: Array[float] = []
		for b in b_arr:
			b_floats.append(float(b))
		enemy.mover.bounds = b_floats
