class_name InteractableSpawner
extends RefCounted

const FRAGMENT_SCENE: PackedScene = preload("res://scenes/interactables/fragment.tscn")
const KEYCARD_SCENE: PackedScene = preload("res://scenes/interactables/keycard.tscn")
const EXIT_SCENE: PackedScene = preload("res://scenes/interactables/exit_terminal.tscn")
const DOOR_SCENE: PackedScene = preload("res://scenes/interactables/door.tscn")
const PLATE_SCENE: PackedScene = preload("res://scenes/interactables/pressure_plate.tscn")
const ONE_WAY_DOOR_SCENE: PackedScene = preload("res://scenes/interactables/one_way_door.tscn")
const GLASS_SCENE: PackedScene = preload("res://scenes/interactables/glass_floor.tscn")
const LANTERN_SCENE: PackedScene = preload("res://scenes/interactables/lantern.tscn")
const VENT_SCENE: PackedScene = preload("res://scenes/interactables/vent.tscn")

static func spawn_interactables(data: LevelData, parent: Node2D, graph: PlatformGraph) -> void:
	# 1. Exit Terminal
	var e_cell: Vector2i = data.exit_cell
	var e_pos := Vector2((float(e_cell.x) + 0.5) * 32.0, (float(e_cell.y) + 1.0) * 32.0)
	var exit_inst: ExitTerminal = EXIT_SCENE.instantiate() as ExitTerminal
	exit_inst.position = e_pos
	exit_inst.cell = e_cell
	parent.add_child(exit_inst)

	# 2. Fragments
	if data.cells.has("F"):
		var frag_id: int = 0
		for cell in data.cells["F"]:
			var cell_vec: Vector2i = cell
			var f_pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, (float(cell_vec.y) + 0.5) * 32.0)
			var frag_inst: Fragment = FRAGMENT_SCENE.instantiate() as Fragment
			frag_inst.position = f_pos
			frag_inst.cell = cell_vec
			frag_inst.fragment_id = frag_id
			frag_id += 1
			parent.add_child(frag_inst)

	# 3. Keycards
	if data.cells.has("K"):
		for cell in data.cells["K"]:
			var cell_vec: Vector2i = cell
			var k_pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, (float(cell_vec.y) + 0.5) * 32.0)
			var key_inst: Keycard = KEYCARD_SCENE.instantiate() as Keycard
			key_inst.position = k_pos
			key_inst.cell = cell_vec
			parent.add_child(key_inst)

	# 4. Key Doors (D) and Plate Doors (R)
	_spawn_doors(data, "D", "KEY", parent, graph)
	_spawn_doors(data, "R", "PLATE", parent, graph)

	# 5. One-Way Doors (>, <)
	_spawn_one_way_doors(data, ">", 1, parent)
	_spawn_one_way_doors(data, "<", -1, parent)

	# 6. Pressure Plates (_)
	if data.cells.has("_"):
		for cell in data.cells["_"]:
			var cell_vec: Vector2i = cell
			var p_pos_plate := Vector2((float(cell_vec.x) + 0.5) * 32.0, (float(cell_vec.y) + 1.0) * 32.0)
			var plate_inst: PressurePlate = PLATE_SCENE.instantiate() as PressurePlate
			plate_inst.position = p_pos_plate
			plate_inst.cell = cell_vec
			parent.add_child(plate_inst)

	# 7. Glass Floors (G)
	if data.cells.has("G"):
		for cell in data.cells["G"]:
			var cell_vec: Vector2i = cell
			var g_pos := Vector2(float(cell_vec.x) * 32.0, float(cell_vec.y) * 32.0)
			var glass_inst: GlassFloor = GLASS_SCENE.instantiate() as GlassFloor
			glass_inst.position = g_pos
			glass_inst.cell = cell_vec
			glass_inst.graph_ref = graph
			parent.add_child(glass_inst)

	# 8. Lanterns (~)
	if data.cells.has("~"):
		for cell in data.cells["~"]:
			var cell_vec: Vector2i = cell
			var lantern_pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, float(cell_vec.y) * 32.0)
			var lantern_inst: Lantern = LANTERN_SCENE.instantiate() as Lantern
			lantern_inst.position = lantern_pos
			lantern_inst.cell = cell_vec
			parent.add_child(lantern_inst)

	# 9. Vents (V, v, M)
	_spawn_vents(data, parent)

static func _spawn_doors(data: LevelData, key: String, mode: String, parent: Node2D, graph: PlatformGraph) -> void:
	if not data.cells.has(key):
		return
	var processed: Dictionary = {}
	for cell in data.cells[key]:
		var cell_vec: Vector2i = cell
		if processed.has(cell_vec):
			continue
		var lower_cell: Vector2i = cell_vec + Vector2i(0, 1)
		if (data.cells[key] as Array).has(lower_cell):
			processed[cell_vec] = true
			processed[lower_cell] = true
			var d_pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, float(cell_vec.y) * 32.0)
			var door_inst: Door = DOOR_SCENE.instantiate() as Door
			door_inst.mode = mode
			door_inst.cell = cell_vec
			door_inst.position = d_pos
			door_inst.graph_ref = graph
			parent.add_child(door_inst)

static func _spawn_one_way_doors(data: LevelData, key: String, dir: int, parent: Node2D) -> void:
	if not data.cells.has(key):
		return
	var processed: Dictionary = {}
	for cell in data.cells[key]:
		var cell_vec: Vector2i = cell
		if processed.has(cell_vec):
			continue
		var lower_cell: Vector2i = cell_vec + Vector2i(0, 1)
		if (data.cells[key] as Array).has(lower_cell):
			processed[cell_vec] = true
			processed[lower_cell] = true
			var owd_pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, float(cell_vec.y) * 32.0)
			var owd_inst: OneWayDoor = ONE_WAY_DOOR_SCENE.instantiate() as OneWayDoor
			owd_inst.dir = dir
			owd_inst.cell = cell_vec
			owd_inst.position = owd_pos
			parent.add_child(owd_inst)

static func _spawn_vents(data: LevelData, parent: Node2D) -> void:
	var spawned_intakes: Array[Vent] = []
	var spawned_outlets: Array[Vent] = []

	if data.cells.has("V"):
		var v_cells: Array = data.cells["V"].duplicate()
		v_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return (a.y * data.width + a.x) < (b.y * data.width + b.x)
		)
		for cell in v_cells:
			var cell_vec: Vector2i = cell
			var vent_inst: Vent = VENT_SCENE.instantiate() as Vent
			vent_inst.mode = "INTAKE"
			vent_inst.cell = cell_vec
			vent_inst.position = Vector2(float(cell_vec.x) * 32.0, float(cell_vec.y) * 32.0)
			parent.add_child(vent_inst)
			spawned_intakes.append(vent_inst)

	if data.cells.has("v"):
		var v_cells: Array = data.cells["v"].duplicate()
		v_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return (a.y * data.width + a.x) < (b.y * data.width + b.x)
		)
		for cell in v_cells:
			var cell_vec: Vector2i = cell
			var vent_inst: Vent = VENT_SCENE.instantiate() as Vent
			vent_inst.mode = "OUTLET"
			vent_inst.cell = cell_vec
			vent_inst.position = Vector2(float(cell_vec.x) * 32.0, float(cell_vec.y) * 32.0)
			parent.add_child(vent_inst)
			spawned_outlets.append(vent_inst)

	var pair_count: int = mini(spawned_intakes.size(), spawned_outlets.size())
	for i in range(pair_count):
		spawned_intakes[i].outlet = spawned_outlets[i]

	if data.cells.has("M"):
		for cell in data.cells["M"]:
			var cell_vec: Vector2i = cell
			var vent_inst: Vent = VENT_SCENE.instantiate() as Vent
			vent_inst.mode = "MUTE"
			vent_inst.cell = cell_vec
			vent_inst.position = Vector2(float(cell_vec.x) * 32.0, float(cell_vec.y) * 32.0)
			parent.add_child(vent_inst)
