class_name ChargeRings
extends Node2D

@export var charger: PulseCharger

var current_reveal_radius: float = 0.0
var target_reveal_radius: float = 0.0
var current_noise_radius: float = 0.0
var target_noise_radius: float = 0.0
var is_downgraded: bool = false
var rotation_angle: float = 0.0
var tween: Tween

func _ready() -> void:
	visible = false
	var mat: CanvasItemMaterial = CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = mat

	if charger == null and get_parent() != null:
		charger = get_parent().get_node_or_null("PulseCharger") as PulseCharger

	if charger != null:
		charger.charge_started.connect(_on_charge_started)
		charger.charge_changed.connect(_on_charge_changed)
		charger.pulse_released.connect(_on_pulse_ended)
		charger.pulse_failed.connect(_on_pulse_failed)

func _process(delta: float) -> void:
	if visible:
		rotation_angle += deg_to_rad(20.0) * delta
		if rotation_angle > TAU:
			rotation_angle -= TAU
		queue_redraw()

func _on_charge_started() -> void:
	visible = true
	current_reveal_radius = 0.0
	target_reveal_radius = 0.0
	current_noise_radius = 0.0
	target_noise_radius = 0.0
	is_downgraded = false
	queue_redraw()

func _on_charge_changed(tier: int, _charge_norm: float, affordable_tier: int) -> void:
	var active_tier: int = affordable_tier if affordable_tier >= 0 else tier
	is_downgraded = (affordable_tier >= 0 and affordable_tier < tier)
	var prof: PulseProfile = GameConfig.pulse_for_tier(active_tier)
	if prof != null:
		var n_scale: float = charger.noise_scale if charger != null else 1.0
		target_reveal_radius = prof.reveal_radius
		target_noise_radius = prof.noise_radius() * n_scale

		if tween != null and tween.is_valid():
			tween.kill()
		tween = create_tween().set_parallel(true)
		tween.tween_property(self, "current_reveal_radius", target_reveal_radius, 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "current_noise_radius", target_noise_radius, 0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	queue_redraw()

func _on_pulse_ended(_profile: PulseProfile, _origin: Vector2) -> void:
	visible = false
	if tween != null and tween.is_valid():
		tween.kill()

func _on_pulse_failed() -> void:
	visible = false
	if tween != null and tween.is_valid():
		tween.kill()

func _draw() -> void:
	if not visible or current_reveal_radius <= 1.0:
		return

	var white_c: Color = Palette.color(&"white")
	var danger_c: Color = Palette.color(&"danger")
	var red_c: Color = Color(danger_c.r, danger_c.g, danger_c.b, 0.6)

	# White reveal ring
	if is_downgraded:
		var segments: int = 12
		var angle_step: float = TAU / float(segments)
		var dash_len: float = angle_step * 0.6
		for i in range(segments):
			var a_start: float = float(i) * angle_step
			draw_arc(Vector2.ZERO, current_reveal_radius, a_start, a_start + dash_len, 6, white_c, 1.5)
	else:
		draw_arc(Vector2.ZERO, current_reveal_radius, 0.0, TAU, 64, white_c, 1.5)

	# Red noise ring (dashed, rotating)
	var noise_segments: int = 16
	var n_step: float = TAU / float(noise_segments)
	var n_dash: float = n_step * 0.5
	for i in range(noise_segments):
		var a: float = rotation_angle + float(i) * n_step
		draw_arc(Vector2.ZERO, current_noise_radius, a, a + n_dash, 6, red_c, 1.0)
