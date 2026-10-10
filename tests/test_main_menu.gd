class_name TestMainMenu
extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []

	var menu_scene: PackedScene = load("res://scenes/ui/main_menu.tscn")
	if menu_scene == null:
		failures.append("main_menu.tscn failed to load")
		return failures

	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var menu: MainMenu = menu_scene.instantiate() as MainMenu
	if menu == null:
		failures.append("MainMenu failed to instantiate")
		return failures

	if tree != null and tree.root != null:
		tree.root.add_child(menu)
	else:
		menu.notification(Node.NOTIFICATION_READY)

	var title: TitleLogo = menu.get_node_or_null("CenterContainer/VBoxContainer/TitleLogo") as TitleLogo
	if title == null:
		failures.append("TitleLogo missing")
	else:
		if title.signal_label == null or title.signal_label.text != "SIGNAL":
			failures.append("SignalLabel mismatch")
		if title.lost_label == null or title.lost_label.text != "LOST":
			failures.append("LostLabel mismatch")

	var play_btn: UiButton = menu.get_node_or_null("CenterContainer/VBoxContainer/ButtonGroup/PlayButton") as UiButton
	if play_btn == null:
		failures.append("PlayButton missing or not UiButton")

	var settings_btn: UiButton = menu.get_node_or_null("CenterContainer/VBoxContainer/ButtonGroup/SettingsButton") as UiButton
	if settings_btn == null:
		failures.append("SettingsButton missing")

	var quit_btn: UiButton = menu.get_node_or_null("CenterContainer/VBoxContainer/ButtonGroup/QuitButton") as UiButton
	if quit_btn == null:
		failures.append("QuitButton missing")

	if play_btn != null and quit_btn != null and menu.is_inside_tree():
		if play_btn.focus_neighbor_top.is_empty():
			failures.append("PlayButton should have top focus neighbor configured")

	if menu.is_inside_tree():
		menu.get_parent().remove_child(menu)
	menu.free()
	return failures
