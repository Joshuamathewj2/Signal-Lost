extends Node

## In-game Chapter II captures (run WITH a window):
##   godot --path . res://scenes/test/capture_chapter2_flow.tscn
## Boots Main, starts the chapter, fires a scream pulse in each room and saves
## qa/shots/chapter2/flow_<room>.png, a boss-fight shot and the victory screen.

const MAIN_SCENE: PackedScene = preload("res://scenes/main/main.tscn")
const OUT_DIR: String = "res://qa/shots/chapter2"

var host: PlaygroundHost = null


func _ready() -> void:
	call_deferred(&"_run")


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(file: String) -> void:
	await _frames(3)
	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(OUT_DIR + "/" + file)
		print("[CAPTURE] ", file)


func _pulse(tier: StringName) -> void:
	var p: Node = host._room_player(host.current_room)
	var charger: Node = p.get_node_or_null("PulseCharger")
	var prof: PulseProfile = GameConfig.pulses.get(tier)
	if charger != null and prof != null:
		charger.emit_signal("pulse_released", prof, (p as Node2D).global_position)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var main: Node = MAIN_SCENE.instantiate()
	main.name = "Main"
	get_tree().root.add_child.call_deferred(main)
	await _frames(20)
	await _shot("flow_main_menu.png")
	SceneRouter.load_playground("room_01_hub")
	await _frames(60)
	host = SceneRouter.current_level_root as PlaygroundHost

	var rooms: Array = [["room_01_hub", "default"], ["room_02_corridor", "default"], ["room_04_catwalks", "default"], ["room_05_enemy_pit", "default"], ["room_03_shaft", "default"]]
	for r in rooms:
		host.load_room(r[0], r[1])
		await _frames(30)
		_pulse(&"scream")
		await _frames(18)
		await _shot("flow_%s.png" % r[0])
		for e in host.current_room.get("spawned_enemies"):
			if is_instance_valid(e):
				DamageInfo.make(99, null, DamageInfo.Faction.PLAYER).apply_to(e)
		await _frames(40)

	host.load_room("room_03_shaft", "default")
	await _frames(20)
	await _shot("flow_sanctum_door_open.png")

	host.load_room("room_06_arena", "from_enemy_pit")
	await _frames(30)
	var boss: BossLeviathan = get_tree().get_first_node_in_group(&"boss") as BossLeviathan
	var p: Node2D = host._room_player(host.current_room)
	p.global_position = boss.global_position + Vector2(-90.0, 20.0)
	await _frames(100)
	boss.start_attack("slam")
	_pulse(&"scream")
	await _frames(20)
	await _shot("flow_boss_telegraph.png")
	await _frames(40)
	await _shot("flow_boss_slam.png")
	(boss.get_node("HealthComponent") as HealthComponent).take_damage(9, Vector2.ZERO, &"test")
	await _frames(100)
	boss.start_attack("pillars")
	_pulse(&"scream")
	await _frames(55)
	await _shot("flow_boss_pillars.png")
	(boss.get_node("HealthComponent") as HealthComponent).take_damage(8, Vector2.ZERO, &"test")
	await _frames(100)
	boss.start_attack("clones")
	await _frames(70)
	_pulse(&"scream")
	await _frames(15)
	await _shot("flow_boss_clones.png")
	(boss.get_node("HealthComponent") as HealthComponent).take_damage(99, Vector2.ZERO, &"test")
	await _frames(60 * 5)
	await _shot("flow_victory.png")

	get_tree().paused = false
	get_tree().quit(0)
