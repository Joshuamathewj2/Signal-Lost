class_name EntitySpawner
extends RefCounted

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const LISTENER_SCENE: PackedScene = preload("res://scenes/enemies/listener.tscn")
const FRAGMENT_SCENE: PackedScene = preload("res://scenes/interactables/fragment.tscn")
const KEYCARD_SCENE: PackedScene = preload("res://scenes/interactables/keycard.tscn")
const EXIT_SCENE: PackedScene = preload("res://scenes/interactables/exit_terminal.tscn")

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

	# 2. Spawn Exit Terminal
	var e_cell: Vector2i = data.exit_cell
	var e_pos := Vector2((float(e_cell.x) + 0.5) * 32.0, (float(e_cell.y) + 1.0) * 32.0)
	var exit_inst: ExitTerminal = EXIT_SCENE.instantiate() as ExitTerminal
	exit_inst.position = e_pos
	exit_inst.cell = e_cell
	interactables_node.add_child(exit_inst)

	# 3. Spawn Fragments
	if data.cells.has("F"):
		var frag_id: int = 0
		for cell in data.cells["F"]:
			var f_pos := Vector2((float(cell.x) + 0.5) * 32.0, (float(cell.y) + 0.5) * 32.0)
			var frag_inst: Fragment = FRAGMENT_SCENE.instantiate() as Fragment
			frag_inst.position = f_pos
			frag_inst.cell = cell
			frag_inst.fragment_id = frag_id
			frag_id += 1
			interactables_node.add_child(frag_inst)

	# 4. Spawn Keycards
	if data.cells.has("K"):
		for cell in data.cells["K"]:
			var k_pos := Vector2((float(cell.x) + 0.5) * 32.0, (float(cell.y) + 0.5) * 32.0)
			var key_inst: Keycard = KEYCARD_SCENE.instantiate() as Keycard
			key_inst.position = k_pos
			key_inst.cell = cell
			interactables_node.add_child(key_inst)

	# 5. Extract bounds for enemies
	var bounds_per_row: Dictionary = {}
	if data.cells.has("|"):
		for bound_cell in data.cells["|"]:
			var r: int = bound_cell.y
			if not bounds_per_row.has(r):
				bounds_per_row[r] = []
			(bounds_per_row[r] as Array).append(float(bound_cell.x * 32))

	# 6. Spawn Listener enemies
	if data.cells.has("L"):
		for cell in data.cells["L"]:
			var l_pos := Vector2((float(cell.x) + 0.5) * 32.0, (float(cell.y) + 1.0) * 32.0)
			var listener_inst: EnemyBase = LISTENER_SCENE.instantiate() as EnemyBase
			listener_inst.position = l_pos
			listener_inst.set_meta("spawn_pos", l_pos)
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

	# 7. Stub warnings for unimplemented entities
	for ch in data.cells.keys():
		if ch != "#" and ch != "=" and ch != "P" and ch != "L" and ch != "|" and ch != "." and ch != "F" and ch != "K" and ch != "E":
			if not _warned_stubs.has(ch):
				_warned_stubs[ch] = true
				push_warning("STUB: spawn " + ch)

	return result
