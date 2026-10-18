extends Node2D

const ARTIFACT_DIR: String = "C:/Users/Administrator.TNEB/.gemini/antigravity-ide/brain/797c8105-e056-48de-ac95-136de5f2a429"

func _ready() -> void:
	call_deferred(&"_run_captures")

func _run_captures() -> void:
	DirAccess.make_dir_recursive_absolute("res://qa/shots")
	DirAccess.make_dir_recursive_absolute(ARTIFACT_DIR)

	var arena_scene: PackedScene = load("res://scenes/test/combat_test_arena.tscn")
	var arena: Node2D = arena_scene.instantiate() as Node2D
	add_child(arena)

	var cam: Camera2D = arena.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		cam = Camera2D.new()
		arena.add_child(cam)

	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: CharacterBody2D = player_scene.instantiate() as CharacterBody2D
	arena.add_child(player)
	player.global_position = Vector2(200, 160)

	var kenshi_scene: PackedScene = load("res://scenes/enemies/kenshi.tscn")
	var kenshi: EnemyBase = kenshi_scene.instantiate() as EnemyBase
	arena.add_child(kenshi)
	kenshi.global_position = Vector2(260, 160)

	var brute_scene: PackedScene = load("res://scenes/enemies/brute.tscn")
	var brute: EnemyBase = brute_scene.instantiate() as EnemyBase
	arena.add_child(brute)
	brute.global_position = Vector2(360, 160)

	for i in range(15):
		await get_tree().process_frame

	var visual: PlayerVisual = player.get_node_or_null("Visual") as PlayerVisual
	var combat: CombatController = player.get_node_or_null("CombatController") as CombatController

	# 1. Capture Hero Idle & Rim Contour
	if visual != null:
		visual.set_pose(&"idle")
	cam.global_position = player.global_position + Vector2(0, -12)
	cam.zoom = Vector2(3.5, 3.5)
	for f in range(6): await get_tree().process_frame
	_save_shot("hero_sprite_idle.png")

	# 2. Capture Hero Dash Slash
	if visual != null:
		visual.set_pose(&"dash_slash")
	if combat != null:
		combat.start_dash_slash()
	for f in range(6): await get_tree().process_frame
	_save_shot("hero_dash_slash.png")

	# 3. Capture Hero Plunge Strike Impact
	if visual != null:
		visual.set_pose(&"plunge")
	ParticlesFactory.spawn_smash_impact(arena, player.global_position + Vector2(0, 10))
	for f in range(6): await get_tree().process_frame
	_save_shot("hero_plunge_strike.png")

	# 4. Capture Hero Rising Slash
	if visual != null:
		visual.set_pose(&"rising_slash")
	var slash_arc_script: Script = load("res://scenes/fx/slash_arc.gd")
	if slash_arc_script != null:
		slash_arc_script.call("spawn", player, Vector2(0.0, -14.0), 1, 44.0)
	for f in range(6): await get_tree().process_frame
	_save_shot("hero_rising_slash.png")

	# 5. Capture Hero Counter Strike Riposte with Flash
	if visual != null:
		visual.set_pose(&"counter_strike")
		visual.flash()
	for f in range(4): await get_tree().process_frame
	_save_shot("hero_counter_strike.png")

	# 6. Capture Enemy Hit Flinch & Floating Health Bar
	cam.global_position = kenshi.global_position + Vector2(0, -16)
	cam.zoom = Vector2(3.2, 3.2)
	kenshi._on_damaged(1, Vector2(-120, 0))
	for f in range(6): await get_tree().process_frame
	_save_shot("enemy_hit_flinch.png")

	# 7. Capture Enemy Poise Break Stagger
	if kenshi.poise_component != null:
		kenshi.poise_component.damage_poise(60.0)
	for f in range(6): await get_tree().process_frame
	_save_shot("enemy_poise_break.png")

	# 8. Capture Vertical Ledge Jump Traversal
	kenshi.global_position = Vector2(220, 150)
	kenshi.velocity = Vector2(120, -420)
	kenshi.escape_jump_upward()
	cam.global_position = Vector2(250, 110)
	cam.zoom = Vector2(2.4, 2.4)
	for f in range(6): await get_tree().process_frame
	_save_shot("enemy_vertical_jump.png")

	# 9. Capture Brute Rage Mode
	cam.global_position = brute.global_position + Vector2(0, -20)
	cam.zoom = Vector2(2.6, 2.6)
	brute._trigger_low_hp_behavior()
	for f in range(6): await get_tree().process_frame
	_save_shot("enemy_brute_enraged.png")

	# 10. Capture Combat Arena with HUD Segmented Bar
	cam.global_position = Vector2(260, 140)
	cam.zoom = Vector2(1.8, 1.8)
	var hud_scene: PackedScene = load("res://scenes/ui/hud.tscn")
	if hud_scene != null:
		var hud: HUD = hud_scene.instantiate() as HUD
		add_child(hud)
		hud._on_health_changed(2, 3) # Demonstrate damage segment
	for f in range(8): await get_tree().process_frame
	_save_shot("combat_arena_hud_view.png")

	print("\nALL SCREENSHOTS CAPTURED SUCCESSFULLY TO res://qa/shots/ and brain artifact dir!")
	get_tree().quit(0)

func _save_shot(filename: String) -> void:
	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		var qa_path := "res://qa/shots/" + filename
		var art_path := ARTIFACT_DIR + "/" + filename
		img.save_png(qa_path)
		img.save_png(art_path)
		print("[CAPTURE] " + filename + " -> " + qa_path)
