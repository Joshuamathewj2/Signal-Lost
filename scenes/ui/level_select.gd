class_name LevelSelect
extends Control

signal closed
signal level_selected(level_index: int)

const LEVEL_BOX_SCRIPT: Script = preload("res://scenes/ui/level_select_box.gd")

@onready var grid: GridContainer = $CenterContainer/VBoxContainer/GridContainer
@onready var back_button: UiButton = $CenterContainer/VBoxContainer/BackButton
@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel

var _boxes: Array[LevelSelectBox] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_populate_grid()
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)
	_setup_focus_navigation()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()

func _populate_grid() -> void:
	if grid == null:
		return

	for child in grid.get_children():
		child.queue_free()
	_boxes.clear()

	for i in range(1, 9):
		var box: LevelSelectBox = LEVEL_BOX_SCRIPT.new() as LevelSelectBox
		box.name = "LevelBox_%d" % i
		box.level_index = i

		var data: Dictionary = {}
		if SaveData != null and SaveData.has_method("get_level_data"):
			data = SaveData.get_level_data(i)

		box.is_unlocked = bool(data.get("unlocked", i == 1))
		box.medal = StringName(data.get("best_medal", &"none"))
		box.fragments_count = int(data.get("fragments", 0))

		box.level_chosen.connect(_on_level_chosen)
		grid.add_child(box)
		_boxes.append(box)

func _setup_focus_navigation() -> void:
	if not is_inside_tree():
		return

	var first_unlocked: LevelSelectBox = null

	# Setup 4x2 grid neighbors
	for row in range(2):
		for col in range(4):
			var idx: int = row * 4 + col
			if idx >= _boxes.size():
				continue
			var box: LevelSelectBox = _boxes[idx]
			if not box.is_unlocked:
				continue

			if first_unlocked == null:
				first_unlocked = box

			# Left neighbor
			for c in range(col - 1, -1, -1):
				var left_box: LevelSelectBox = _boxes[row * 4 + c]
				if left_box.is_unlocked:
					box.focus_neighbor_left = box.get_path_to(left_box)
					break

			# Right neighbor
			for c in range(col + 1, 4):
				var right_box: LevelSelectBox = _boxes[row * 4 + c]
				if right_box.is_unlocked:
					box.focus_neighbor_right = box.get_path_to(right_box)
					break

			# Up neighbor
			if row == 1:
				var up_box: LevelSelectBox = _boxes[col]
				if up_box.is_unlocked:
					box.focus_neighbor_top = box.get_path_to(up_box)

			# Down neighbor
			if row == 0:
				var down_box: LevelSelectBox = _boxes[4 + col]
				if down_box.is_unlocked:
					box.focus_neighbor_bottom = box.get_path_to(down_box)
				elif back_button != null:
					box.focus_neighbor_bottom = box.get_path_to(back_button)
			elif row == 1 and back_button != null:
				box.focus_neighbor_bottom = box.get_path_to(back_button)

	if back_button != null and first_unlocked != null:
		back_button.focus_neighbor_top = back_button.get_path_to(first_unlocked)
		back_button.focus_neighbor_bottom = back_button.get_path_to(first_unlocked)

	if first_unlocked != null:
		first_unlocked.grab_focus()
	elif back_button != null:
		back_button.grab_focus()

func _on_level_chosen(level_idx: int) -> void:
	level_selected.emit(level_idx)
	if SceneRouter != null and SceneRouter.has_method("load_level"):
		SceneRouter.load_level(level_idx)
	queue_free()

func _on_back_pressed() -> void:
	closed.emit()
	queue_free()
