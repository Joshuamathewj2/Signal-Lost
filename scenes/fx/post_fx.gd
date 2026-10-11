class_name PostFx
extends ColorRect

@export var default_vignette_strength: float = 0.45
@export var default_vignette_radius: float = 0.75
@export var default_grain_amount: float = 0.06
@export var default_bloom_amount: float = 0.25

var ca_tween: Tween = null
var flash_tween: Tween = null
var mat: ShaderMaterial = null

func _ready() -> void:
	mat = material as ShaderMaterial
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if GameState != null and GameState.has_signal("detected"):
		GameState.detected.connect(_on_detected)

	if SceneRouter != null and SceneRouter.has_signal("level_loaded"):
		SceneRouter.level_loaded.connect(_on_level_loaded)

	if SaveData != null and SaveData.has_signal("settings_changed"):
		SaveData.settings_changed.connect(_apply_settings)
	if GameConfig != null and GameConfig.has_signal("quality_changed"):
		GameConfig.quality_changed.connect(func(_q: int) -> void: _apply_settings())

	_apply_settings()

func _on_level_loaded(root: Node) -> void:
	var player: Node = root.find_child("Player", true, false) if root != null else null
	if player == null and root != null and root.get_tree() != null:
		player = root.get_tree().get_first_node_in_group(&"player")
	if player != null:
		var charger = player.get_node_or_null("PulseCharger")
		if charger != null and charger.has_signal("pulse_released") and not charger.pulse_released.is_connected(_on_pulse_released):
			charger.pulse_released.connect(_on_pulse_released)

func _on_pulse_released(profile: PulseProfile, _origin: Vector2) -> void:
	if profile != null and profile.id == &"scream":
		burst_ca(0.012, 0.4)

func _on_detected() -> void:
	flash_frame(0.35, 0.12)
	burst_ca(0.008, 0.4)

func burst_ca(amount: float, duration: float) -> void:
	if mat == null:
		return
	if ca_tween != null and ca_tween.is_valid():
		ca_tween.kill()
	mat.set_shader_parameter(&"ca_amount", amount)
	ca_tween = create_tween()
	ca_tween.tween_method(func(v: float) -> void:
		if mat != null:
			mat.set_shader_parameter(&"ca_amount", v)
	, amount, 0.0, duration)

func flash_frame(amount: float, duration: float) -> void:
	if mat == null:
		return
	if flash_tween != null and flash_tween.is_valid():
		flash_tween.kill()
	mat.set_shader_parameter(&"flash", amount)
	flash_tween = create_tween()
	flash_tween.tween_method(func(v: float) -> void:
		if mat != null:
			mat.set_shader_parameter(&"flash", v)
	, amount, 0.0, duration)

func _apply_settings() -> void:
	if mat == null:
		return
	var grain_enabled: bool = bool(SaveData.get_setting("film_grain", true)) if SaveData != null else true
	var is_low: bool = (GameConfig != null and GameConfig.sonar_quality == 0)
	var final_grain: float = 0.0 if (not grain_enabled or is_low) else default_grain_amount
	var ca_enabled: bool = bool(SaveData.get_setting("chromatic_aberration", true)) if SaveData != null else true

	mat.set_shader_parameter(&"vignette_strength", default_vignette_strength)
	mat.set_shader_parameter(&"vignette_radius", default_vignette_radius)
	mat.set_shader_parameter(&"grain_amount", final_grain)
	mat.set_shader_parameter(&"bloom_amount", default_bloom_amount)
	if not ca_enabled:
		mat.set_shader_parameter(&"ca_amount", 0.0)

func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey:
		var ke: InputEventKey = event as InputEventKey
		if ke.pressed and not ke.echo and ke.keycode == KEY_P:
			burst_ca(0.012, 0.4)
			flash_frame(0.35, 0.12)
