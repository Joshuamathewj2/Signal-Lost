class_name PulseBubble
extends Node2D

signal finished(bubble: PulseBubble)

@onready var light: PointLight2D = $Light

var active: bool = false
var age: float = 0.0
var radius: float = 0.0
var brightness: float = 0.0
var ring_alpha: float = 0.0
var profile: PulseProfile = null
var origin: Vector2 = Vector2.ZERO

func _ready() -> void:
	visible = false
	if light != null:
		light.texture = RevealTextureFactory.get_texture()
		light.blend_mode = PointLight2D.BLEND_MODE_ADD
		light.shadow_filter_smooth = 1.5
		light.range_item_cull_mask = 15
		light.shadow_item_cull_mask = 1
	_apply_quality()
	if GameConfig != null and GameConfig.has_signal("quality_changed"):
		GameConfig.quality_changed.connect(func(_q: int) -> void: _apply_quality())

func _apply_quality() -> void:
	if light == null:
		return
	var is_low: bool = (GameConfig != null and GameConfig.sonar_quality == 0)
	light.shadow_enabled = not is_low
	light.shadow_filter = PointLight2D.SHADOW_FILTER_NONE if is_low else PointLight2D.SHADOW_FILTER_PCF5

func start(p_profile: PulseProfile, p_origin: Vector2) -> void:
	profile = p_profile
	origin = p_origin
	global_position = origin
	age = 0.0
	active = true
	visible = true
	radius = 0.0
	brightness = 1.0
	ring_alpha = 1.0

	if light != null:
		light.texture_scale = 0.01
		light.energy = 1.0
		_apply_quality()

func _process(delta: float) -> void:
	if not active or profile == null:
		return

	age += delta
	var cfg: GameConfigData = GameConfig.data
	var t_exp: float = profile.expand_time()

	radius = MathUtil.wave_radius(profile.reveal_radius, age, t_exp)
	brightness = MathUtil.bubble_brightness(age, t_exp, profile.hold_time, profile.fade_time, cfg.ghost_energy, cfg.ghost_time)
	ring_alpha = MathUtil.ring_alpha(age, t_exp, cfg.ring_fade_time)

	if brightness < 0.0:
		active = false
		visible = false
		finished.emit(self)
		return

	if light != null:
		light.texture_scale = maxf(radius, 1.0) / 256.0
		light.energy = brightness
		var is_low: bool = (cfg.sonar_quality == GameConfigData.Quality.LOW)
		light.shadow_enabled = not is_low
