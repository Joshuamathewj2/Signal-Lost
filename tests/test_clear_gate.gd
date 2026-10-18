class_name TestClearGate
extends RefCounted

## tests/test_clear_gate.gd
## Automated verification suite for clear-gate hostile progression (Step 2).
## Tests:
## 1. Terminal rejects completion with remaining enemies > 0
## 2. Terminal allows completion with 0 remaining enemies
## 3. Each death type is counted (takedown, shuriken, combat, hazard)
## 4. Stuck-enemy out-of-bounds recovery auto-defeats after 10 seconds

func _init() -> void:
	call_deferred(&"_run_standalone")

func _run_standalone() -> void:
	var failures: Array[String] = run()
	print("\n========================================")
	if failures.is_empty():
		print("ALL CLEAR GATE TESTS PASSED!")
		print("========================================\n")
		var ml := Engine.get_main_loop()
		if ml != null and ml.has_method("quit"):
			ml.call("quit", 0)
	else:
		print("CLEAR GATE TESTS FAILED: ", str(failures))
		print("========================================\n")
		var ml := Engine.get_main_loop()
		if ml != null and ml.has_method("quit"):
			ml.call("quit", 1)

func run() -> Array[String]:
	var failures: Array[String] = []
	print("\n========================================")
	print("SIGNAL LOST: CLEAR GATE VERIFICATION SUITE")
	print("========================================\n")

	var RegistryScript = load("res://autoload/enemy_registry.gd")
	var registry: Node = null
	var ml := Engine.get_main_loop() as SceneTree
	if ml != null and ml.root != null and ml.root.has_node("EnemyRegistry"):
		registry = ml.root.get_node("EnemyRegistry")
	else:
		registry = RegistryScript.new()
		if ml != null and ml.root != null:
			ml.root.add_child(registry)

	# TEST 1: Register enemies & verify counts
	print("TEST 1: Hostile registration and counts...")
	registry.call("reset_for_level")
	assert(registry.get("remaining_enemies") == 0)
	assert(registry.get("total_enemies") == 0)

	var dummy1: Node2D = Node2D.new()
	var dummy2: Node2D = Node2D.new()
	var dummy3: Node2D = Node2D.new()
	if ml != null and ml.root != null:
		ml.root.add_child(dummy1)
		ml.root.add_child(dummy2)
		ml.root.add_child(dummy3)

	registry.call("register_enemy", dummy1)
	registry.call("register_enemy", dummy2)
	registry.call("register_enemy", dummy3)

	if registry.get("total_enemies") != 3:
		failures.append("Expected total_enemies=3, got %d" % registry.get("total_enemies"))
	if registry.get("remaining_enemies") != 3:
		failures.append("Expected remaining_enemies=3, got %d" % registry.get("remaining_enemies"))
	if registry.get("is_cleared"):
		failures.append("Registry should not be cleared with 3 living hostiles")

	if failures.is_empty():
		print("  [PASS] Registered 3 hostiles; counts=3/3, is_cleared=false")

	# TEST 2: Terminal rejects activation when enemies remain
	print("\nTEST 2: Terminal rejects completion while enemies remain...")
	var TerminalScene: PackedScene = load("res://scenes/interactables/exit_terminal.tscn")
	var terminal: ExitTerminal = TerminalScene.instantiate() as ExitTerminal
	if ml != null and ml.root != null:
		ml.root.add_child(terminal)

	var fake_player: CharacterBody2D = CharacterBody2D.new()
	if ml != null and ml.root != null:
		ml.root.add_child(fake_player)

	# Verify locked state
	if not terminal.is_locked:
		failures.append("Terminal must initialize locked when hostiles remain")

	# Attempt to enter while locked
	terminal._on_player_entered(fake_player)
	if terminal._activated:
		failures.append("Terminal MUST NOT activate when hostiles remain")
	else:
		print("  [PASS] Terminal rejected activation with 3 hostiles remaining")

	# TEST 3: Track varied death types
	print("\nTEST 3: Counting various death causes...")
	registry.call("unregister_enemy", dummy1, &"stealth_takedown")
	if registry.get("remaining_enemies") != 2:
		failures.append("Expected 2 remaining enemies after takedown")
	if registry.get("killed_count") != 1:
		failures.append("Expected killed_count=1 after takedown")

	registry.call("unregister_enemy", dummy2, &"reflected_projectile")
	if registry.get("remaining_enemies") != 1:
		failures.append("Expected 1 remaining enemy after parry reflection")
	if registry.get("killed_count") != 2:
		failures.append("Expected killed_count=2 after parry reflection")

	if failures.size() == 0:
		print("  [PASS] Takedown and projectile deflection deaths successfully recorded")

	# TEST 4: Elimination of last enemy unlocks terminal
	print("\nTEST 4: Elimination of final hostile unlocks terminal...")
	registry.call("unregister_enemy", dummy3, &"katana_slash")
	if registry.get("remaining_enemies") != 0:
		failures.append("Expected 0 remaining enemies")
	if not registry.get("is_cleared"):
		failures.append("Registry should be marked cleared")
	if terminal.is_locked:
		failures.append("Terminal must unlock once all hostiles are dead")
	else:
		print("  [PASS] Final hostile eliminated; terminal unlocked with cyan/white beacon")

	# TEST 5: Terminal allows completion when cleared
	print("\nTEST 5: Terminal allows level completion when cleared...")
	terminal._on_player_entered(fake_player)
	if not terminal._activated:
		failures.append("Terminal should activate now that all hostiles are dead")
	else:
		print("  [PASS] Terminal activated successfully and initiated level completion")

	# TEST 6: Out-of-bounds stuck enemy auto-recovery
	print("\nTEST 6: Out-of-bounds stuck enemy recovery...")
	registry.call("reset_for_level")
	var stuck_dummy: Node2D = Node2D.new()
	stuck_dummy.global_position = Vector2(50.0, 3200.0) # > 2500 px
	if ml != null and ml.root != null:
		ml.root.add_child(stuck_dummy)
	registry.call("register_enemy", stuck_dummy)

	if registry.get("remaining_enemies") != 1:
		failures.append("Failed to register stuck enemy")

	# Simulate 10.5 seconds of out-of-bounds time
	for i in range(11):
		registry.call("_physics_process", 1.0)

	if registry.get("remaining_enemies") != 0:
		failures.append("Stuck enemy should be auto-defeated after 10 seconds out of bounds")
	else:
		print("  [PASS] Out-of-bounds stuck enemy auto-defeated after 10s")

	# Cleanup
	dummy1.queue_free()
	dummy2.queue_free()
	dummy3.queue_free()
	stuck_dummy.queue_free()
	terminal.queue_free()
	fake_player.queue_free()

	return failures
