class_name TestAiYumi
extends RefCounted

## TestAiYumi
## Unit tests for Yumi balcony archer components, laser aim, and arrow specs.

func run() -> Array[String]:
	var failures: Array[String] = []

	var yumi_scene: PackedScene = load("res://scenes/enemies/yumi.tscn")
	if yumi_scene == null:
		failures.append("Failed to load res://scenes/enemies/yumi.tscn")
		return failures

	var enemy = yumi_scene.instantiate()
	if enemy == null:
		failures.append("Failed to instantiate yumi scene")
		return failures

	# 1. Identity & Kind
	if enemy.kind != &"yumi":
		failures.append("Expected kind &\"yumi\", got %s" % str(enemy.kind))

	# 2. Components check
	var hc: HealthComponent = enemy.get_node_or_null("HealthComponent") as HealthComponent
	if hc == null or hc.max_health != 1:
		failures.append("Expected HealthComponent with max_health 1")

	var pc: PoiseComponent = enemy.get_node_or_null("PoiseComponent") as PoiseComponent
	if pc == null or pc.max_poise != 20.0:
		failures.append("Expected PoiseComponent with max_poise 20.0")

	var hurtbox: HurtboxComponent = enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
	if hurtbox == null:
		failures.append("Missing HurtboxComponent on Yumi")

	# 3. State Machine check
	var sm: StateMachine = enemy.get_node_or_null("StateMachine") as StateMachine
	if sm == null:
		failures.append("Missing StateMachine on Yumi")
	else:
		for required_state in [&"Patrol", &"Chase", &"Aim", &"Stagger"]:
			if not sm.has_node(str(required_state)):
				failures.append("Missing required state node %s on Yumi" % str(required_state))

	# 4. Perception Specs
	if enemy.profile != null:
		if enemy.profile.sight_range != 400.0:
			failures.append("Expected sight_range 400.0, got %f" % enemy.profile.sight_range)
		if enemy.profile.projectile_speed != 520.0:
			failures.append("Expected projectile_speed 520.0, got %f" % enemy.profile.projectile_speed)

	enemy.free()
	return failures
