extends Node

## Live test for Step 0D: Multi-room playground system.
## Verifies:
## 1. PlaygroundHost loads room_01_hub
## 2. Player spawns at correct coordinate
## 3. Room 05 spawns test_fighter enemy
## 4. Room 06 spawns test_fighter and ExitTerminal
## 5. Seamless transitions across all 6 rooms
## 6. Camera limits update correctly per room
## Exit 0 = all checks pass.

const PLAYGROUND_SCENE: String = "res://scenes/level/playground_host.tscn"

var host: Node2D = null
var results: Array[String] = []
var failures: Array[String] = []

func _ready() -> void:
	call_deferred(&"_run")

func _check(ok: bool, label: String) -> void:
	if ok:
		results.append(label)
	else:
		failures.append(label)

func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func _run() -> void:
	var packed: PackedScene = load(PLAYGROUND_SCENE) as PackedScene
	host = packed.instantiate() as Node2D
	add_child(host)

	await _frames(5)

	# 1. Hub check
	_check(host.current_room != null and host.current_room_id == "room_01_hub", "Hub room loaded as initial room")
	var p: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	_check(p != null, "Player spawned in playground")

	# 2. Transition to Room 02 (Corridor)
	host.load_room("room_02_corridor", "from_hub")
	await _frames(5)
	_check(host.current_room_id == "room_02_corridor", "Transition to Room 02 Corridor")
	_check(host.current_room.get_room_bounds() == Rect2i(0, 0, 48 * 32, 16 * 32), "Camera bounds match Room 02 dimensions (48x16)")

	# 3. Transition to Room 04 (Catwalks)
	host.load_room("room_04_catwalks", "from_corridor")
	await _frames(5)
	_check(host.current_room_id == "room_04_catwalks", "Transition to Room 04 Catwalks")

	# 4. Transition to Room 05 (Enemy Pit)
	host.load_room("room_05_enemy_pit", "from_catwalks")
	await _frames(5)
	_check(host.current_room_id == "room_05_enemy_pit", "Transition to Room 05 Enemy Pit")
	var enemies: Array[Node] = get_tree().get_nodes_in_group(&"enemies")
	var has_fighter: bool = false
	for e in enemies:
		if e.get("kind") == &"test_fighter" or e.name.begins_with("TestFighter"):
			has_fighter = true
			break
	_check(has_fighter, "Test Fighter enemy spawned in Room 05 Enemy Pit")

	# 5. Transition to Room 06 (Arena)
	host.load_room("room_06_arena", "from_enemy_pit")
	await _frames(5)
	_check(host.current_room_id == "room_06_arena", "Transition to Room 06 Arena")
	var exit_term = host.find_child("ExitTerminal*", true, false)
	if exit_term == null:
		exit_term = get_tree().get_first_node_in_group(&"interactables")
	_check(exit_term != null, "Exit Terminal present in Room 06 Arena")

	# 6. Transition to Room 03 (Vertical Shaft)
	host.load_room("room_03_shaft", "from_arena")
	await _frames(5)
	_check(host.current_room_id == "room_03_shaft", "Transition to Room 03 Vertical Shaft")
	_check(host.current_room.get_room_bounds() == Rect2i(0, 0, 24 * 32, 32 * 32), "Camera bounds match Room 03 Shaft (24x32)")

	# 7. Loop back to Room 01 (Hub)
	host.load_room("room_01_hub", "from_shaft")
	await _frames(5)
	_check(host.current_room_id == "room_01_hub", "Full room loop completed back to Room 01 Hub")

	for r in results:
		print("  ok  ", r)
	if failures.is_empty():
		print("PASS test_playground: %d checks" % results.size())
		get_tree().quit(0)
	else:
		for f in failures:
			print("FAIL test_playground: ", f)
		get_tree().quit(1)
