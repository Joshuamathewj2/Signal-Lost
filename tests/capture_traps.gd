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

	cam.zoom = Vector2(2.5, 2.5)

	# 1. Floor Spikes
	var floor_spikes_scene: PackedScene = load("res://scenes/traps/floor_spikes.tscn")
	var floor_spikes: FloorSpikes = floor_spikes_scene.instantiate() as FloorSpikes
	arena.add_child(floor_spikes)
	floor_spikes.global_position = Vector2(160, 160)
	floor_spikes.trigger_trap()
	floor_spikes._advance_state() # Enter active
	cam.global_position = floor_spikes.global_position + Vector2(0, -16)
	for f in range(6): await get_tree().process_frame
	_save_shot("trap_floor_spikes.png")

	# 2. Ceiling Spikes
	var ceiling_spikes_scene: PackedScene = load("res://scenes/traps/ceiling_spikes.tscn")
	var ceiling_spikes: CeilingSpikes = ceiling_spikes_scene.instantiate() as CeilingSpikes
	arena.add_child(ceiling_spikes)
	ceiling_spikes.global_position = Vector2(260, 80)
	ceiling_spikes.trigger_trap()
	ceiling_spikes._advance_state()
	cam.global_position = ceiling_spikes.global_position + Vector2(0, 40)
	for f in range(6): await get_tree().process_frame
	_save_shot("trap_ceiling_spikes.png")

	# 3. Swinging Blade
	var swinging_blade_scene: PackedScene = load("res://scenes/traps/swinging_blade.tscn")
	var swinging_blade: SwingingBlade = swinging_blade_scene.instantiate() as SwingingBlade
	arena.add_child(swinging_blade)
	swinging_blade.global_position = Vector2(360, 80)
	cam.global_position = swinging_blade.global_position + Vector2(0, 48)
	for f in range(10): await get_tree().process_frame
	_save_shot("trap_swinging_blade.png")

	# 4. Wall Blade
	var wall_blade_scene: PackedScene = load("res://scenes/traps/wall_blade.tscn")
	var wall_blade: WallBlade = wall_blade_scene.instantiate() as WallBlade
	arena.add_child(wall_blade)
	wall_blade.global_position = Vector2(460, 140)
	wall_blade.trigger_trap()
	wall_blade._advance_state()
	cam.global_position = wall_blade.global_position + Vector2(20, 0)
	for f in range(6): await get_tree().process_frame
	_save_shot("trap_wall_blade.png")

	# 5. Arrow Trap & Fired Arrow
	var arrow_trap_scene: PackedScene = load("res://scenes/traps/arrow_trap.tscn")
	var arrow_trap: ArrowTrap = arrow_trap_scene.instantiate() as ArrowTrap
	arena.add_child(arrow_trap)
	arrow_trap.global_position = Vector2(560, 140)
	arrow_trap.trigger_trap()
	arrow_trap._advance_state()
	cam.global_position = arrow_trap.global_position + Vector2(40, 0)
	for f in range(6): await get_tree().process_frame
	_save_shot("trap_arrow_trap.png")

	# 6. Falling Rock Impact
	var falling_rock_scene: PackedScene = load("res://scenes/traps/falling_rock.tscn")
	var falling_rock: FallingRock = falling_rock_scene.instantiate() as FallingRock
	arena.add_child(falling_rock)
	falling_rock.global_position = Vector2(200, 140)
	falling_rock.trigger_trap()
	falling_rock._on_rock_impact()
	cam.global_position = falling_rock.global_position
	for f in range(6): await get_tree().process_frame
	_save_shot("trap_falling_rock.png")

	# 7. Rolling Boulder
	var boulder_scene: PackedScene = load("res://scenes/traps/rolling_boulder.tscn")
	var boulder: RollingBoulder = boulder_scene.instantiate() as RollingBoulder
	arena.add_child(boulder)
	boulder.global_position = Vector2(320, 140)
	boulder.trigger_trap()
	boulder._advance_state()
	cam.global_position = boulder.global_position
	for f in range(6): await get_tree().process_frame
	_save_shot("trap_rolling_boulder.png")

	# 8. Guillotine Razor Drop
	var guillotine_scene: PackedScene = load("res://scenes/traps/guillotine.tscn")
	var guillotine: Guillotine = guillotine_scene.instantiate() as Guillotine
	arena.add_child(guillotine)
	guillotine.global_position = Vector2(440, 90)
	guillotine.trigger_trap()
	guillotine._advance_state()
	cam.global_position = guillotine.global_position + Vector2(0, 32)
	for f in range(6): await get_tree().process_frame
	_save_shot("trap_guillotine.png")

	# 9. Fire Trap Flame Jet
	var fire_trap_scene: PackedScene = load("res://scenes/traps/fire_trap.tscn")
	var fire_trap: FireTrap = fire_trap_scene.instantiate() as FireTrap
	arena.add_child(fire_trap)
	fire_trap.global_position = Vector2(540, 160)
	fire_trap.trigger_trap()
	fire_trap._advance_state()
	cam.global_position = fire_trap.global_position + Vector2(0, -28)
	for f in range(6): await get_tree().process_frame
	_save_shot("trap_fire_trap.png")

	# 10. Trap Killing an Enemy
	var kenshi_scene: PackedScene = load("res://scenes/enemies/kenshi.tscn")
	var doomed_enemy: EnemyBase = kenshi_scene.instantiate() as EnemyBase
	arena.add_child(doomed_enemy)
	doomed_enemy.global_position = Vector2(640, 160)
	var kill_spikes: FloorSpikes = floor_spikes_scene.instantiate() as FloorSpikes
	arena.add_child(kill_spikes)
	kill_spikes.global_position = doomed_enemy.global_position
	kill_spikes.trigger_trap()
	kill_spikes._advance_state()
	# Apply lethal trap strike
	if doomed_enemy.health_component != null:
		doomed_enemy.health_component.take_damage(99, Vector2.UP * 160.0, &"trap")
	cam.global_position = doomed_enemy.global_position + Vector2(0, -16)
	for f in range(8): await get_tree().process_frame
	_save_shot("trap_killing_enemy.png")

	print("\n>>> ALL TRAP SCREENSHOTS CAPTURED SUCCESSFULLY <<<\n")
	get_tree().quit(0)

func _save_shot(filename: String) -> void:
	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		var project_path: String = "res://qa/shots/" + filename
		var global_proj_path: String = ProjectSettings.globalize_path(project_path)
		img.save_png(global_proj_path)
		var artifact_path: String = ARTIFACT_DIR + "/" + filename
		img.save_png(artifact_path)
		print("Saved screenshot: %s" % filename)
