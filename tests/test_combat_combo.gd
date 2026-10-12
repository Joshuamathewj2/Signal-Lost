class_name TestCombatCombo
extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []

	var hero: CharacterBody2D = CharacterBody2D.new()
	var hero_hc: HealthComponent = HealthComponent.new()
	var hero_pc: PoiseComponent = PoiseComponent.new()
	var hero_hitbox: HitboxComponent = HitboxComponent.new()
	var hero_cbt: CombatController = CombatController.new()

	hero.add_child(hero_hc)
	hero.add_child(hero_pc)
	hero.add_child(hero_hitbox)
	hero.add_child(hero_cbt)

	hero_cbt.health_comp = hero_hc
	hero_cbt.poise_comp = hero_pc
	hero_cbt.hitbox = hero_hitbox
	hero_cbt.player = hero
	hero_cbt._ready()

	# 1. Test Slash 1 start
	hero_cbt.start_combo_strike(1)
	if hero_cbt.current_combo != 1:
		failures.append("Expected current_combo 1, got %d" % hero_cbt.current_combo)
	if hero_hitbox.damage != 1:
		failures.append("Expected Slash 1 damage 1, got %d" % hero_hitbox.damage)
	if absf(hero_hitbox.poise_damage - 15.0) > 0.01:
		failures.append("Expected Slash 1 poise_damage 15.0, got %f" % hero_hitbox.poise_damage)

	# 2. Test Slash 2 start
	hero_cbt.start_combo_strike(2)
	if hero_cbt.current_combo != 2:
		failures.append("Expected current_combo 2, got %d" % hero_cbt.current_combo)
	if absf(hero_hitbox.knockback_force - 150.0) > 0.01:
		failures.append("Expected Slash 2 knockback 150.0, got %f" % hero_hitbox.knockback_force)

	# 3. Test Slash 3 (Finisher)
	hero_cbt.start_combo_strike(3)
	if hero_cbt.current_combo != 3:
		failures.append("Expected current_combo 3, got %d" % hero_cbt.current_combo)
	if hero_hitbox.damage != 2:
		failures.append("Expected Slash 3 damage 2, got %d" % hero_hitbox.damage)
	if absf(hero_hitbox.poise_damage - 30.0) > 0.01:
		failures.append("Expected Slash 3 poise_damage 30.0, got %f" % hero_hitbox.poise_damage)

	# 4. Test Dash roll
	hero_cbt.current_state = CombatController.CombatState.IDLE
	hero_cbt.handle_dash_input()
	if hero_cbt.current_state != CombatController.CombatState.DASHING:
		failures.append("Expected DASHING state after handle_dash_input")
	if not hero_hc.is_invulnerable:
		failures.append("Expected hero invulnerable during dash")

	hero.queue_free()
	return failures
