extends Node

## Live test (Step 0B): a Fighter-driven enemy chases the hero through the real
## LevelRoot + PlatformGraph pipeline (levels/test_fighter_chase.txt):
##   leg 1  start -> jump the pit -> climb the 2-tile ledge -> hero
##   leg 2  hero back at the start: drop off the ledge, jump the pit back
##   leg 3  enemy on a one-way platform, hero below: drop through it
##   godot --headless --path . res://tests/live/fighter_chase.tscn [-- --trace]
## Exit 0 = all legs reached the hero, 1 = failed (prints why).

const LEVEL: String = "res://levels/test_fighter_chase.txt"
const ENEMY_SCENE: String = "res://scenes/enemies/test_fighter.tscn"
const LEG_TIMEOUT: float = 10.0
const START_FEET: Vector2 = Vector2(2.5 * 32.0, 10.0 * 32.0)   # segment A floor
const LEDGE_FEET: Vector2 = Vector2(28.5 * 32.0, 8.0 * 32.0)   # ledge C
const ONE_WAY_FEET: Vector2 = Vector2(6.5 * 32.0, 7.0 * 32.0)  # on the '=' platform
const BELOW_FEET: Vector2 = Vector2(9.5 * 32.0, 10.0 * 32.0)   # floor under / past it

var root: LevelRoot = null
var player: CharacterBody2D = null
var enemy: EnemyBase = null
var jumps: int = 0


func _ready() -> void:
	call_deferred(&"_run")


func _run() -> void:
	root = (load("res://scenes/level/level_root.tscn") as PackedScene).instantiate() as LevelRoot
	root.level_path = LEVEL
	add_child(root)
	for i in 5:
		await get_tree().physics_frame
	player = get_tree().get_first_node_in_group(&"player") as CharacterBody2D
	if player == null:
		_finish(false, "no player spawned")
		return
	player.set_physics_process(false)

	enemy = (load(ENEMY_SCENE) as PackedScene).instantiate() as EnemyBase
	enemy.position = START_FEET + Vector2(0.0, -12.0)
	root.enemies.add_child(enemy)
	enemy.mover.graph = root.platform_graph
	enemy.mover.home_pos = enemy.global_position
	# Drive the chase directly (the same call StChase makes every 0.25 s).
	enemy.state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	enemy.fighter.jumped.connect(func() -> void: jumps += 1)

	var legs: Array = [
		["up: pit + ledge", START_FEET, LEDGE_FEET, 2, 0],
		["down: ledge drop + pit", LEDGE_FEET, START_FEET, 1, 0],
		["one-way drop-through", ONE_WAY_FEET, BELOW_FEET, 0, 1],
	]
	for leg in legs:
		var err: String = await _run_leg(leg[0], leg[1], leg[2], leg[3], leg[4])
		if not err.is_empty():
			_finish(false, "%s: %s" % [leg[0], err])
			return
	_finish(true, "")


func _run_leg(label: String, enemy_feet: Vector2, hero_feet: Vector2, min_jumps: int, min_drops: int) -> String:
	enemy.global_position = enemy_feet + Vector2(0.0, -12.0)
	enemy.velocity = Vector2.ZERO
	enemy.mover.stop()
	player.global_position = hero_feet + Vector2(0.0, -9.0)
	await get_tree().physics_frame
	jumps = 0
	var drops: int = 0
	var was_masked: bool = true
	var t: float = 0.0
	var repath: float = 0.0
	var trace: bool = OS.get_cmdline_user_args().has("--trace")
	while t < LEG_TIMEOUT:
		await get_tree().physics_frame
		var dt: float = get_physics_process_delta_time()
		t += dt
		repath -= dt
		if repath <= 0.0:
			repath = 0.25
			enemy.mover.move_to(hero_feet, enemy.fighter.stats.run_speed)
		var masked: bool = enemy.get_collision_mask_value(2)
		if was_masked and not masked:
			drops += 1
		was_masked = masked
		var feet: Vector2 = enemy.fighter.feet_position()
		if trace:
			print("[t] %s feet=%s vel=%s floor=%s" % [label, feet, enemy.velocity, enemy.is_on_floor()])
		if enemy.is_on_floor() and absf(feet.y - hero_feet.y) < 4.0 and absf(feet.x - hero_feet.x) < 40.0:
			print("[chase] %-24s reached in %.2fs  jumps=%d drop-throughs=%d" % [label, t, jumps, drops])
			if jumps < min_jumps:
				return "reached with %d jumps (expected >= %d)" % [jumps, min_jumps]
			if drops < min_drops:
				return "reached without dropping through the one-way platform"
			return ""
	return "timeout after %.0fs: feet %s, jumps %d, path %s" % [LEG_TIMEOUT, str(enemy.fighter.feet_position()), jumps, str(enemy.mover.current_path)]


func _finish(ok: bool, why: String) -> void:
	if ok:
		print("PASS fighter_chase: enemy jumped the pit, climbed the ledge, dropped back and dropped through a one-way")
	else:
		print("FAIL fighter_chase: ", why)
	get_tree().quit(0 if ok else 1)
