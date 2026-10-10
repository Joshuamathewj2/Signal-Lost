class_name PauseMenu
extends Control

@onready var resume_btn: UiButton = $CenterContainer/VBoxContainer/ButtonGroup/ResumeButton
@onready var restart_btn: UiButton = $CenterContainer/VBoxContainer/ButtonGroup/RestartButton
@onready var settings_btn: UiButton = $CenterContainer/VBoxContainer/ButtonGroup/SettingsButton
@onready var quit_btn: UiButton = $CenterContainer/VBoxContainer/ButtonGroup/QuitButton

var is_paused: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	if resume_btn != null:
		resume_btn.pressed.connect(resume)
	if restart_btn != null:
		restart_btn.pressed.connect(_on_restart_pressed)
	if settings_btn != null:
		settings_btn.pressed.connect(_on_settings_pressed)
	if quit_btn != null:
		quit_btn.pressed.connect(_on_quit_pressed)

	_setup_focus_wrap()

func _setup_focus_wrap() -> void:
	var buttons: Array[UiButton] = [resume_btn, restart_btn, settings_btn, quit_btn]
	var n: int = buttons.size()
	for i in range(n):
		if buttons[i] != null:
			var prev_btn: UiButton = buttons[(i - 1 + n) % n]
			var next_btn: UiButton = buttons[(i + 1) % n]
			if prev_btn != null:
				buttons[i].focus_neighbor_top = buttons[i].get_path_to(prev_btn)
			if next_btn != null:
				buttons[i].focus_neighbor_bottom = buttons[i].get_path_to(next_btn)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if is_paused:
			resume()
			get_viewport().set_input_as_handled()
		else:
			var has_level: bool = false
			if SceneRouter != null and "current_level_root" in SceneRouter and SceneRouter.current_level_root != null:
				has_level = true
			var main_menu: Node = get_tree().get_first_node_in_group(&"main_menu")
			if main_menu != null and main_menu.is_visible_in_tree():
				has_level = false

			if has_level:
				pause()
				get_viewport().set_input_as_handled()

func pause() -> void:
	is_paused = true
	visible = true
	get_tree().paused = true
	if AudioManager != null and AudioManager.has_method("set_pause_mute"):
		AudioManager.set_pause_mute(true)
	if resume_btn != null:
		resume_btn.grab_focus()

func resume() -> void:
	is_paused = false
	visible = false
	get_tree().paused = false
	if AudioManager != null and AudioManager.has_method("set_pause_mute"):
		AudioManager.set_pause_mute(false)

func _on_restart_pressed() -> void:
	resume()
	if SceneRouter != null and SceneRouter.has_method("restart_level"):
		SceneRouter.restart_level()

func _on_settings_pressed() -> void:
	pass

func _on_quit_pressed() -> void:
	resume()
	var main_node: Node = get_tree().root.get_node_or_null("Main")
	if main_node != null and main_node.has_method("show_main_menu"):
		if SceneRouter != null and "current_level_root" in SceneRouter and SceneRouter.current_level_root != null:
			SceneRouter.current_level_root.queue_free()
			SceneRouter.current_level_root = null
		main_node.call("show_main_menu")
