extends Node

## Live test for Chapter II villains + Leviathan (headless):
##   godot --headless --path . res://tests/live/test_villains.tscn
## For every manifest villain: spawn it facing the hero, keep the room lit,
## let its own AI (Patrol -> Chase -> Attack) run, and require the hero to
## take damage. Then it must die cleanly. Warden: frontal guard blocks, a hit
## from behind lands. Leviathan: every attack fires, phases 1->2->3 on damage,
## boss_defeated on death.
## Exit 0 = all checks pass.

const LEVEL_ROOT: PackedScene = preload("res://scenes/level/level_root.tscn")
const GALLERY: String = "res://levels/test_villain_gallery.txt"
const KINDS: Dictionary = {
	"phantom": 44.0, "warden": 50.0, "executioner": 54.0, "iron_monk": 46.0,
	"blood_archer": 190.0, "archer": 220.0, "acoustic_hunter": 180.0,
}

var level: Node2D = null
var player: Node2D = null
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
		_reveal()
		await get_tree().physics_frame


## Fake a sonar bubble on the hero every frame so sight-based AI can see.
func _reveal() -> void:
	if player != null and is_instance_valid(player):
		PulseRegistry.set_bubbles([{"active": true, "origin": player.global_position, "radius": 4000.0, "brightness": 1.0}])


func _new_level() -> void:
	if level != null and is_instance_valid(level):
		level.queue_free()
		await get_tree().process_frame
	level = LEVEL_ROOT.instantiate() as Node2D
	level.set("level_path", GALLERY)
	add_child(level)
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group(&"player") as Node2D
	var hc: HealthComponent = player.get_node("HealthComponent") as HealthComponent
	hc.max_health = 99
	hc.current_health = 99
	hc.invulnerability_duration = 0.05


func _player_hp() -> int:
	return int((player.get_node("HealthComponent") as HealthComponent).current_health)


func _spawn(kind: String, dx: float) -> Node2D:
	var cell := Vector2i(int((player.global_position.x + dx) / 32.0), 9)
	var v: Node2D = EntitySpawner.spawn_villain(kind, cell, level.get_node("Enemies") as Node2D, level.get("platform_graph") as PlatformGraph)
	v.call("face", -1)
	return v


func _run() -> void:
	for kind in KINDS:
		await _test_villain(kind, float(KINDS[kind]))
	await _test_warden_guard()
	await _test_boss()
	_report()


func _test_villain(kind: String, dx: float) -> void:
	await _new_level()
	await _frames(5)
	var v: Node2D = _spawn(kind, dx)
	await _frames(3)
	var hp0: int = _player_hp()
	var saw_attack: bool = false
	var t: int = 0
	while t < 60 * 8 and _player_hp() >= hp0:
		await _frames(1)
		t += 1
		var sm: StateMachine = v.get_node("StateMachine") as StateMachine
		if sm.current != null and sm.current.name == &"Attack":
			saw_attack = true
	_check(saw_attack, "%s: AI reached Attack on its own" % kind)
	_check(_player_hp() < hp0, "%s: hero took damage (%d -> %d) after %.1fs" % [kind, hp0, _player_hp(), float(t) / 60.0])

	var died: Array = [false]
	(v.get_node("HealthComponent") as HealthComponent).died.connect(func(_c: StringName) -> void: died[0] = true)
	var info := DamageInfo.make(99, player, DamageInfo.Faction.PLAYER, Vector2(100.0, 0.0), &"test")
	info.apply_to(v)
	await _frames(240)
	var dbg: String = "" if not is_instance_valid(v) else " [hp=%d alpha=%.2f state=%s]" % [(v.get_node("HealthComponent") as HealthComponent).current_health, v.modulate.a, str((v.get_node("StateMachine") as StateMachine).current.name)]
	_check(died[0] and not is_instance_valid(v), "%s: dies and is cleaned up (died=%s)%s" % [kind, str(died[0]), dbg])


func _hero_hitbox(dmg: int, poise: float) -> Area2D:
	var hb := VillainHitbox.new()
	hb.damage = dmg
	hb.poise_damage = poise
	player.add_child(hb)
	return hb


func _test_warden_guard() -> void:
	await _new_level()
	await _frames(3)
	var w: Node2D = _spawn("warden", 120.0)
	w.process_mode = Node.PROCESS_MODE_DISABLED
	await _frames(2)
	var light: Area2D = _hero_hitbox(1, 20.0)
	light.global_position = w.global_position + Vector2(-20.0, 0.0)  # in front (warden faces left)
	_check(bool(w.call("intercept_hit", light)), "warden: shield blocks a frontal light hit")
	light.global_position = w.global_position + Vector2(20.0, 0.0)  # behind
	_check(not bool(w.call("intercept_hit", light)), "warden: hit from behind is not blocked")
	var heavy: Area2D = _hero_hitbox(2, 60.0)
	heavy.global_position = w.global_position + Vector2(-20.0, 0.0)
	_check(not bool(w.call("intercept_hit", heavy)), "warden: heavy (60 poise) hit breaks through the shield")


func _test_boss() -> void:
	await _new_level()
	await _frames(3)
	var cell := Vector2i(int((player.global_position.x + 70.0) / 32.0), 9)
	var boss: BossLeviathan = EntitySpawner.spawn_villain("boss_leviathan", cell, level.get_node("Enemies") as Node2D, null) as BossLeviathan
	_check(boss != null, "leviathan: spawns")
	if boss == null:
		return
	_check(boss.is_in_group(&"boss"), "leviathan: in boss group (BossHealthBar binds)")
	await _frames(int(60 * 1.8))  # intro

	var hp0: int = _player_hp()
	boss.start_attack("slam")
	await _frames(70)
	_check(_player_hp() < hp0, "leviathan: overhead slam hits the hero in front")

	var phases: Array[int] = []
	boss.phase_changed.connect(func(n: int) -> void: phases.append(n))
	var hc: HealthComponent = boss.get_node("HealthComponent") as HealthComponent
	hc.take_damage(9, Vector2.ZERO, &"test")
	await _frames(100)
	_check(boss.phase == 2, "leviathan: phase 2 at <=66%% HP (hp %d)" % hc.current_health)

	for atk in ["jump_slam", "pillars"]:
		boss.global_position.x = player.global_position.x + 120.0
		var before: int = _player_hp()
		boss.start_attack(atk)
		await _frames(150)
		_check(_player_hp() < before, "leviathan: %s damages the hero" % atk)
		boss.action = BossLeviathan.Action.IDLE

	hc.take_damage(8, Vector2.ZERO, &"test")
	await _frames(100)
	_check(boss.phase == 3 and phases == [2, 3], "leviathan: phase 3 at <=33%% HP, phases %s" % str(phases))

	for atk in ["clones", "sword_rain"]:
		var before2: int = _player_hp()
		boss.start_attack(atk)
		await _frames(60 * 4)
		_check(_player_hp() < before2, "leviathan: %s damages the hero" % atk)
		boss.action = BossLeviathan.Action.IDLE

	var pc: PoiseComponent = boss.get_node("PoiseComponent") as PoiseComponent
	pc.damage_poise(999.0)
	await _frames(2)
	_check(boss.action == BossLeviathan.Action.STAGGERED, "leviathan: poise break staggers")
	var hp_before: int = hc.current_health
	var hb: Area2D = _hero_hitbox(1, 10.0)
	(boss.get_node("HurtboxComponent") as HurtboxComponent).receive_hit(hb)
	_check(hc.current_health == hp_before - 2, "leviathan: staggered hits deal double damage")

	var defeated: Array = [false]
	boss.boss_defeated.connect(func() -> void: defeated[0] = true)
	hc.take_damage(99, Vector2.ZERO, &"test")
	await _frames(10)
	_check(defeated[0], "leviathan: boss_defeated emitted on death")


func _report() -> void:
	for r in results:
		print("  ok  ", r)
	if failures.is_empty():
		print("PASS test_villains: %d checks" % results.size())
		get_tree().quit(0)
	else:
		for f in failures:
			print("FAIL test_villains: ", f)
		get_tree().quit(1)
