class_name TestHintSigns
extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var tree: SceneTree = Engine.get_main_loop() as SceneTree

	# --- 1. Test HintSign node and drawing ---
	var hint_scene: PackedScene = load("res://scenes/interactables/hint_sign.tscn")
	if hint_scene == null:
		failures.append("Failed to load hint_sign.tscn")
		return failures

	var sign_inst: HintSign = hint_scene.instantiate() as HintSign
	if tree != null and tree.root != null:
		tree.root.add_child(sign_inst)
	else:
		sign_inst.notification(Node.NOTIFICATION_READY)

	sign_inst.set_text("HOLD [K] / LMB")
	if sign_inst.hint_text != "HOLD [K] / LMB":
		failures.append("Expected hint_text to be 'HOLD [K] / LMB'")

	if sign_inst.material == null:
		failures.append("HintSign should have flat_reveal material")

	sign_inst.queue_free()

	# --- 2. Test Level 1 & Level 2 parsing and validation with '?' ---
	var data1: LevelData = LevelParser.parse_file("res://levels/level_01.txt")
	if data1 == null:
		failures.append("Failed to parse level_01.txt")
	else:
		if not data1.cells.has("?"):
			failures.append("level_01.txt should have '?' tile")
		else:
			var cell: Vector2i = data1.cells["?"][0]
			if cell != Vector2i(5, 9):
				failures.append("Expected '?' at (5, 9) in level_01.txt, got %s" % str(cell))
		if str(data1.headers.get("hint_0", "")) != "HOLD [K] / LMB":
			failures.append("Expected hint_0 header in level_01.txt")

		var val1: Dictionary = LevelValidator.validate(data1)
		var errs1: Array = val1.get("errors", [])
		if not errs1.is_empty():
			failures.append("level_01.txt failed validation: %s" % str(errs1))

	var data2: LevelData = LevelParser.parse_file("res://levels/level_02.txt")
	if data2 == null:
		failures.append("Failed to parse level_02.txt")
	else:
		if not data2.cells.has("?"):
			failures.append("level_02.txt should have '?' tile")
		if str(data2.headers.get("hint_0", "")) != "[SHIFT] SNEAK":
			failures.append("Expected hint_0='[SHIFT] SNEAK' in level_02.txt")

		var val2: Dictionary = LevelValidator.validate(data2)
		var errs2: Array = val2.get("errors", [])
		if not errs2.is_empty():
			failures.append("level_02.txt failed validation: %s" % str(errs2))

	# --- 3. Test InteractableSpawner spawning HintSign ---
	if data1 != null:
		var dummy_parent := Node2D.new()
		if tree != null and tree.root != null:
			tree.root.add_child(dummy_parent)

		InteractableSpawner.spawn_interactables(data1, dummy_parent, null)
		var found_hint: HintSign = null
		for child in dummy_parent.get_children():
			if child is HintSign:
				found_hint = child as HintSign
				break

		if found_hint == null:
			failures.append("Expected HintSign to be spawned by InteractableSpawner for level_01")
		elif found_hint.hint_text != "HOLD [K] / LMB":
			failures.append("Expected HintSign hint_text to be 'HOLD [K] / LMB', got '%s'" % found_hint.hint_text)

		dummy_parent.queue_free()

	return failures
