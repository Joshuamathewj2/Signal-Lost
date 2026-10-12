class_name TestAiAshigaru
extends RefCounted

## TestAiAshigaru
## Unit tests for Ashigaru spearman components, poise stagger, and projectile deflection.

func run() -> Array[String]:
	var failures: Array[String] = []

	var ashigaru_scene: PackedScene = load("res://scenes/enemies/ashigaru.tscn")
	if ashigaru_scene == null:
		failures.append("Failed to load res://scenes/enemies/ashigaru.tscn")
		return failures

	var enemy = ashigaru_scene.instantiate()
	if enemy == null:
		failures.append("Failed to instantiate ashigaru scene")
		return failures

	# 1. Identity & Kind
	if enemy.kind != &"ashigaru":
		failures.append("Expected kind &\"ashigaru\", got %s" % str(enemy.kind))

	# 2. Components check
	var hc: HealthComponent = enemy.get_node_or_null("HealthComponent") as HealthComponent
	if hc == null or hc.max_health != 2:
		failures.append("Expected HealthComponent with max_health 2")

	var pc: PoiseComponent = enemy.get_node_or_null("PoiseComponent") as PoiseComponent
	if pc == null or pc.max_poise != 40.0:
		failures.append("Expected PoiseComponent with max_poise 40.0")

	var hurtbox: HurtboxComponent = enemy.get_node_or_null("HurtboxComponent") as HurtboxComponent
	if hurtbox == null:
		failures.append("Missing HurtboxComponent on Ashigaru")

	# 3. State Machine check
	var sm: StateMachine = enemy.get_node_or_null("StateMachine") as StateMachine
	if sm == null:
		failures.append("Missing StateMachine on Ashigaru")
	else:
		for required_state in [&"Patrol", &"Chase", &"Thrust", &"Stagger"]:
			if not sm.has_node(str(required_state)):
				failures.append("Missing required state node %s on Ashigaru" % str(required_state))

	# 4. Poise Stagger Test
	if pc != null:
		pc.damage_poise(40.0)
		if not pc.is_staggered:
			failures.append("Ashigaru not staggered after taking 40.0 poise damage")

	# 5. Lethal Damage Test
	if hc != null:
		hc.take_damage(2)
		if hc.is_alive():
			failures.append("Ashigaru reported alive after taking 2 damage")

	# 6. Sentry Projectile Deflection Test
	var bolt := Projectile.new()
	bolt.direction = Vector2.RIGHT
	var turret := Node2D.new()
	turret.global_position = Vector2(0, 0)
	bolt.global_position = Vector2(100, 0)
	bolt.source_turret = turret

	bolt.deflect()
	if not bolt.is_deflected:
		failures.append("Projectile is_deflected is false after calling deflect()")
	if bolt.direction.x > 0.0:
		failures.append("Expected projectile direction to reverse towards turret, got %s" % str(bolt.direction))

	bolt.free()
	turret.free()
	enemy.free()

	return failures
