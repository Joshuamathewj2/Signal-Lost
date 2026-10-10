class_name LevelComplete
extends Control

signal next_requested
signal retry_requested
signal menu_requested

@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var stats_grid: GridContainer = $CenterContainer/VBoxContainer/StatsPanel/StatsGrid
@onready var medal_glyph_control: Control = $CenterContainer/VBoxContainer/MedalContainer/MedalGlyph
@onready var medal_name_label: Label = $CenterContainer/VBoxContainer/MedalContainer/MedalNameLabel
@onready var new_best_label: Label = $CenterContainer/VBoxContainer/MedalContainer/NewBestLabel
@onready var lore_container: VBoxContainer = $CenterContainer/VBoxContainer/LoreContainer
@onready var next_button: UiButton = $CenterContainer/VBoxContainer/ButtonGroup/NextButton
@onready var retry_button: UiButton = $CenterContainer/VBoxContainer/ButtonGroup/RetryButton
@onready var menu_button: UiButton = $CenterContainer/VBoxContainer/ButtonGroup/MenuButton

var run_stats: Dictionary = {}
var save_result: Dictionary = {}
var medal_wipe_progress: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if next_button != null:
		next_button.pressed.connect(_on_next_pressed)
	if retry_button != null:
		retry_button.pressed.connect(_on_retry_pressed)
	if menu_button != null:
		menu_button.pressed.connect(_on_menu_pressed)

	_setup_focus_wrap()
	if not run_stats.is_empty():
		display_results(run_stats, save_result)

func setup(stats: Dictionary, result: Dictionary = {}) -> void:
	run_stats = stats
	save_result = result
	if is_inside_tree() and title_label != null:
		display_results(run_stats, save_result)

func display_results(stats: Dictionary, result: Dictionary) -> void:
	_animate_title()
	_populate_stats(stats)
	_animate_medal(stats, result)
	_populate_lore(stats)

func _animate_title() -> void:
	if title_label == null:
		return
	title_label.text = "SIGNAL RESTORED"
	title_label.visible_ratio = 0.0
	var char_count: int = title_label.text.length()
	var duration: float = char_count * 0.03
	var tween := create_tween()
	tween.tween_property(title_label, "visible_ratio", 1.0, duration)

func _populate_stats(stats: Dictionary) -> void:
	if stats_grid == null:
		return
	var time_val: float = float(stats.get("time", 0.0))
	var pulses: Dictionary = stats.get("pulses", {})
	var w: int = int(pulses.get("whisper", 0))
	var n: int = int(pulses.get("normal", 0))
	var s: int = int(pulses.get("scream", 0))

	var loudest_str: String = "NONE"
	var loudest_tier: int = int(stats.get("loudest", 0))
	match loudest_tier:
		0:
			loudest_str = "WHISPER" if (w > 0) else "NONE"
		1:
			loudest_str = "NORMAL"
		2:
			loudest_str = "SCREAM"

	var det: int = int(stats.get("detections", 0))
	var frags: Array = stats.get("fragments", [])

	_set_grid_val("TimeVal", "%.2f s" % time_val)
	_set_grid_val("PulsesVal", "W: %d   N: %d   S: %d" % [w, n, s])
	_set_grid_val("LoudestVal", loudest_str)
	_set_grid_val("DetectedVal", str(det))
	_set_grid_val("FragmentsVal", "%d / 3" % frags.size())

func _set_grid_val(node_name: String, text: String) -> void:
	var lbl: Label = stats_grid.get_node_or_null(node_name) as Label
	if lbl != null:
		lbl.text = text

func _animate_medal(stats: Dictionary, result: Dictionary) -> void:
	var medal: StringName = StringName(stats.get("medal", &"loud"))
	if medal_name_label != null:
		medal_name_label.text = str(medal).to_upper()
		medal_name_label.modulate.a = 0.0

	var is_new_best: bool = bool(result.get("is_new_best_medal", false))
	if new_best_label != null:
		new_best_label.visible = is_new_best
		new_best_label.modulate.a = 0.0

	medal_wipe_progress = 0.0
	var tween := create_tween()
	tween.tween_interval(0.3)
	tween.tween_property(self, "medal_wipe_progress", 1.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(medal_name_label, "modulate:a", 1.0, 0.4)
	if is_new_best and new_best_label != null:
		tween.parallel().tween_property(new_best_label, "modulate:a", 1.0, 0.4)

	if medal_glyph_control != null:
		medal_glyph_control.draw.connect(_on_draw_medal_glyph)

func _process(_delta: float) -> void:
	if medal_glyph_control != null and medal_wipe_progress < 1.0:
		medal_glyph_control.queue_redraw()

func _on_draw_medal_glyph() -> void:
	if medal_glyph_control == null:
		return
	var center := medal_glyph_control.size * 0.5
	var r: float = 24.0 * medal_wipe_progress
	if r <= 0.5:
		return

	var medal: StringName = StringName(run_stats.get("medal", &"loud"))
	var col := Palette.color(&"lit_fg")

	# Sonar ring wipe perimeter
	medal_glyph_control.draw_arc(center, r + 2.0, 0.0, TAU, 32, Palette.color(&"actor_subtle"), 1.0, true)

	match medal:
		&"ghost":
			medal_glyph_control.draw_arc(center, r, 0.0, TAU, 32, col, 2.5, true)
		&"quiet":
			var pts: PackedVector2Array = [center]
			var steps: int = 16
			for i in range(steps + 1):
				var angle: float = PI * 0.5 + PI * float(i) / float(steps)
				pts.append(center + Vector2(cos(angle), sin(angle)) * r)
			pts.append(center)
			medal_glyph_control.draw_colored_polygon(pts, col)
			medal_glyph_control.draw_arc(center, r, -PI * 0.5, PI * 0.5, 16, col, 2.5, true)
		&"loud":
			medal_glyph_control.draw_circle(center, r, col)

func _populate_lore(stats: Dictionary) -> void:
	if lore_container == null:
		return
	for child in lore_container.get_children():
		child.queue_free()

	var frags: Array = stats.get("fragments", [])
	if frags.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "NO ENCRYPTED DATA FRAGMENTS RECOVERED."
		empty_lbl.add_theme_color_override(&"font_color", Color(0.4, 0.4, 0.4))
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lore_container.add_child(empty_lbl)
		return

	var headers: Dictionary = {}
	if SceneRouter != null and SceneRouter.current_level_root != null:
		var root: LevelRoot = SceneRouter.current_level_root
		if root.level_data != null:
			headers = root.level_data.headers

	for f_idx in frags:
		var lore_text: String = str(headers.get("lore_%d" % int(f_idx), ""))
		if lore_text.is_empty():
			lore_text = "FRAGMENT #%02d AUDIO ARCHIVE: DECRYPTED SIGNAL STREAM SECURED." % (int(f_idx) + 1)
		var lbl := Label.new()
		lbl.text = lore_text
		lbl.add_theme_color_override(&"font_color", Color(0.85, 0.85, 0.85))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lore_container.add_child(lbl)

func _setup_focus_wrap() -> void:
	var buttons: Array[UiButton] = [next_button, retry_button, menu_button]
	var n: int = buttons.size()
	for i in range(n):
		if buttons[i] != null:
			var prev_btn: UiButton = buttons[(i - 1 + n) % n]
			var next_btn: UiButton = buttons[(i + 1) % n]
			buttons[i].focus_neighbor_left = buttons[i].get_path_to(prev_btn)
			buttons[i].focus_neighbor_right = buttons[i].get_path_to(next_btn)

	if next_button != null:
		next_button.grab_focus()

func _on_next_pressed() -> void:
	next_requested.emit()
	if SceneRouter != null and SceneRouter.has_method("next_level"):
		SceneRouter.next_level()
	queue_free()

func _on_retry_pressed() -> void:
	retry_requested.emit()
	if SceneRouter != null and SceneRouter.has_method("restart_level"):
		SceneRouter.restart_level()
	queue_free()

func _on_menu_pressed() -> void:
	menu_requested.emit()
	if SceneRouter != null and SceneRouter.has_method("return_to_main_menu"):
		SceneRouter.return_to_main_menu()
	queue_free()
