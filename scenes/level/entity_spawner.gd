class_name EntitySpawner
extends RefCounted

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const LISTENER_SCENE: PackedScene = preload("res://scenes/enemies/listener.tscn")
const SENTRY_SCENE: PackedScene = preload("res://scenes/enemies/sentry.tscn")
const HUNTER_SCENE: PackedScene = preload("res://scenes/enemies/hunter.tscn")
const BRUTE_SCENE: PackedScene = preload("res://scenes/enemies/brute.tscn")
const ASHIGARU_SCENE: PackedScene = preload("res://scenes/enemies/ashigaru.tscn")
const KENSHI_SCENE: PackedScene = preload("res://scenes/enemies/kenshi.tscn")
const YUMI_SCENE: PackedScene = preload("res://scenes/enemies/yumi.tscn")
const BOSS_SHOGUN_SCENE: PackedScene = preload("res://scenes/enemies/boss_shogun.tscn")
const SHIELD_BEARER_SCENE: PackedScene = preload("res://scenes/enemies/shield_bearer.tscn")
const BOMBER_SCENE: PackedScene = preload("res://scenes/enemies/bomber.tscn")
const DRONE_SCENE: PackedScene = preload("res://scenes/enemies/drone.tscn")
const ASSASSIN_SCENE: PackedScene = preload("res://scenes/enemies/shadow_assassin.tscn")
const CHAIN_REAPER_SCENE: PackedScene = preload("res://scenes/enemies/chain_reaper.tscn")
const JAMMER_TOWER_SCENE: PackedScene = preload("res://scenes/enemies/jammer_tower.tscn")
const BANSHEE_SCENE: PackedScene = preload("res://scenes/enemies/banshee.tscn")
const MIRROR_DUELIST_SCENE: PackedScene = preload("res://scenes/enemies/mirror_duelist.tscn")
const ONI_ENFORCER_SCENE: PackedScene = preload("res://scenes/enemies/oni_enforcer.tscn")
const TEST_FIGHTER_SCENE: PackedScene = preload("res://scenes/enemies/test_fighter.tscn")

## Chapter II manifest villains, spawned by name from room JSON (data/level.json).
const VILLAIN_SCENES: Dictionary = {
	"test_fighter": "res://scenes/enemies/test_fighter.tscn",
	"phantom": "res://scenes/enemies/phantom.tscn",
	"warden": "res://scenes/enemies/warden.tscn",
	"executioner": "res://scenes/enemies/executioner.tscn",
	"iron_monk": "res://scenes/enemies/iron_monk.tscn",
	"blood_archer": "res://scenes/enemies/blood_archer.tscn",
	"archer": "res://scenes/enemies/archer.tscn",
	"acoustic_hunter": "res://scenes/enemies/acoustic_hunter.tscn",
	"boss_leviathan": "res://scenes/enemies/boss_leviathan.tscn",
}

static var _warned_stubs: Dictionary = {}


## Spawns one named villain standing on tile `cell` (feet on the tile's floor).
static func spawn_villain(kind: String, cell: Vector2i, parent: Node2D, graph: PlatformGraph) -> Node2D:
	if not VILLAIN_SCENES.has(kind):
		push_warning("EntitySpawner: unknown villain '%s'" % kind)
		return null
	var scene: PackedScene = load(VILLAIN_SCENES[kind]) as PackedScene
	if scene == null:
		return null
	var pos := Vector2((float(cell.x) + 0.5) * 32.0, (float(cell.y) + 1.0) * 32.0)
	var inst: Node2D = scene.instantiate() as Node2D
	# Stand the body on the floor instead of embedding its capsule in it.
	var cs: CollisionShape2D = inst.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs != null and cs.shape != null:
		pos.y -= cs.position.y + cs.shape.get_rect().end.y
	inst.position = pos
	inst.set_meta("spawn_pos", pos)
	_setup_mover(inst, graph, {}, cell.y)
	parent.add_child(inst)
	return inst

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
	var player_inst: Node2D = PLAYER_SCENE.instantiate() as Node2D
	player_inst.position = p_pos
	root.add_child(player_inst)
	result["player"] = player_inst

	# 2. Spawn Interactables via InteractableSpawner
	InteractableSpawner.spawn_interactables(data, interactables_node, graph)

	# 2.5 Spawn Traps via TrapSpawner
	var traps_node: Node2D = root.get_node_or_null("Traps") as Node2D
	if traps_node == null:
		traps_node = interactables_node
	TrapSpawner.spawn_traps(data, traps_node)

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
			var listener_inst: Node2D = LISTENER_SCENE.instantiate() as Node2D
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
			var sentry_inst: Node2D = SENTRY_SCENE.instantiate() as Node2D
			sentry_inst.position = s_pos
			sentry_inst.set_meta("spawn_pos", s_pos)
			enemies_node.add_child(sentry_inst)
			(result["enemies"] as Array).append(sentry_inst)

	# 6. Spawn Hunter enemies (H)
	if data.cells.has("H"):
		for cell in data.cells["H"]:
			var cell_vec: Vector2i = cell
			var is_ladder: bool = (data.cells["H"] as Array).has(cell_vec + Vector2i(0, 1)) or (data.cells["H"] as Array).has(cell_vec - Vector2i(0, 1))
			if not is_ladder:
				var h_pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, (float(cell_vec.y) + 1.0) * 32.0)
				var hunter_inst: Node2D = HUNTER_SCENE.instantiate() as Node2D
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
			var brute_inst: Node2D = BRUTE_SCENE.instantiate() as Node2D
			brute_inst.position = b_pos
			brute_inst.set_meta("spawn_pos", b_pos)
			_setup_mover(brute_inst, graph, bounds_per_row, cell_vec.y)
			enemies_node.add_child(brute_inst)
			(result["enemies"] as Array).append(brute_inst)

	# 8. Spawn Ashigaru enemies (A)
	if data.cells.has("A"):
		for cell in data.cells["A"]:
			var cell_vec: Vector2i = cell
			var a_pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, (float(cell_vec.y) + 1.0) * 32.0)
			var ashigaru_inst: Node2D = ASHIGARU_SCENE.instantiate() as Node2D
			ashigaru_inst.position = a_pos
			ashigaru_inst.set_meta("spawn_pos", a_pos)
			_setup_mover(ashigaru_inst, graph, bounds_per_row, cell_vec.y)
			enemies_node.add_child(ashigaru_inst)
			(result["enemies"] as Array).append(ashigaru_inst)

	# 9. Spawn Kenshi duelist enemies (k)
	if data.cells.has("k"):
		for cell in data.cells["k"]:
			var cell_vec: Vector2i = cell
			var k_pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, (float(cell_vec.y) + 1.0) * 32.0)
			var kenshi_inst: Node2D = KENSHI_SCENE.instantiate() as Node2D
			kenshi_inst.position = k_pos
			kenshi_inst.set_meta("spawn_pos", k_pos)
			_setup_mover(kenshi_inst, graph, bounds_per_row, cell_vec.y)
			enemies_node.add_child(kenshi_inst)
			(result["enemies"] as Array).append(kenshi_inst)

	# 10. Spawn Yumi archer enemies (Y)
	if data.cells.has("Y"):
		for cell in data.cells["Y"]:
			var cell_vec: Vector2i = cell
			var y_pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, (float(cell_vec.y) + 1.0) * 32.0)
			var yumi_inst: Node2D = YUMI_SCENE.instantiate() as Node2D
			yumi_inst.position = y_pos
			yumi_inst.set_meta("spawn_pos", y_pos)
			_setup_mover(yumi_inst, graph, bounds_per_row, cell_vec.y)
			enemies_node.add_child(yumi_inst)
			(result["enemies"] as Array).append(yumi_inst)

	# 11. Spawn Boss Shogun (W)
	if data.cells.has("W"):
		for cell in data.cells["W"]:
			var cell_vec: Vector2i = cell
			var w_pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, (float(cell_vec.y) + 1.0) * 32.0)
			var shogun_inst: Node2D = BOSS_SHOGUN_SCENE.instantiate() as Node2D
			shogun_inst.position = w_pos
			shogun_inst.set_meta("spawn_pos", w_pos)
			enemies_node.add_child(shogun_inst)
			(result["enemies"] as Array).append(shogun_inst)

	# 12. Spawn Shield Bearer (U)
	if data.cells.has("U"):
		for cell in data.cells["U"]:
			var cell_vec: Vector2i = cell
			var pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, (float(cell_vec.y) + 1.0) * 32.0)
			var inst: Node2D = SHIELD_BEARER_SCENE.instantiate() as Node2D
			inst.position = pos
			inst.set_meta("spawn_pos", pos)
			_setup_mover(inst, graph, bounds_per_row, cell_vec.y)
			enemies_node.add_child(inst)
			(result["enemies"] as Array).append(inst)

	# 13. Spawn Bomber (o)
	if data.cells.has("o"):
		for cell in data.cells["o"]:
			var cell_vec: Vector2i = cell
			var pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, (float(cell_vec.y) + 1.0) * 32.0)
			var inst: Node2D = BOMBER_SCENE.instantiate() as Node2D
			inst.position = pos
			inst.set_meta("spawn_pos", pos)
			_setup_mover(inst, graph, bounds_per_row, cell_vec.y)
			enemies_node.add_child(inst)
			(result["enemies"] as Array).append(inst)

	# 14. Spawn Drone (d)
	if data.cells.has("d"):
		for cell in data.cells["d"]:
			var cell_vec: Vector2i = cell
			var pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, (float(cell_vec.y) + 1.0) * 32.0)
			var inst: Node2D = DRONE_SCENE.instantiate() as Node2D
			inst.position = pos
			inst.set_meta("spawn_pos", pos)
			enemies_node.add_child(inst)
			(result["enemies"] as Array).append(inst)

	# 15. Spawn Shadow Assassin (a)
	if data.cells.has("a"):
		for cell in data.cells["a"]:
			var cell_vec: Vector2i = cell
			var pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, (float(cell_vec.y) + 1.0) * 32.0)
			var inst: Node2D = ASSASSIN_SCENE.instantiate() as Node2D
			inst.position = pos
			inst.set_meta("spawn_pos", pos)
			_setup_mover(inst, graph, bounds_per_row, cell_vec.y)
			enemies_node.add_child(inst)
			(result["enemies"] as Array).append(inst)

	# 16. Spawn Chain Reaper (c)
	if data.cells.has("c"):
		for cell in data.cells["c"]:
			var cell_vec: Vector2i = cell
			var pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, (float(cell_vec.y) + 1.0) * 32.0)
			var inst: Node2D = CHAIN_REAPER_SCENE.instantiate() as Node2D
			inst.position = pos
			inst.set_meta("spawn_pos", pos)
			_setup_mover(inst, graph, bounds_per_row, cell_vec.y)
			enemies_node.add_child(inst)
			(result["enemies"] as Array).append(inst)

	# 17. Spawn Jammer Tower (j)
	if data.cells.has("j"):
		for cell in data.cells["j"]:
			var cell_vec: Vector2i = cell
			var pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, (float(cell_vec.y) + 1.0) * 32.0)
			var inst: Node2D = JAMMER_TOWER_SCENE.instantiate() as Node2D
			inst.position = pos
			inst.set_meta("spawn_pos", pos)
			enemies_node.add_child(inst)
			(result["enemies"] as Array).append(inst)

	# 18. Spawn Banshee (w)
	if data.cells.has("w"):
		for cell in data.cells["w"]:
			var cell_vec: Vector2i = cell
			var pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, (float(cell_vec.y) + 1.0) * 32.0)
			var inst: Node2D = BANSHEE_SCENE.instantiate() as Node2D
			inst.position = pos
			inst.set_meta("spawn_pos", pos)
			enemies_node.add_child(inst)
			(result["enemies"] as Array).append(inst)

	# 19. Spawn Mirror Duelist (m)
	if data.cells.has("m"):
		for cell in data.cells["m"]:
			var cell_vec: Vector2i = cell
			var pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, (float(cell_vec.y) + 1.0) * 32.0)
			var inst: Node2D = MIRROR_DUELIST_SCENE.instantiate() as Node2D
			inst.position = pos
			inst.set_meta("spawn_pos", pos)
			_setup_mover(inst, graph, bounds_per_row, cell_vec.y)
			enemies_node.add_child(inst)
			(result["enemies"] as Array).append(inst)

	# 20. Spawn Oni Enforcer (O)
	if data.cells.has("O"):
		for cell in data.cells["O"]:
			var cell_vec: Vector2i = cell
			var pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, (float(cell_vec.y) + 1.0) * 32.0)
			var inst: Node2D = ONI_ENFORCER_SCENE.instantiate() as Node2D
			inst.position = pos
			inst.set_meta("spawn_pos", pos)
			_setup_mover(inst, graph, bounds_per_row, cell_vec.y)
			enemies_node.add_child(inst)
			(result["enemies"] as Array).append(inst)

	# 20.5 Spawn Test Fighter (T)
	if data.cells.has("T"):
		for cell in data.cells["T"]:
			var cell_vec: Vector2i = cell
			var pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, (float(cell_vec.y) + 1.0) * 32.0)
			var inst: Node2D = TEST_FIGHTER_SCENE.instantiate() as Node2D
			inst.position = pos
			inst.set_meta("spawn_pos", pos)
			_setup_mover(inst, graph, bounds_per_row, cell_vec.y)
			enemies_node.add_child(inst)
			(result["enemies"] as Array).append(inst)

	# 21. Stub warnings for unimplemented entities
	var known_chars: String = "#=PL.FKEDR_><G~VvMSHBAkYC?WUodacjwmOT^*)}!\"@Q%$"
	for ch in data.cells.keys():
		if known_chars.find(ch) == -1:
			if not _warned_stubs.has(ch):
				_warned_stubs[ch] = true
				push_warning("STUB: spawn " + ch)

	return result

static func _setup_mover(enemy: Node2D, graph: PlatformGraph, bounds_per_row: Dictionary, row_y: int) -> void:
	var mover = enemy.get("mover")
	if mover == null:
		return
	mover.graph = graph
	if bounds_per_row.has(row_y):
		var b_arr: Array = bounds_per_row[row_y]
		b_arr.sort()
		var b_floats: Array[float] = []
		for b in b_arr:
			b_floats.append(float(b))
		enemy.mover.bounds = b_floats
