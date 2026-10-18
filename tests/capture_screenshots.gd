extends Node2D

func _ready() -> void:
	call_deferred(&"_capture_all")

func _step(frames: int = 1) -> void:
	for i in range(frames):
		await get_tree().process_frame

func _capture_all() -> void:
	var dir := DirAccess.open("res://")
	if dir != null:
		dir.make_dir_recursive("qa/shots")

	print("[Screenshot Capture] Initializing high-fidelity capture sequence...")
	await _step(5)

	var lr_scene: PackedScene = load("res://scenes/level/level_root.tscn")

	# --- 1. Level 1 Atmosphere & Parallax Depth ---
	print("[Screenshot Capture] Loading Level 1 in LevelRoot...")
	var lr1: LevelRoot = lr_scene.instantiate() as LevelRoot
	lr1.level_path = "res://levels/level_01.txt"
	add_child(lr1)
	await _step(25)

	var l1_player: Player = lr1.get_node_or_null("Player") as Player
	if l1_player != null:
		print("  -> Found Player in Level 1 at ", l1_player.global_position)
		var p_motor: PlayerMotor = l1_player.get_node_or_null("PlayerMotor") as PlayerMotor
		if p_motor != null:
			p_motor.facing = 1
		if lr1.sonar_system != null:
			var prof: PulseProfile = preload("res://resources/pulses/pulse_normal.tres")
			lr1.sonar_system.spawn(prof, l1_player.global_position)

	await _step(15)
	var img1: Image = get_viewport().get_texture().get_image()
	if img1 != null:
		img1.save_png("res://qa/shots/level1_spawn_after.png")
		img1.save_png("res://qa/shots/level1_atmosphere.png")
		print("  -> Saved res://qa/shots/level1_spawn_after.png and level1_atmosphere.png")

	lr1.queue_free()
	await _step(10)

	# --- 2. Level 2 (Acoustic Bay) Multi-Tier Atmosphere ---
	print("[Screenshot Capture] Loading Level 2 in LevelRoot...")
	var lr2: LevelRoot = lr_scene.instantiate() as LevelRoot
	lr2.level_path = "res://levels/level_02.txt"
	add_child(lr2)
	await _step(25)

	var l2_player: Player = lr2.get_node_or_null("Player") as Player
	if l2_player != null:
		if lr2.sonar_system != null:
			var prof: PulseProfile = preload("res://resources/pulses/pulse_normal.tres")
			lr2.sonar_system.spawn(prof, l2_player.global_position)

	await _step(15)
	var img2: Image = get_viewport().get_texture().get_image()
	if img2 != null:
		img2.save_png("res://qa/shots/level2_bay_atmosphere.png")
		print("  -> Saved res://qa/shots/level2_bay_atmosphere.png")

	lr2.queue_free()
	await _step(10)

	# --- 3. Level 9 (Shogun Citadel Boss Arena) ---
	print("[Screenshot Capture] Loading Level 9 in LevelRoot...")
	var lr9: LevelRoot = lr_scene.instantiate() as LevelRoot
	lr9.level_path = "res://levels/level_09.txt"
	add_child(lr9)
	await _step(25)

	var l9_player: Player = lr9.get_node_or_null("Player") as Player
	if l9_player != null:
		if lr9.sonar_system != null:
			var prof: PulseProfile = preload("res://resources/pulses/pulse_normal.tres")
			lr9.sonar_system.spawn(prof, l9_player.global_position)

	await _step(15)
	var img9: Image = get_viewport().get_texture().get_image()
	if img9 != null:
		img9.save_png("res://qa/shots/level9_citadel_arena.png")
		print("  -> Saved res://qa/shots/level9_citadel_arena.png")

	lr9.queue_free()
	await _step(10)

	# --- 4. Combat Arena High-Detail Closeups ---
	var arena_scene: PackedScene = load("res://scenes/test/combat_test_arena.tscn")
	var arena: Node2D = arena_scene.instantiate() as Node2D
	add_child(arena)
	await _step(5)

	var cam: Camera2D = arena.get_node_or_null("Camera2D") as Camera2D
	var player: Player = arena.get_node_or_null("Player") as Player
	var combat: CombatController = player.get_node_or_null("CombatController") as CombatController
	var motor: PlayerMotor = player.get_node_or_null("PlayerMotor") as PlayerMotor
	var dummy_guard: EnemyBase = arena.get_node_or_null("DummyGuard") as EnemyBase

	# Freeze enemies
	for enemy in get_tree().get_nodes_in_group(&"enemies"):
		if enemy is EnemyBase:
			var eb := enemy as EnemyBase
			if eb.mover != null:
				eb.mover.set_physics_process(false)
			if eb.state_machine != null:
				eb.state_machine.set_physics_process(false)
				eb.state_machine.set_process(false)

	player.global_position = Vector2(240, 168)
	motor.facing = 1
	if cam != null:
		cam.enabled = true
		cam.make_current()
		cam.global_position = Vector2(265, 165)
		cam.zoom = Vector2(3.5, 3.5)
	if dummy_guard != null:
		dummy_guard.global_position = Vector2(285, 168)

	await _step(5)

	# 4.1 Katana Slash Arc in Motion
	print("[Screenshot Capture] Capturing Katana slash arc in motion...")
	combat.start_combo_strike(1)
	await _step(5)
	var img_slash: Image = get_viewport().get_texture().get_image()
	if img_slash != null:
		img_slash.save_png("res://qa/shots/katana_slash_arc.png")
		print("  -> Saved res://qa/shots/katana_slash_arc.png")

	combat.hitbox.deactivate()
	combat.current_state = CombatController.CombatState.IDLE
	motor.set_state(PlayerMotor.MotorState.IDLE)
	await _step(6)

	# 4.2 Parry Flash
	print("[Screenshot Capture] Capturing Parry flash...")
	if cam != null:
		cam.global_position = Vector2(240, 155)
	combat.start_parry()
	await _step(2)
	var img_parry: Image = get_viewport().get_texture().get_image()
	if img_parry != null:
		img_parry.save_png("res://qa/shots/parry_flash.png")
		print("  -> Saved res://qa/shots/parry_flash.png")

	combat.current_state = CombatController.CombatState.IDLE
	motor.set_state(PlayerMotor.MotorState.IDLE)
	await _step(6)

	# 4.3 Shuriken Throw
	print("[Screenshot Capture] Capturing Shuriken throw...")
	var shuriken: Shuriken = Shuriken.new()
	arena.add_child(shuriken)
	shuriken.global_position = player.global_position + Vector2(28, -6)
	shuriken.direction = Vector2.RIGHT
	shuriken.speed = 400.0
	if cam != null:
		cam.global_position = Vector2(260, 155)
	await _step(4)
	var img_shuriken: Image = get_viewport().get_texture().get_image()
	if img_shuriken != null:
		img_shuriken.save_png("res://qa/shots/shuriken_throw.png")
		print("  -> Saved res://qa/shots/shuriken_throw.png")

	arena.queue_free()
	await _step(5)

	print("[Screenshot Capture] All high-detail screenshots captured successfully!")
	get_tree().quit(0)
