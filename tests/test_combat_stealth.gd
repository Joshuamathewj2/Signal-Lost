class_name TestCombatStealth
extends RefCounted

## TestCombatStealth
## Unit test suite for AssassinationSystem rear cone, distance, and awareness logic.

func run() -> Array[String]:
	var failures: Array[String] = []

	var assassin_sys := AssassinationSystem.new()

	var hero := CharacterBody2D.new()
	hero.global_position = Vector2(100, 100)

	var enemy := CharacterBody2D.new()
	enemy.global_position = Vector2(120, 100)
	# Enemy is facing right (+1)
	enemy.set_meta(&"facing", 1)

	var enemy_hc := HealthComponent.new()
	enemy_hc.name = "HealthComponent"
	enemy_hc.max_health = 3
	enemy.add_child(enemy_hc)
	enemy_hc._ready()

	# 1. Hero is to the left of enemy (x = 100, enemy x = 120, facing right).
	# This means hero is behind the enemy! Distance = 20 px (< 28 px).
	# Enemy has awareness 0.0 (< 0.35).
	enemy.set_meta(&"awareness", 0.0)
	var can_kill: bool = AssassinationSystem.can_assassinate(hero, enemy)
	if not can_kill:
		failures.append("Expected can_assassinate to return true when behind unaware enemy")

	# 2. Test awareness threshold >= 0.35
	enemy.set_meta(&"awareness", 0.50)
	can_kill = AssassinationSystem.can_assassinate(hero, enemy)
	if can_kill:
		failures.append("can_assassinate returned true for alerted enemy (awareness 0.50)")
	enemy.set_meta(&"awareness", 0.0)

	# 3. Test distance > 32 px
	hero.global_position = Vector2(70, 100) # Dist = 50 px
	can_kill = AssassinationSystem.can_assassinate(hero, enemy)
	if can_kill:
		failures.append("can_assassinate returned true when distance 50 px > 32 px")
	hero.global_position = Vector2(100, 100)

	# 4. Test front angle (hero in front of enemy: enemy at 120, hero at 140, enemy facing right)
	hero.global_position = Vector2(140, 100)
	can_kill = AssassinationSystem.can_assassinate(hero, enemy)
	if can_kill:
		failures.append("can_assassinate returned true when hero is in front of enemy")
	hero.global_position = Vector2(100, 100)

	# 5. Execute assassination
	var executed: bool = assassin_sys.execute(hero, enemy)
	if not executed:
		failures.append("assassin_sys.execute returned false")
	if enemy_hc.current_health > 0:
		failures.append("Enemy health expected 0 after assassination, got %d" % enemy_hc.current_health)

	hero.free()
	enemy.free()
	assassin_sys.free()
	return failures
