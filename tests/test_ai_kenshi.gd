class_name TestAiKenshi
extends RefCounted

## TestAiKenshi
## Unit tests for Kenshi duelist components, auto-parry, and states.

func run() -> Array[String]:
	var failures: Array[String] = []

	var kenshi_scene: PackedScene = load("res://scenes/enemies/kenshi.tscn")
	if kenshi_scene == null:
		failures.append("Failed to load res://scenes/enemies/kenshi.tscn")
		return failures

	var enemy = kenshi_scene.instantiate()
	if enemy == null:
		failures.append("Failed to instantiate kenshi scene")
		return failures

	# 1. Identity & Kind
	if enemy.kind != &"kenshi":
		failures.append("Expected kind &\"kenshi\", got %s" % str(enemy.kind))

	# 2. Components check
	var hc: HealthComponent = enemy.get_node_or_null("HealthComponent") as HealthComponent
	if hc == null or hc.max_health != 3:
		failures.append("Expected HealthComponent with max_health 3")

	var pc: PoiseComponent = enemy.get_node_or_null("PoiseComponent") as PoiseComponent
	if pc == null or pc.max_poise != 60.0:
		failures.append("Expected PoiseComponent with max_poise 60.0")

	var hurtbox: HurtboxComponent = enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
	if hurtbox == null:
		failures.append("Missing HurtboxComponent on Kenshi")

	# 3. State Machine check
	var sm: StateMachine = enemy.get_node_or_null("StateMachine") as StateMachine
	if sm == null:
		failures.append("Missing StateMachine on Kenshi")
	else:
		for required_state in [&"Patrol", &"Chase", &"Duel", &"Stagger"]:
			if not sm.has_node(str(required_state)):
				failures.append("Missing required state node %s on Kenshi" % str(required_state))

	# 4. Auto-Parry Deflection Check
	var duel_state = sm.get_node_or_null("Duel")
	if duel_state != null:
		duel_state.actor = enemy
		sm.current = duel_state
		duel_state.auto_parry_chance = 1.0 # Guarantee parry for test

		# Mock frontal hitbox
		var front_hb := Area2D.new()
		front_hb.global_position = enemy.global_position + Vector2(20, 0)
		enemy.facing = 1

		var deflected: bool = enemy.intercept_hit(front_hb)
		if not deflected:
			failures.append("Expected Kenshi to auto-parry frontal strike")

		# Mock rear hitbox
		var rear_hb := Area2D.new()
		rear_hb.global_position = enemy.global_position - Vector2(20, 0)
		var rear_deflected: bool = duel_state.intercept_hit(rear_hb)
		if rear_deflected:
			failures.append("Kenshi should not parry rear strike")

		front_hb.free()
		rear_hb.free()

	# 5. Poise Break Test
	if pc != null:
		pc.damage_poise(60.0)
		if not pc.is_staggered:
			failures.append("Kenshi not staggered after taking 60.0 poise damage")

	enemy.free()
	return failures
