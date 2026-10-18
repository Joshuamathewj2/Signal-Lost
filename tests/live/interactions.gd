extends Node

## Live test (Step 0C): hero <-> villain interactions on real nodes + physics.
##   godot --headless --path . res://tests/live/interactions.tscn
## Exit 0 = all checks pass.

const LEVEL: String = "res://levels/test_fighter_chase.txt"
const FLOOR_Y: float = 10.0 * 32.0   # segment A stand row 9 (feet)

var root: LevelRoot = null
var player: Player = null
var results: Array[String] = []
var failures: Array[String] = []


func _ready() -> void:
	call_deferred(&"_run")


func _run() -> void:
	root = (load("res://scenes/level/level_root.tscn") as PackedScene).instantiate() as LevelRoot
	root.level_path = LEVEL
	add_child(root)
	for i in 5:
		await get_tree().physics_frame
	player = get_tree().get_first_node_in_group(&"player") as Player
	player.health.max_health = 99
	player.health.current_health = 99

	await _test_clash()
	await _test_weight_and_armor()
	await _test_execution()
	await _test_wall_slam()
	await _test_dodge()
	await _test_reactions()
	await _test_friendly_fire()

	for r in results:
		print("  ok  ", r)
	if failures.is_empty():
		print("PASS interactions: %d checks" % results.size())
		get_tree().quit(0)
	else:
		for f in failures:
			print("FAIL interactions: ", f)
		get_tree().quit(1)


func _check(ok: bool, label: String) -> void:
	if ok:
		results.append(label)
	else:
		failures.append(label)


func _spawn(scene: String, x: float) -> EnemyBase:
	var e: EnemyBase = (load(scene) as PackedScene).instantiate() as EnemyBase
	e.position = Vector2(x, FLOOR_Y - 12.0)
	root.enemies.add_child(e)
	e.mover.graph = root.platform_graph
	e.state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	e.health_component.max_health = 20
	e.health_component.current_health = 20
	e.health_component.invulnerability_duration = 0.0
	return e


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _place_player(x: float, facing: int) -> void:
	player.global_position = Vector2(x, FLOOR_Y - 9.0)
	player.velocity = Vector2.ZERO
	player.motor.facing = facing
	await _frames(2)


# 1. Weapon clash: enemy melee lands while the katana is live -> no damage.
func _test_clash() -> void:
	await _place_player(200.0, 1)
	var e: EnemyBase = _spawn("res://scenes/enemies/test_fighter.tscn", 236.0)
	await _frames(3)
	e.hurtbox_component.set_deferred(&"monitorable", false)
	var clashed: Array = []
	player.combat.clashed.connect(func(a: Node) -> void: clashed.append(a))
	player.combat.start_combo_strike(1)
	var guard: int = 0
	while not player.combat.hitbox.is_active and guard < 30:
		await get_tree().physics_frame
		guard += 1
	var hp_before: int = player.health.current_health
	var hb: Area2D = e.get_node("Hitbox") as Area2D
	hb.set("damage", 1)
	player.hurtbox.receive_hit(hb)
	await _frames(1)
	_check(clashed.size() == 1, "clash detected when enemy melee meets a live katana")
	_check(player.health.current_health == hp_before, "clash deals no damage")
	_check(player.velocity.x < 0.0 and e.velocity.x > 0.0, "clash pushes both fighters apart (hero %.0f, enemy %.0f)" % [player.velocity.x, e.velocity.x])
	await _frames(40)
	# Outside the window it is a normal hit again.
	player.combat.current_state = CombatController.CombatState.IDLE
	player.hurtbox.receive_hit(hb)
	_check(player.health.current_health < hp_before, "no clash outside the attack window (normal hit lands)")
	e.queue_free()
	await _frames(2)

	# Enemy side: katana reaches an enemy whose melee window is live -> clash, no damage.
	await _place_player(200.0, 1)
	var e2: EnemyBase = _spawn("res://scenes/enemies/test_fighter.tscn", 236.0)
	await _frames(3)
	var hp_e: int = e2.health_component.current_health
	clashed.clear()
	player.combat.current_state = CombatController.CombatState.IDLE
	e2.mark_attack_active(0.067)
	e2.hurtbox_component.receive_hit(player.combat.hitbox)
	_check(clashed.size() == 1 and e2.health_component.current_health == hp_e, "enemy-side clash: live enemy melee + katana = no damage either way")
	e2.queue_free()
	await _frames(2)


# 2. Weight classes: light flies further than heavy; heavy hyper-armor is not interrupted.
func _test_weight_and_armor() -> void:
	await _place_player(120.0, 1)
	var light: EnemyBase = _spawn("res://scenes/enemies/test_fighter.tscn", 240.0)
	await _frames(3)
	var x0: float = light.global_position.x
	light.health_component.take_damage(1, Vector2(300.0, 0.0))
	await _frames(20)
	var light_dist: float = light.global_position.x - x0
	var light_class: StringName = light.weight_class()
	light.queue_free()
	var heavy: EnemyBase = (load("res://scenes/enemies/brute.tscn") as PackedScene).instantiate() as EnemyBase
	heavy.position = Vector2(240.0, FLOOR_Y - 20.0)
	root.enemies.add_child(heavy)
	heavy.state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	await _frames(3)
	var hx0: float = heavy.global_position.x
	heavy.health_component.max_health = 20
	heavy.health_component.current_health = 20
	heavy.velocity = Vector2.ZERO
	heavy.health_component.take_damage(1, Vector2(300.0, 0.0))
	var heavy_kb: float = heavy.velocity.x
	_check(light_class == &"light" and heavy.weight_class() == &"heavy", "weight classes resolved (light test_fighter, heavy brute)")
	_check(light_dist > 20.0 and heavy_kb < 300.0 * 0.5, "light knocked %.0f px; heavy knockback reduced to %.0f px/s" % [light_dist, heavy_kb])
	_check(heavy.is_hyper_armored(), "brute keeps its legacy always-on hyper-armor")
	heavy.queue_free()
	await _frames(2)


# 3. Execution: staggered enemy + hero hit = boosted damage.
func _test_execution() -> void:
	await _place_player(200.0, 1)
	var e: EnemyBase = _spawn("res://scenes/enemies/test_fighter.tscn", 236.0)
	await _frames(3)
	var executed: Array = []
	e.executed.connect(func() -> void: executed.append(true))
	e.poise_component.damage_poise(9999.0)
	var hp0: int = e.health_component.current_health
	var hb: HitboxComponent = player.combat.hitbox
	hb.damage = 1
	e.hurtbox_component.receive_hit(hb)
	var cfg: Dictionary = CombatTuning.combat("execution")
	var expected: int = int(round(1.0 * float(cfg["damage_mult"]))) + int(cfg["bonus_damage"])
	_check(executed.size() == 1 and hp0 - e.health_component.current_health == expected, "execution on staggered enemy deals %d (got %d)" % [expected, hp0 - e.health_component.current_health])
	e.queue_free()
	await _frames(2)


# 4. Wall slam: knocked fast into a wall -> bonus damage once.
func _test_wall_slam() -> void:
	await _place_player(120.0, 1)
	var e: EnemyBase = _spawn("res://scenes/enemies/test_fighter.tscn", 46.0) # left wall at x=32
	await _frames(3)
	var slams: Array = []
	e.wall_slammed.connect(func() -> void: slams.append(true))
	var hp0: int = e.health_component.current_health
	e.health_component.take_damage(1, Vector2(-320.0, 0.0))
	await _frames(15)
	_check(slams.size() == 1, "wall slam triggered once")
	_check(hp0 - e.health_component.current_health == 1 + int(CombatTuning.combat("wall_slam")["bonus_damage"]), "wall slam adds bonus damage")
	e.queue_free()
	await _frames(2)


# 5. Dodge: Fighter enemies dash away from the hero.
func _test_dodge() -> void:
	await _place_player(200.0, 1)
	var e: EnemyBase = _spawn("res://scenes/enemies/test_fighter.tscn", 240.0)
	await _frames(3)
	var x0: float = e.global_position.x
	var ok: bool = e.dodge_away()
	await _frames(14)
	_check(ok and e.global_position.x - x0 > 30.0, "dodge dash moves away from the hero (%.0f px)" % (e.global_position.x - x0))
	e.queue_free()
	await _frames(2)


# 6. Noise reactions to the hero's landings / dashes / parries.
func _test_reactions() -> void:
	await _place_player(200.0, 1)
	var e: EnemyBase = _spawn("res://scenes/enemies/test_fighter.tscn", 300.0)
	await _frames(3)
	var tags: Array = []
	e.reacted_to_hero.connect(func(t: StringName) -> void: tags.append(t))
	e.face(1) # looking away from the hero
	var ev := NoiseEvent.make(player.global_position, 96.0, 1.0, NoiseEvent.NoiseType.LAND, player)
	ev.tag = &"land"
	NoiseBus.emit_noise(ev)
	_check(tags.has(&"land") and e.facing == -1, "enemy turns toward a nearby hero landing")
	var x0: float = e.global_position.x
	var pv := NoiseEvent.make(player.global_position, 260.0, 2.2, NoiseEvent.NoiseType.COMBAT, player)
	pv.tag = &"parry"
	NoiseBus.emit_noise(pv)
	await _frames(12)
	_check(tags.has(&"parry") and e.global_position.x > x0 + 4.0, "enemy hesitates and gives ground after a parry (%.0f px)" % (e.global_position.x - x0))
	var far := NoiseEvent.make(Vector2(900.0, 250.0), 96.0, 1.0, NoiseEvent.NoiseType.LAND, player)
	far.tag = &"land"
	tags.clear()
	NoiseBus.emit_noise(far)
	_check(tags.is_empty(), "no reaction beyond max_distance / through walls")
	e.queue_free()
	await _frames(2)


# 7. Friendly fire: an ally's shockwave hurts other enemies.
func _test_friendly_fire() -> void:
	var a: EnemyBase = _spawn("res://scenes/enemies/test_fighter.tscn", 200.0)
	var b: EnemyBase = _spawn("res://scenes/enemies/test_fighter.tscn", 240.0)
	await _frames(3)
	var hp0: int = b.health_component.current_health
	var wave: DamageInfo = DamageInfo.make(2, a, DamageInfo.Faction.ENEMY, Vector2(320.0, -80.0), &"shockwave")
	var hit: Array[Node] = Shockwave.strike(get_tree(), a.global_position, 64.0, wave, a)
	_check(hit.has(b) and not hit.has(a) and b.health_component.current_health == hp0 - 2, "enemy shockwave damages allies in range, not its source")
	a.queue_free()
	b.queue_free()
	await _frames(2)
