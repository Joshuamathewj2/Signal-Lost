class_name UiButton
extends Button

var _ready_timestamp: int = 0

func _ready() -> void:
	_ready_timestamp = Time.get_ticks_msec()
	mouse_entered.connect(_on_mouse_entered)
	focus_entered.connect(_on_focus_entered)
	pressed.connect(_on_pressed)

func _on_mouse_entered() -> void:
	if not disabled and is_visible_in_tree():
		if Time.get_ticks_msec() - _ready_timestamp > 50:
			AudioManager.play_sfx(&"ui_move")

func _on_focus_entered() -> void:
	if not disabled and is_visible_in_tree():
		if Time.get_ticks_msec() - _ready_timestamp > 50:
			AudioManager.play_sfx(&"ui_move")

func _on_pressed() -> void:
	if not disabled:
		AudioManager.play_sfx(&"ui_select")
