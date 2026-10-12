class_name TestBossShogun
extends RefCounted

## Unit tests for Sector 9 Shogun Mech Climax Boss

const BOSS_SCRIPT: Script = preload("res://scenes/enemies/boss_shogun.gd")

func run() -> Array[String]:
	var failures: Array[String] = []

	var boss_scene: PackedScene = load("res://scenes/enemies/boss_shogun.tscn")
	if boss_scene == null:
		failures.append("Cannot load boss_shogun.tscn")
		return failures

	var boss: Node2D = boss_scene.instantiate() as Node2D
	if boss == null:
		failures.append("Cannot instantiate BossShogun")
		return failures

	boss._ready()

	# Test 1: Initialization
	var health_comp: HealthComponent = boss.get_node_or_null("HealthComponent") as HealthComponent
	var poise_comp: PoiseComponent = boss.get_node_or_null("PoiseComponent") as PoiseComponent

	if health_comp == null or poise_comp == null:
		failures.append("Missing health or poise component on BossShogun")
		boss.free()
		return failures

	health_comp.invulnerability_duration = 0.0

	if health_comp.max_health != 18 or poise_comp.max_poise != 200.0:
		failures.append("Incorrect boss stats max_hp=%d max_poise=%.1f" % [health_comp.max_health, poise_comp.max_poise])
		boss.free()
		return failures

	var cur_phase: int = boss.get("current_phase") if boss.get("current_phase") != null else 0
	if cur_phase != 1:
		failures.append("Boss should start in Phase 1 (BLADE_MASTER), got %d" % cur_phase)
		boss.free()
		return failures

	# Test 2: Phase 2 Transition at <= 12 HP
	var events := { "phase": 0, "defeated": false }
	boss.connect("phase_changed", func(p: int) -> void: events["phase"] = p)

	health_comp.take_damage(6, Vector2.ZERO, &"katana") # 18 -> 12 HP
	cur_phase = boss.get("current_phase") if boss.get("current_phase") != null else 0
	if cur_phase != 2 or events["phase"] != 2:
		failures.append("Boss failed to transition to Phase 2 at 12 HP (cur_phase=%d event_phase=%d)" % [cur_phase, events["phase"]])
		boss.free()
		return failures

	# Test 3: Phase 3 Transition at <= 6 HP
	health_comp.take_damage(6, Vector2.ZERO, &"katana") # 12 -> 6 HP
	cur_phase = boss.get("current_phase") if boss.get("current_phase") != null else 0
	if cur_phase != 3 or events["phase"] != 3:
		failures.append("Boss failed to transition to Phase 3 at 6 HP (cur_phase=%d event_phase=%d)" % [cur_phase, events["phase"]])
		boss.free()
		return failures

	# Test 4: Poise break stagger
	poise_comp.damage_poise(200.0)
	var cur_action: int = boss.get("current_action") if boss.get("current_action") != null else -1
	if cur_action != 4: # STAGGERED
		failures.append("Boss should enter STAGGERED (4) on poise break (action=%d)" % cur_action)
		boss.free()
		return failures

	# Test 5: Boss Defeat Signal
	boss.connect("boss_defeated", func() -> void: events["defeated"] = true)

	health_comp.take_damage(6, Vector2.ZERO, &"finisher") # 6 -> 0 HP
	if not events["defeated"]:
		failures.append("boss_defeated signal not emitted on lethal damage")
		boss.free()
		return failures

	boss.free()
	return failures
