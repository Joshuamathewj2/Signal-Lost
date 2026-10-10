class_name SettingsMenu
extends Control

signal closed

@onready var master_slider: HSlider = $CenterContainer/Panel/VBoxContainer/ScrollContainer/GridContainer/MasterSlider
@onready var music_slider: HSlider = $CenterContainer/Panel/VBoxContainer/ScrollContainer/GridContainer/MusicSlider
@onready var sfx_slider: HSlider = $CenterContainer/Panel/VBoxContainer/ScrollContainer/GridContainer/SfxSlider
@onready var shake_slider: HSlider = $CenterContainer/Panel/VBoxContainer/ScrollContainer/GridContainer/ShakeSlider

@onready var grain_check: CheckButton = $CenterContainer/Panel/VBoxContainer/ScrollContainer/GridContainer/GrainCheck
@onready var ca_check: CheckButton = $CenterContainer/Panel/VBoxContainer/ScrollContainer/GridContainer/CaCheck
@onready var colorblind_check: CheckButton = $CenterContainer/Panel/VBoxContainer/ScrollContainer/GridContainer/ColorblindCheck
@onready var perf_check: CheckButton = $CenterContainer/Panel/VBoxContainer/ScrollContainer/GridContainer/PerfCheck
@onready var fullscreen_check: CheckButton = $CenterContainer/Panel/VBoxContainer/ScrollContainer/GridContainer/FullscreenCheck
@onready var quick_scream_check: CheckButton = $CenterContainer/Panel/VBoxContainer/ScrollContainer/GridContainer/QuickScreamCheck

@onready var back_btn: UiButton = $CenterContainer/Panel/VBoxContainer/BackButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_values()

	if master_slider != null:
		master_slider.value_changed.connect(_on_master_changed)
	if music_slider != null:
		music_slider.value_changed.connect(_on_music_changed)
	if sfx_slider != null:
		sfx_slider.value_changed.connect(_on_sfx_changed)
	if shake_slider != null:
		shake_slider.value_changed.connect(_on_shake_changed)

	if grain_check != null:
		grain_check.toggled.connect(_on_grain_toggled)
	if ca_check != null:
		ca_check.toggled.connect(_on_ca_toggled)
	if colorblind_check != null:
		colorblind_check.toggled.connect(_on_colorblind_toggled)
	if perf_check != null:
		perf_check.toggled.connect(_on_perf_toggled)
	if fullscreen_check != null:
		fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	if quick_scream_check != null:
		quick_scream_check.toggled.connect(_on_quick_scream_toggled)

	if back_btn != null:
		back_btn.pressed.connect(close)
		back_btn.grab_focus()

func _load_values() -> void:
	if SaveData == null:
		return
	if master_slider != null:
		master_slider.value = float(SaveData.get_setting("master_volume", 80))
	if music_slider != null:
		music_slider.value = float(SaveData.get_setting("music_volume", 70))
	if sfx_slider != null:
		sfx_slider.value = float(SaveData.get_setting("sfx_volume", 80))
	if shake_slider != null:
		shake_slider.value = float(SaveData.get_setting("screen_shake", 100))

	if grain_check != null:
		grain_check.button_pressed = bool(SaveData.get_setting("film_grain", true))
	if ca_check != null:
		ca_check.button_pressed = bool(SaveData.get_setting("chromatic_aberration", true))
	if colorblind_check != null:
		colorblind_check.button_pressed = bool(SaveData.get_setting("colorblind_mode", false))
	if perf_check != null:
		perf_check.button_pressed = bool(SaveData.get_setting("performance_mode", false))
	if fullscreen_check != null:
		fullscreen_check.button_pressed = bool(SaveData.get_setting("fullscreen", false))
	if quick_scream_check != null:
		quick_scream_check.button_pressed = bool(SaveData.get_setting("quick_scream", false))

func _on_master_changed(val: float) -> void:
	SaveData.set_setting("master_volume", int(val))
	var idx: int = AudioServer.get_bus_index(&"Master")
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear_to_db(val / 100.0) if val > 0.0 else -80.0)

func _on_music_changed(val: float) -> void:
	SaveData.set_setting("music_volume", int(val))
	var idx: int = AudioServer.get_bus_index(&"Music")
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear_to_db(val / 100.0) if val > 0.0 else -80.0)

func _on_sfx_changed(val: float) -> void:
	SaveData.set_setting("sfx_volume", int(val))
	var idx: int = AudioServer.get_bus_index(&"SFX")
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear_to_db(val / 100.0) if val > 0.0 else -80.0)

func _on_shake_changed(val: float) -> void:
	SaveData.set_setting("screen_shake", int(val))

func _on_grain_toggled(on: bool) -> void:
	SaveData.set_setting("film_grain", on)

func _on_ca_toggled(on: bool) -> void:
	SaveData.set_setting("chromatic_aberration", on)

func _on_colorblind_toggled(on: bool) -> void:
	SaveData.set_setting("colorblind_mode", on)
	if Palette != null:
		Palette.set_colorblind(on)

func _on_perf_toggled(on: bool) -> void:
	SaveData.set_setting("performance_mode", on)
	if GameConfig != null:
		GameConfig.set_sonar_quality(0 if on else 1)

func _on_fullscreen_toggled(on: bool) -> void:
	SaveData.set_setting("fullscreen", on)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)

func _on_quick_scream_toggled(on: bool) -> void:
	SaveData.set_setting("quick_scream", on)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func close() -> void:
	closed.emit()
	queue_free()
