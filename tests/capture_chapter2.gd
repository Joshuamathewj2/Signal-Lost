extends Node2D

## Chapter II visual capture (run WITH a window, not headless):
##   godot --path . res://scenes/test/capture_chapter2.tscn
## Spawns every manifest villain on a flat lit floor and saves
## qa/shots/chapter2/<kind>.png plus a roster panorama. Set `mode` via
## `-- attack` to capture each villain mid-telegraph next to the hero.

const LEVEL_ROOT: PackedScene = preload("res://scenes/level/level_root.tscn")
const OUT_DIR: String = "res://qa/shots/chapter2"
const KINDS: PackedStringArray = ["phantom", "warden", "executioner", "iron_monk", "blood_archer", "archer", "acoustic_hunter", "boss_leviathan"]

var level: Node2D = null
var cam: Camera2D = null


func _ready() -> void:
	call_deferred(&"_run")


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(file: String) -> void:
	await _frames(4)
	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(OUT_DIR + "/" + file)
		print("[CAPTURE] ", OUT_DIR, "/", file)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var attack_mode: bool = OS.get_cmdline_user_args().has("attack")
	level = LEVEL_ROOT.instantiate() as Node2D
	level.set("level_path", "res://levels/test_villain_gallery.txt")
	add_child(level)
	await _frames(3)
	# Fully lit so the art can be judged (the game itself is dark).
	var cm: CanvasModulate = level.get_node_or_null("CanvasModulate") as CanvasModulate
	if cm != null:
		cm.color = Color(0.9, 0.9, 0.9)
	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	var enemies_node: Node2D = level.get_node("Enemies") as Node2D
	var graph: PlatformGraph = level.get("platform_graph") as PlatformGraph

	cam = Camera2D.new()
	add_child(cam)
	cam.make_current()

	var spawned: Dictionary = {}
	var x: int = 6
	for k in KINDS:
		if not ResourceLoader.exists(String(EntitySpawner.VILLAIN_SCENES.get(k, ""))):
			continue
		var cell := Vector2i(x, 9)
		var v: Node2D = EntitySpawner.spawn_villain(k, cell, enemies_node, graph)
		if v != null:
			spawned[k] = v
			v.process_mode = Node.PROCESS_MODE_DISABLED if not attack_mode else Node.PROCESS_MODE_INHERIT
			v.get_node("Visual").process_mode = Node.PROCESS_MODE_ALWAYS
		x += 5
	if player != null:
		player.process_mode = Node.PROCESS_MODE_DISABLED
	await _frames(20)

	for k in spawned:
		var v: Node2D = spawned[k]
		if attack_mode and player != null:
			player.global_position = v.global_position + Vector2(-40.0, 0.0)
			var sm: StateMachine = v.get_node("StateMachine") as StateMachine
			var st: StVillainAttack = sm.get_node_or_null("Attack") as StVillainAttack
			if st != null:
				var atks: Array = (v.get("enemy_data") as Dictionary).get("attacks", [])
				if not atks.is_empty():
					sm.transition_to(&"Attack", {"attack": atks[0], "force": true})
			await _frames(int(30.0 * 0.5))
		cam.global_position = v.global_position + Vector2(0.0, -24.0)
		cam.zoom = Vector2(3.0, 3.0) if k != "boss_leviathan" else Vector2(2.0, 2.0)
		await _shot(("attack_" if attack_mode else "") + k + ".png")

	cam.global_position = Vector2(32.0 * 24.0, 32.0 * 8.0)
	cam.zoom = Vector2(0.95, 0.95)
	await _shot(("attack_" if attack_mode else "") + "roster.png")
	get_tree().quit(0)
