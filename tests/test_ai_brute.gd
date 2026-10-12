class_name TestAiBrute
extends RefCounted

## TestAiBrute
## Unit tests for Oni Brute components, armor deflection, and club slam.

func run() -> Array[String]:
	var failures: Array[String] = []

	var brute_scene: PackedScene = load("res://scenes/enemies/brute.tscn")
	if brute_scene == null:
		failures.append("Failed to load res://scenes/enemies/brute.tscn")
		return failures

	var enemy = brute_scene.instantiate()
	if enemy == null:
		failures.append("Failed to instantiate brute scene")
		return failures

	# 1. Identity & Kind
	if enemy.kind != &"brute":
		failures.append("Expected kind &\"brute\", got %s" % str(enemy.kind))

	# 2. Components check
	var hc: HealthComponent = enemy.get_node_or_null("HealthComponent") as HealthComponent
	if hc == null or hc.max_health != 6:
		failures.append("Expected HealthComponent with max_health 6")

	var pc: PoiseComponent = enemy.get_node_or_null("PoiseComponent") as PoiseComponent
	if pc == null or pc.max_poise != 120.0:
		failures.append("Expected PoiseComponent with max_poise 120.0")

	var hurtbox: HurtboxComponent = enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
	if hurtbox == null:
		failures.append("Missing HurtboxComponent on Brute")

	# 3. State Machine check
	var sm: StateMachine = enemy.get_node_or_null("StateMachine") as StateMachine
	if sm == null:
		failures.append("Missing StateMachine on Brute")
	else:
		for required_state in [&"Wander", &"Charge", &"Stunned", &"Slam"]:
			if not sm.has_node(str(required_state)):
				failures.append("Missing required state node %s on Brute" % str(required_state))

	# 4. Front Armor Defense Check
	enemy.facing = 1

	# A. Frontal light Katana strike -> Intercepted (bounced off)
	var light_hb := Area2D.new()
	light_hb.global_position = enemy.global_position + Vector2(20, 0)
	light_hb.set("damage", 1)
	light_hb.set("poise_damage", 20.0)
	light_hb.set_meta(&"weapon_type", 0)
	light_hb.set_meta(&"is_heavy", false)

	var light_blocked: bool = enemy.intercept_hit(light_hb)
	if not light_blocked:
		failures.append("Expected Brute front armor to bounce light Katana strike")

	# B. Frontal heavy Naginata strike -> Penetrates armor (not intercepted)
	var heavy_hb := Area2D.new()
	heavy_hb.global_position = enemy.global_position + Vector2(20, 0)
	heavy_hb.set("damage", 3)
	heavy_hb.set("poise_damage", 60.0)
	heavy_hb.set_meta(&"weapon_type", 1)
	heavy_hb.set_meta(&"is_heavy", true)

	var heavy_blocked: bool = enemy.intercept_hit(heavy_hb)
	if heavy_blocked:
		failures.append("Expected Brute front armor to be penetrated by heavy Naginata strike")

	# C. Rear strike -> Penetrates armor (not intercepted)
	var rear_hb := Area2D.new()
	rear_hb.global_position = enemy.global_position - Vector2(20, 0)
	rear_hb.set("damage", 1)
	rear_hb.set("poise_damage", 20.0)
	rear_hb.set_meta(&"weapon_type", 0)
	rear_hb.set_meta(&"is_heavy", false)

	var rear_blocked: bool = enemy.intercept_hit(rear_hb)
	if rear_blocked:
		failures.append("Expected Brute to take damage from rear strike")

	light_hb.free()
	heavy_hb.free()
	rear_hb.free()
	enemy.free()

	return failures
