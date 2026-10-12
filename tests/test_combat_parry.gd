class_name TestCombatParry
extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []

	# Setup target (hero)
	var hero: CharacterBody2D = CharacterBody2D.new()
	var hero_hc: HealthComponent = HealthComponent.new()
	hero_hc.max_health = 3
	hero.add_child(hero_hc)
	var hero_pc: PoiseComponent = PoiseComponent.new()
	hero.add_child(hero_pc)
	var hero_cbt: CombatController = CombatController.new()
	hero.add_child(hero_cbt)
	hero_cbt.health_comp = hero_hc
	hero_cbt.poise_comp = hero_pc
	hero_cbt.player = hero
	hero_cbt._ready()

	# Setup attacker
	var attacker: Node2D = Node2D.new()
	var attacker_pc: PoiseComponent = PoiseComponent.new()
	attacker_pc.name = "PoiseComponent"
	attacker.add_child(attacker_pc)
	attacker_pc._ready()
	var hostile_hitbox: HitboxComponent = HitboxComponent.new()
	hostile_hitbox.damage = 1
	hostile_hitbox.poise_damage = 20.0
	attacker.add_child(hostile_hitbox)

	# 1. Test unparried hit
	var parried: bool = hero_cbt.intercept_hit(hostile_hitbox)
	if parried:
		failures.append("Hit intercepted while IDLE (expected false)")

	# 2. Test successful parry deflect
	hero_cbt.start_parry()
	var parry_signal_called: Array[bool] = [false]
	hero_cbt.parry_success.connect(func(_atk: Node) -> void:
		parry_signal_called[0] = true
	)

	parried = hero_cbt.intercept_hit(hostile_hitbox)
	if not parried:
		failures.append("Hit not intercepted during active parry window")
	if not parry_signal_called[0]:
		failures.append("parry_success signal not emitted")
	if absf(attacker_pc.current_poise - 60.0) > 0.01:
		failures.append("Expected attacker poise 60.0 after parry, got %f" % attacker_pc.current_poise)
	if not hero_hc.is_invulnerable:
		failures.append("Hero not granted i-frames after successful parry")

	# Cleanup
	hero.queue_free()
	attacker.queue_free()

	return failures
