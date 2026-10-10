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

	_apply_settings()

func _on_level_loaded(root: Node) -> void:
	var player: Node = root.get_tree().get_first_node_in_group(&"player")
	if player != null:
		var charger: PulseCharger = player.get_node_or_null("PulseCharger") as PulseCharger
		if charger != null and not charger.pulse_released.is_connected(_on_pulse_released):
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
	mat.set_shader_parameter(&"vignette_strength", default_vignette_strength)
	mat.set_shader_parameter(&"vignette_radius", default_vignette_radius)
	mat.set_shader_parameter(&"grain_amount", default_grain_amount)
	mat.set_shader_parameter(&"bloom_amount", default_bloom_amount)

func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey:
		var ke: InputEventKey = event as InputEventKey
		if ke.pressed and not ke.echo and ke.keycode == KEY_P:
			burst_ca(0.012, 0.4)
			flash_frame(0.35, 0.12)
