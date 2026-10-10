class_name MainMenu
extends Control

@onready var continue_btn: UiButton = $CenterContainer/VBoxContainer/ButtonGroup/ContinueButton
@onready var play_btn: UiButton = $CenterContainer/VBoxContainer/ButtonGroup/PlayButton
@onready var settings_btn: UiButton = $CenterContainer/VBoxContainer/ButtonGroup/SettingsButton
@onready var quit_btn: UiButton = $CenterContainer/VBoxContainer/ButtonGroup/QuitButton
@onready var title_logo: TitleLogo = $CenterContainer/VBoxContainer/TitleLogo

func _ready() -> void:
	# Check for existing save
	var can_continue: bool = false
	if SaveData != null and SaveData.has_method("has_save"):
		can_continue = SaveData.has_save()

	if continue_btn != null:
		continue_btn.visible = can_continue
		continue_btn.pressed.connect(_on_continue_pressed)

	if play_btn != null:
		play_btn.pressed.connect(_on_play_pressed)
	if settings_btn != null:
		settings_btn.pressed.connect(_on_settings_pressed)
	if quit_btn != null:
		quit_btn.pressed.connect(_on_quit_pressed)

	_setup_focus_wrap()

func _setup_focus_wrap() -> void:
	if not is_inside_tree():
		return

	var buttons: Array[UiButton] = []
	if continue_btn != null and continue_btn.visible:
		buttons.append(continue_btn)
	if play_btn != null:
		buttons.append(play_btn)
	if settings_btn != null:
		buttons.append(settings_btn)
	if quit_btn != null:
		buttons.append(quit_btn)

	var n: int = buttons.size()
	for i in range(n):
		var prev_btn: UiButton = buttons[(i - 1 + n) % n]
		var next_btn: UiButton = buttons[(i + 1) % n]
		buttons[i].focus_neighbor_top = buttons[i].get_path_to(prev_btn)
		buttons[i].focus_neighbor_bottom = buttons[i].get_path_to(next_btn)

	if not buttons.is_empty():
		buttons[0].grab_focus()

func _on_continue_pressed() -> void:
	var lvl: int = 1
	if SaveData != null and SaveData.has_method("get_continue_level"):
		lvl = SaveData.get_continue_level()
	_start_level(lvl)

func _on_play_pressed() -> void:
	_start_level(1)

const SETTINGS_SCENE: PackedScene = preload("res://scenes/ui/settings_menu.tscn")

func _on_settings_pressed() -> void:
	var settings: SettingsMenu = SETTINGS_SCENE.instantiate() as SettingsMenu
	add_child(settings)
	settings.closed.connect(func() -> void:
		if settings_btn != null and settings_btn.is_visible_in_tree():
			settings_btn.grab_focus()
	)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _start_level(level_idx: int) -> void:
	visible = false
	if SceneRouter != null and SceneRouter.has_method("load_level"):
		SceneRouter.load_level(level_idx)
	queue_free()
