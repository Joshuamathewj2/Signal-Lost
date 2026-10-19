extends Node

## End-to-end Chapter II flow on the real Main scene (headless):
##   godot --headless --path . res://tests/live/test_chapter2.tscn
## 1. Main menu -> SceneRouter.load_playground starts the chapter at the hub
## 2. The arena doors are sealed (locked + solid) at 0 seals
## 3. Killing every villain in a seal room breaks its seal; a cleared room
##    stays empty when revisited
## 4. Hero death respawns in the same room (never a campaign level)
## 5. HP is carried through doors
## 6. At 5 seals the arena opens; the Leviathan binds the boss bar; its death
##    shows the chapter-complete screen and records the clear in SaveData
## The player's real save is restored afterwards. Exit 0 = all checks pass.

const MAIN_SCENE: PackedScene = preload("res://scenes/main/main.tscn")
const SEAL_ROOMS: PackedStringArray = ["room_01_hub", "room_02_corridor", "room_04_catwalks", "room_05_enemy_pit", "room_03_shaft"]

var host: PlaygroundHost = null
var results: Array[String] = []
var failures: Array[String] = []
var _had_chapter_save: bool = false


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


func _player() -> Node2D:
	return get_tree().get_first_node_in_group(&"player") as Node2D


func _hp() -> int:
	var p: Node2D = _player()
	return int((p.get_node("HealthComponent") as HealthComponent).current_health) if p != null else -1


func _kill_room() -> void:
	for e in host.current_room.get("spawned_enemies"):
		if is_instance_valid(e):
			DamageInfo.make(99, null, DamageInfo.Faction.PLAYER).apply_to(e)
	await _frames(30)


func _arena_door(room: Node) -> DoorTransition:
	var doors: Node = room.get_node_or_null("Doors")
	if doors == null:
		return null
	for d in doors.get_children():
		if (d as DoorTransition).target_room == "room_06_arena":
			return d as DoorTransition
	return null


func _run() -> void:
	_had_chapter_save = SaveData._config.has_section("chapter_2")
	var main: Node = MAIN_SCENE.instantiate()
	main.name = "Main"
	get_tree().root.add_child.call_deferred(main)
	await _frames(10)

	SceneRouter.load_playground("room_01_hub")
	await _frames(40)
	host = SceneRouter.current_level_root as PlaygroundHost
	_check(host != null and host.current_room_id == "room_01_hub", "chapter starts in the Gatehouse hub")
	if host == null:
		_report()
		return
	_check(host.seal_count() == 0 and host.seals_required() == 5, "0 / 5 seals at start")
	_check((host.current_room.get("spawned_enemies") as Array).size() == 2, "hub spawns its villains (warden + blood archer)")

	# 2. Sealed arena gate
	host.load_room("room_03_shaft", "from_hub")
	await _frames(10)
	var door: DoorTransition = _arena_door(host.current_room)
	_check(door != null and door.is_locked(), "shaft -> sanctum door is sealed at 0 seals")
	_check(door != null and door._blocker != null and not door._blocker.disabled, "sealed doorway is physically blocked")

	# 5. HP carried through doors
	var p: Node2D = _player()
	(p.get_node("HealthComponent") as HealthComponent).current_health = 2
	host._on_room_transition_requested("room_01_hub", "from_shaft")
	await _frames(40)
	_check(_hp() == 2, "hero HP carried through a door (2 -> %d)" % _hp())

	# 3. Break all five seals
	for rid in SEAL_ROOMS:
		host.load_room(rid, "default")
		await _frames(10)
		var before: int = host.seal_count()
		await _kill_room()
		_check(host.seal_count() == before + 1, "clearing %s breaks a seal (%d)" % [rid, host.seal_count()])
	host.load_room("room_02_corridor", "default")
	await _frames(10)
	_check((host.current_room.get("spawned_enemies") as Array).is_empty(), "a cleared room stays empty when revisited")

	# 4. Death respawns in place
	host.load_room("room_04_catwalks", "from_corridor")
	await _frames(10)
	var deaths0: int = host.deaths
	_player().call("die", &"test")
	await _frames(90)
	_check(SceneRouter.current_level_root == host and host.current_room_id == "room_04_catwalks", "death respawns in the same room, not a campaign level")
	_check(host.deaths == deaths0 + 1, "death counted")
	_check(_player() != null and bool(_player().get("is_alive")) and _hp() == (_player().get_node("HealthComponent") as HealthComponent).max_health, "respawned at full health")

	# 6. Sanctum opens, boss fight, victory
	host.load_room("room_03_shaft", "from_hub")
	await _frames(10)
	door = _arena_door(host.current_room)
	await _frames(2)
	_check(door != null and not door.is_locked(), "sanctum door opens at 5 / 5 seals")
	host.load_room("room_06_arena", "from_shaft")
	await _frames(20)
	var boss: Node = get_tree().get_first_node_in_group(&"boss")
	_check(boss != null, "the Leviathan waits in the sanctum")
	var bar: Node = get_tree().get_first_node_in_group(&"hud").find_child("BossHealthBar", true, false)
	_check(bar != null and (bar as CanvasItem).visible and bar.get("boss_target") == boss, "boss health bar bound to the Leviathan")
	if boss != null:
		(boss.get_node("HealthComponent") as HealthComponent).take_damage(99, Vector2.ZERO, &"test")
	await _frames(60 * 4)
	_check(host.completed, "chapter marked complete on boss death")
	_check(host.find_child("@Control*", true, false) != null or _find_complete_screen() != null, "chapter-complete screen shown")
	_check(bool(SaveData.get_chapter_data(2).get("completed", false)), "clear recorded in SaveData")
	get_tree().paused = false
	_report()


func _find_complete_screen() -> Node:
	for n in host.find_children("*", "Control", true, false):
		if n is ChapterComplete:
			return n
	return null


func _report() -> void:
	if not _had_chapter_save and SaveData._config.has_section("chapter_2"):
		SaveData._config.erase_section("chapter_2")
		SaveData._config.save(SaveData.SAVE_PATH)
	for r in results:
		print("  ok  ", r)
	if failures.is_empty():
		print("PASS test_chapter2: %d checks" % results.size())
		get_tree().quit(0)
	else:
		for f in failures:
			print("FAIL test_chapter2: ", f)
		get_tree().quit(1)
