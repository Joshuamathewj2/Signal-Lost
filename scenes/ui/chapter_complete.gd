class_name ChapterComplete
extends Control

## ChapterComplete
## End screen for Chapter II: title, run stats (time, deaths, seals), personal
## bests from SaveData, and Replay / Main Menu. Built in code so the host can
## drop it onto any CanvasLayer. Pauses the tree while open.

const FONT: Font = preload("res://assets/fonts/Rajdhani-SemiBold.ttf")
const THEME: Theme = preload("res://resources/theme/ui_theme.tres")
const RED: Color = Color(0.878, 0.0, 0.0, 1.0)

var replay_btn: Button = null
var menu_btn: Button = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = THEME
	mouse_filter = Control.MOUSE_FILTER_STOP


func _label(text: String, size: int, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override(&"font", FONT)
	l.add_theme_font_size_override(&"font_size", size)
	l.add_theme_color_override(&"font_color", color)
	return l


func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(260.0, 48.0)
	b.theme_type_variation = &"MenuButton"
	b.process_mode = Node.PROCESS_MODE_ALWAYS
	return b


func setup(stats: Dictionary, save_res: Dictionary) -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	create_tween().tween_property(bg, "color:a", 0.92, 0.6)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override(&"separation", 14)
	center.add_child(col)

	col.add_child(_label("CHAPTER II", 28, RED))
	col.add_child(_label("THE UNDERCROFT IS SILENT", 64))
	col.add_child(_label("The Leviathan has fallen. The signal carries on.", 22, Color(0.75, 0.75, 0.75)))

	var t: float = float(stats.get("time", 0.0))
	var best: float = float(save_res.get("best_time", t))
	var time_line: String = "TIME  %s" % PlaygroundHost.format_time(t)
	if bool(save_res.get("is_new_best_time", false)):
		time_line += "   NEW BEST"
	else:
		time_line += "   (BEST %s)" % PlaygroundHost.format_time(best)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 16.0)
	col.add_child(spacer)
	col.add_child(_label(time_line, 30))
	col.add_child(_label("DEATHS  %d      SEALS  %d" % [int(stats.get("deaths", 0)), int(stats.get("seals", 0))], 30))
	col.add_child(_label("CLEARS  %d" % int(save_res.get("clears", 1)), 20, Color(0.6, 0.6, 0.6)))

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0.0, 20.0)
	col.add_child(spacer2)
	var buttons := VBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override(&"separation", 12)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(buttons)
	replay_btn = _button("REPLAY CHAPTER")
	menu_btn = _button("MAIN MENU")
	buttons.add_child(replay_btn)
	buttons.add_child(menu_btn)
	replay_btn.focus_neighbor_bottom = replay_btn.get_path_to(menu_btn)
	menu_btn.focus_neighbor_top = menu_btn.get_path_to(replay_btn)
	replay_btn.pressed.connect(_on_replay)
	menu_btn.pressed.connect(_on_menu)
	replay_btn.grab_focus()

	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.8)
	get_tree().paused = true


func _on_replay() -> void:
	get_tree().paused = false
	if SceneRouter != null:
		SceneRouter.load_playground("room_01_hub")


func _on_menu() -> void:
	get_tree().paused = false
	if SceneRouter != null:
		SceneRouter.return_to_main_menu()
