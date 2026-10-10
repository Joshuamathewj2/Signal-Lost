class_name TestSettings
extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []

	var settings_scene: PackedScene = load("res://scenes/ui/settings_menu.tscn")
	if settings_scene == null:
		failures.append("settings_menu.tscn failed to load")
		return failures

	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var settings: SettingsMenu = settings_scene.instantiate() as SettingsMenu
	if settings == null:
		failures.append("SettingsMenu failed to instantiate")
		return failures

	if tree != null and tree.root != null:
		tree.root.add_child(settings)
	else:
		settings.notification(Node.NOTIFICATION_READY)

	# 1. Test master volume change
	settings._on_master_changed(50.0)
	var saved_master: int = int(SaveData.get_setting("master_volume", 0))
	if saved_master != 50:
		failures.append("Expected master_volume to be 50, got %d" % saved_master)

	# 2. Test colourblind mode
	settings._on_colorblind_toggled(true)
	var saved_cb: bool = bool(SaveData.get_setting("colorblind_mode", false))
	if not saved_cb:
		failures.append("Expected colorblind_mode to be true in SaveData")
	if Palette != null and not Palette.is_colorblind:
		failures.append("Expected Palette.is_colorblind to be true")

	# Restore colorblind
	settings._on_colorblind_toggled(false)

	# 3. Test quick scream option
	settings._on_quick_scream_toggled(true)
	var saved_qs: bool = bool(SaveData.get_setting("quick_scream", false))
	if not saved_qs:
		failures.append("Expected quick_scream to be true in SaveData")

	var charger := PulseCharger.new()
	charger._ready()
	if not charger.quick_scream_enabled:
		failures.append("Expected PulseCharger to have quick_scream_enabled = true")
	charger.free()

	# Restore quick scream
	settings._on_quick_scream_toggled(false)

	# 4. Test close
	var closed_box := [false]
	settings.closed.connect(func() -> void: closed_box[0] = true)
	settings.close()
	if not closed_box[0]:
		failures.append("SettingsMenu.close() did not emit closed signal")

	return failures
