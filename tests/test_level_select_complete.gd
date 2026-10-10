class_name TestLevelSelectComplete
extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []

	var tree: SceneTree = Engine.get_main_loop() as SceneTree

	SaveData.clear_level_data(1)
	SaveData.clear_level_data(2)

	# --- 1. Test SaveData medals, times, and unlocking ---
	var res1: Dictionary = SaveData.save_level_result(1, {
		"time": 30.0,
		"medal": &"quiet",
		"fragments": [0, 1],
	})

	if not bool(res1.get("is_new_best_time", false)):
		failures.append("Expected first run to be new best time")
	if not bool(res1.get("is_new_best_medal", false)):
		failures.append("Expected first run to be new best medal")

	var lvl1_data: Dictionary = SaveData.get_level_data(1)
	if StringName(lvl1_data.get("best_medal", &"none")) != &"quiet":
		failures.append("Expected best_medal to be 'quiet', got %s" % str(lvl1_data.get("best_medal")))
	if int(lvl1_data.get("fragments", 0)) != 2:
		failures.append("Expected fragments count to be 2, got %d" % int(lvl1_data.get("fragments")))
	if int(lvl1_data.get("fragments_mask", 0)) != 3:
		failures.append("Expected fragments_mask to be 3 (bits 0,1), got %d" % int(lvl1_data.get("fragments_mask")))

	# Level 2 should now be unlocked
	if not SaveData.is_level_unlocked(2):
		failures.append("Expected level 2 to be unlocked after level 1 complete")

	# Second run with worse medal and time: should not overwrite best
	var res2: Dictionary = SaveData.save_level_result(1, {
		"time": 45.0,
		"medal": &"loud",
		"fragments": [0],
	})
	if bool(res2.get("is_new_best_time", false)):
		failures.append("Worse time should not be marked as new best time")
	if bool(res2.get("is_new_best_medal", false)):
		failures.append("Worse medal should not be marked as new best medal")
	var lvl1_after: Dictionary = SaveData.get_level_data(1)
	if StringName(lvl1_after.get("best_medal", &"none")) != &"quiet":
		failures.append("Worse medal should not downgrade best_medal")

	# Third run with better medal (ghost): should improve best
	var res3: Dictionary = SaveData.save_level_result(1, {
		"time": 25.0,
		"medal": &"ghost",
		"fragments": [0, 1, 2],
	})
	if not bool(res3.get("is_new_best_medal", false)):
		failures.append("Ghost medal should improve best_medal over quiet")
	var lvl1_ghost: Dictionary = SaveData.get_level_data(1)
	if StringName(lvl1_ghost.get("best_medal", &"none")) != &"ghost":
		failures.append("Expected best_medal to be 'ghost', got %s" % str(lvl1_ghost.get("best_medal")))

	# --- 2. Test LevelSelect scene ---
	var lvl_sel_scene: PackedScene = load("res://scenes/ui/level_select.tscn")
	if lvl_sel_scene == null:
		failures.append("Failed to load res://scenes/ui/level_select.tscn")
		return failures

	var lvl_sel: Control = lvl_sel_scene.instantiate() as Control
	if lvl_sel == null:
		failures.append("Failed to instantiate LevelSelect")
		return failures

	if tree != null and tree.root != null:
		tree.root.add_child(lvl_sel)
	else:
		lvl_sel.notification(Node.NOTIFICATION_READY)

	var grid: GridContainer = lvl_sel.get_node_or_null("CenterContainer/VBoxContainer/GridContainer") as GridContainer
	if grid == null or grid.get_child_count() != 8:
		failures.append("Expected GridContainer with 8 LevelSelectBoxes, got %d" % (grid.get_child_count() if grid else -1))
	else:
		var box1: Button = grid.get_child(0) as Button
		if box1 == null or not bool(box1.get("is_unlocked")):
			failures.append("Expected box 1 to be unlocked")
		if box1 != null and StringName(box1.get("medal")) != &"ghost":
			failures.append("Expected box 1 medal to be 'ghost', got %s" % str(box1.get("medal")))

	var closed_box := [false]
	lvl_sel.connect("closed", func() -> void: closed_box[0] = true)
	lvl_sel.call("_on_back_pressed")
	if not closed_box[0]:
		failures.append("LevelSelect back button did not emit closed signal")

	# --- 3. Test LevelComplete scene ---
	var complete_scene: PackedScene = load("res://scenes/ui/level_complete.tscn")
	if complete_scene == null:
		failures.append("Failed to load res://scenes/ui/level_complete.tscn")
		return failures

	var complete: Control = complete_scene.instantiate() as Control
	if complete == null:
		failures.append("Failed to instantiate LevelComplete")
		return failures

	if tree != null and tree.root != null:
		tree.root.add_child(complete)
	else:
		complete.notification(Node.NOTIFICATION_READY)

	complete.call("setup", {
		"time": 18.42,
		"pulses": {"whisper": 3, "normal": 0, "scream": 0},
		"loudest": 0,
		"detections": 0,
		"fragments": [0, 2],
		"medal": &"ghost",
		"level_index": 1,
	}, {
		"is_new_best_time": true,
		"is_new_best_medal": true,
	})

	var next_box := [false]
	complete.connect("next_requested", func() -> void: next_box[0] = true)
	complete.call("_on_next_pressed")
	if not next_box[0]:
		failures.append("LevelComplete NEXT button did not emit next_requested")

	return failures
