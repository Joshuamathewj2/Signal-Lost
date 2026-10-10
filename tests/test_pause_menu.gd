class_name TestPauseMenu
extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []

	var pause_scene: PackedScene = load("res://scenes/ui/pause_menu.tscn")
	if pause_scene == null:
		failures.append("pause_menu.tscn failed to load")
		return failures

	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var pause_menu: PauseMenu = pause_scene.instantiate() as PauseMenu
	if pause_menu == null:
		failures.append("PauseMenu failed to instantiate")
		return failures

	if pause_menu.process_mode != Node.PROCESS_MODE_ALWAYS:
		failures.append("PauseMenu process_mode should be PROCESS_MODE_ALWAYS")

	if tree != null and tree.root != null:
		tree.root.add_child(pause_menu)
	else:
		pause_menu.notification(Node.NOTIFICATION_READY)

	# Test pause action
	pause_menu.pause()
	if not pause_menu.is_paused or not pause_menu.visible:
		failures.append("pause() should set is_paused and visible true")
	if tree != null and not tree.paused:
		failures.append("tree should be paused after pause()")
	if AudioManager != null and not AudioManager.is_paused_audio:
		failures.append("AudioManager should be in paused audio state")

	# Test resume action
	pause_menu.resume()
	if pause_menu.is_paused or pause_menu.visible:
		failures.append("resume() should set is_paused and visible false")
	if tree != null and tree.paused:
		failures.append("tree should not be paused after resume()")
	if AudioManager != null and AudioManager.is_paused_audio:
		failures.append("AudioManager should not be in paused audio state")

	if pause_menu.is_inside_tree():
		pause_menu.get_parent().remove_child(pause_menu)
	pause_menu.free()

	return failures
