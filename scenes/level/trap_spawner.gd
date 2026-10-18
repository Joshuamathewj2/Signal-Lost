class_name TrapSpawner
extends RefCounted

## TrapSpawner
## Instantiates and positions traps from level data grid representations.
## Ensures data-driven TrapData assignment, acoustic registration, and level parentage.

const FLOOR_SPIKES_SCENE: PackedScene = preload("res://scenes/traps/floor_spikes.tscn")
const CEILING_SPIKES_SCENE: PackedScene = preload("res://scenes/traps/ceiling_spikes.tscn")
const SWINGING_BLADE_SCENE: PackedScene = preload("res://scenes/traps/swinging_blade.tscn")
const WALL_BLADE_SCENE: PackedScene = preload("res://scenes/traps/wall_blade.tscn")
const ARROW_TRAP_SCENE: PackedScene = preload("res://scenes/traps/arrow_trap.tscn")
const SPEAR_LAUNCHER_SCENE: PackedScene = preload("res://scenes/traps/spear_launcher.tscn")
const FALLING_ROCK_SCENE: PackedScene = preload("res://scenes/traps/falling_rock.tscn")
const ROLLING_BOULDER_SCENE: PackedScene = preload("res://scenes/traps/rolling_boulder.tscn")
const GUILLOTINE_SCENE: PackedScene = preload("res://scenes/traps/guillotine.tscn")
const FIRE_TRAP_SCENE: PackedScene = preload("res://scenes/traps/fire_trap.tscn")

static func spawn_traps(data: LevelData, parent: Node2D) -> Array[Node2D]:
	var spawned: Array[Node2D] = []
	if data == null or parent == null:
		return spawned

	# 1. Floor Spikes (^)
	if data.cells.has("^"):
		for cell in data.cells["^"]:
			var cell_vec: Vector2i = cell
			var pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, (float(cell_vec.y) + 1.0) * 32.0)
			var inst: Node2D = FLOOR_SPIKES_SCENE.instantiate() as Node2D
			inst.position = pos
			parent.add_child(inst)
			spawned.append(inst)

	# 2. Ceiling Spikes (*)
	if data.cells.has("*"):
		for cell in data.cells["*"]:
			var cell_vec: Vector2i = cell
			var pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, float(cell_vec.y) * 32.0)
			var inst: Node2D = CEILING_SPIKES_SCENE.instantiate() as Node2D
			inst.position = pos
			parent.add_child(inst)
			spawned.append(inst)

	# 3. Swinging Blade ())
	if data.cells.has(")"):
		for cell in data.cells[")"]:
			var cell_vec: Vector2i = cell
			var pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, float(cell_vec.y) * 32.0)
			var inst: Node2D = SWINGING_BLADE_SCENE.instantiate() as Node2D
			inst.position = pos
			parent.add_child(inst)
			spawned.append(inst)

	# 4. Wall Blade (})
	if data.cells.has("}"):
		for cell in data.cells["}"]:
			var cell_vec: Vector2i = cell
			var pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, (float(cell_vec.y) + 0.5) * 32.0)
			var inst: Node2D = WALL_BLADE_SCENE.instantiate() as Node2D
			inst.position = pos
			# Detect wall side: if wall on left, face right (1), else face left (-1)
			var left_solid: bool = cell_vec.x > 0 and data.grid[cell_vec.y][cell_vec.x - 1] == "#"
			inst.set("facing_dir", 1 if left_solid else -1)
			parent.add_child(inst)
			spawned.append(inst)

	# 5. Arrow Trap (")
	if data.cells.has("\""):
		for cell in data.cells["\""]:
			var cell_vec: Vector2i = cell
			var pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, (float(cell_vec.y) + 0.5) * 32.0)
			var inst: Node2D = ARROW_TRAP_SCENE.instantiate() as Node2D
			inst.position = pos
			var left_solid: bool = cell_vec.x > 0 and data.grid[cell_vec.y][cell_vec.x - 1] == "#"
			inst.set("firing_direction", Vector2.RIGHT if left_solid else Vector2.LEFT)
			parent.add_child(inst)
			spawned.append(inst)

	# 6. Spear Launcher (!)
	if data.cells.has("!"):
		for cell in data.cells["!"]:
			var cell_vec: Vector2i = cell
			var pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, (float(cell_vec.y) + 1.0) * 32.0)
			var inst: Node2D = SPEAR_LAUNCHER_SCENE.instantiate() as Node2D
			inst.position = pos
			parent.add_child(inst)
			spawned.append(inst)

	# 7. Falling Rock (@)
	if data.cells.has("@"):
		for cell in data.cells["@"]:
			var cell_vec: Vector2i = cell
			var pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, float(cell_vec.y) * 32.0)
			var inst: Node2D = FALLING_ROCK_SCENE.instantiate() as Node2D
			inst.position = pos
			parent.add_child(inst)
			spawned.append(inst)

	# 8. Rolling Boulder (Q)
	if data.cells.has("Q"):
		for cell in data.cells["Q"]:
			var cell_vec: Vector2i = cell
			var pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, (float(cell_vec.y) + 0.5) * 32.0)
			var inst: Node2D = ROLLING_BOULDER_SCENE.instantiate() as Node2D
			inst.position = pos
			parent.add_child(inst)
			spawned.append(inst)

	# 9. Guillotine (%)
	if data.cells.has("%"):
		for cell in data.cells["%"]:
			var cell_vec: Vector2i = cell
			var pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, float(cell_vec.y) * 32.0)
			var inst: Node2D = GUILLOTINE_SCENE.instantiate() as Node2D
			inst.position = pos
			parent.add_child(inst)
			spawned.append(inst)

	# 10. Fire Trap ($)
	if data.cells.has("$"):
		for cell in data.cells["$"]:
			var cell_vec: Vector2i = cell
			var pos := Vector2((float(cell_vec.x) + 0.5) * 32.0, (float(cell_vec.y) + 1.0) * 32.0)
			var inst: Node2D = FIRE_TRAP_SCENE.instantiate() as Node2D
			inst.position = pos
			parent.add_child(inst)
			spawned.append(inst)

	return spawned
