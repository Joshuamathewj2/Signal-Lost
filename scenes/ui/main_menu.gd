class_name MainMenu
extends Control

@onready var continue_btn: UiButton = $CenterContainer/VBoxContainer/ButtonGroup/ContinueButton
@onready var play_btn: UiButton = $CenterContainer/VBoxContainer/ButtonGroup/PlayButton
@onready var playground_btn: UiButton = get_node_or_null("CenterContainer/VBoxContainer/ButtonGroup/PlaygroundButton") as UiButton
@onready var atlas_btn: UiButton = get_node_or_null("CenterContainer/VBoxContainer/ButtonGroup/AtlasButton") as UiButton
@onready var arena_btn: UiButton = get_node_or_null("CenterContainer/VBoxContainer/ButtonGroup/ArenaButton") as UiButton
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
	if playground_btn != null:
		playground_btn.pressed.connect(_on_playground_pressed)
		if SaveData != null and SaveData.has_method("get_chapter_data") and bool(SaveData.get_chapter_data(2).get("completed", false)):
			playground_btn.text = "CHAPTER II: UNDERCROFT  [CLEARED]"
	if atlas_btn != null:
		atlas_btn.pressed.connect(_on_atlas_pressed)
	if arena_btn != null:
		arena_btn.pressed.connect(_on_arena_pressed)
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
	if playground_btn != null:
		buttons.append(playground_btn)
	if atlas_btn != null:
		buttons.append(atlas_btn)
	if arena_btn != null:
		buttons.append(arena_btn)
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

func _on_playground_pressed() -> void:
	visible = false
	if SceneRouter != null and SceneRouter.has_method("load_playground"):
		SceneRouter.load_playground("room_01_hub")
	queue_free()

func _on_atlas_pressed() -> void:
	visible = false
	if SceneRouter != null and SceneRouter.has_method("load_atlas_preview"):
		SceneRouter.load_atlas_preview()
	queue_free()

func _on_arena_pressed() -> void:
	visible = false
	if SceneRouter != null and SceneRouter.has_method("load_combat_arena"):
		SceneRouter.load_combat_arena()
	queue_free()

func _on_continue_pressed() -> void:
	var lvl: int = 1
	if SaveData != null and SaveData.has_method("get_continue_level"):
		lvl = SaveData.get_continue_level()
	_start_level(lvl)

const LEVEL_SELECT_SCENE: PackedScene = preload("res://scenes/ui/level_select.tscn")
const SETTINGS_SCENE: PackedScene = preload("res://scenes/ui/settings_menu.tscn")

func _on_play_pressed() -> void:
	var container: Control = get_node_or_null("CenterContainer") as Control
	if container != null:
		container.visible = false
	var lvl_sel: Node = LEVEL_SELECT_SCENE.instantiate()
	add_child(lvl_sel)
	if lvl_sel.has_signal("closed"):
		lvl_sel.connect("closed", func() -> void:
			if container != null:
				container.visible = true
			if play_btn != null and play_btn.is_visible_in_tree():
				play_btn.grab_focus()
		)
	if lvl_sel.has_signal("level_selected"):
		lvl_sel.connect("level_selected", func(_idx: int) -> void:
			queue_free()
		)

func _on_settings_pressed() -> void:
	var container: Control = get_node_or_null("CenterContainer") as Control
	if container != null:
		container.visible = false
	var settings: Node = SETTINGS_SCENE.instantiate()
	add_child(settings)
	if settings.has_signal("closed"):
		settings.connect("closed", func() -> void:
			if container != null:
				container.visible = true
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
