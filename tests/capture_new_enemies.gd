extends Node2D

const ARTIFACT_DIR: String = "C:/Users/Administrator.TNEB/.gemini/antigravity-ide/brain/7ae4db4a-6570-4148-9cb4-b50c5b833978"

func _ready() -> void:
	call_deferred(&"_run")

func _run() -> void:
	var arena_scene: PackedScene = load("res://scenes/test/combat_test_arena.tscn")
	var arena: Node2D = arena_scene.instantiate() as Node2D
	add_child(arena)

	var cam: Camera2D = arena.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		cam = Camera2D.new()
		arena.add_child(cam)

	# Ensure directory exists
	DirAccess.make_dir_recursive_absolute("res://qa/shots")

	for i in range(15):
		await get_tree().process_frame

	# List of enemies to focus and capture
	var captures := [
		{"node": "ShieldBearer", "file": "enemy_shield_bearer.png", "zoom": Vector2(2.5, 2.5), "offset": Vector2(0, -10)},
		{"node": "Bomber", "file": "enemy_bomber.png", "zoom": Vector2(2.5, 2.5), "offset": Vector2(0, -10)},
		{"node": "Drone", "file": "enemy_drone.png", "zoom": Vector2(2.5, 2.5), "offset": Vector2(0, 0)},
		{"node": "ShadowAssassin", "file": "enemy_shadow_assassin.png", "zoom": Vector2(2.5, 2.5), "offset": Vector2(0, -10)},
		{"node": "ChainReaper", "file": "enemy_chain_reaper.png", "zoom": Vector2(2.5, 2.5), "offset": Vector2(0, -10)},
		{"node": "JammerTower", "file": "enemy_jammer_tower.png", "zoom": Vector2(2.0, 2.0), "offset": Vector2(0, -20)},
		{"node": "Banshee", "file": "enemy_banshee.png", "zoom": Vector2(2.5, 2.5), "offset": Vector2(0, 0)},
		{"node": "MirrorDuelist", "file": "enemy_mirror_duelist.png", "zoom": Vector2(2.5, 2.5), "offset": Vector2(0, -10)},
		{"node": "OniEnforcer", "file": "enemy_oni_enforcer.png", "zoom": Vector2(2.2, 2.2), "offset": Vector2(0, -15)}
	]

	for item in captures:
		var target: Node2D = arena.get_node_or_null(str(item["node"])) as Node2D
		if target != null:
			cam.global_position = target.global_position + (item["offset"] as Vector2)
			cam.zoom = item["zoom"] as Vector2

			if target.has_method("reveal"):
				target.call("reveal", 5.0)

			for f in range(6):
				await get_tree().process_frame

			var img: Image = get_viewport().get_texture().get_image()
			if img != null:
				var qa_path := "res://qa/shots/" + str(item["file"])
				var art_path := ARTIFACT_DIR + "/" + str(item["file"])
				img.save_png(qa_path)
				img.save_png(art_path)
				print("[CAPTURE] Saved " + qa_path + " and " + art_path)

	# Finally capture panoramic view of entire arena roster
	cam.global_position = Vector2(1100, 140)
	cam.zoom = Vector2(0.85, 0.85)
	for f in range(8):
		await get_tree().process_frame

	var img_pan: Image = get_viewport().get_texture().get_image()
	if img_pan != null:
		img_pan.save_png("res://qa/shots/enemy_roster_arena.png")
		img_pan.save_png(ARTIFACT_DIR + "/enemy_roster_arena.png")
		print("[CAPTURE] Saved arena roster panorama!")

	get_tree().quit(0)
