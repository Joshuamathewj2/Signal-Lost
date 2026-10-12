class_name CameraRig
extends Node2D

@export var target: Node2D
@onready var camera: Camera2D = $Camera2D

var current_lookahead: float = 0.0
var target_y: float = 0.0
var trauma: float = 0.0
var shake_time: float = 0.0
var zoom_tween: Tween = null
var base_zoom: float = 1.8
var current_target_zoom: float = 1.8

func _ready() -> void:
	add_to_group(&"camera_rig")
	var cfg: GameConfigData = GameConfig.data
	base_zoom = 1.8
	current_target_zoom = 1.8
	if camera != null:
		camera.zoom = Vector2(1.8, 1.8)
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = cfg.camera_smoothing if cfg != null else 6.0

	if target == null:
		target = get_tree().get_first_node_in_group(&"player") as Node2D

	if target != null:
		global_position = target.global_position
		target_y = target.global_position.y
		_connect_player(target)

	if GameState != null and GameState.has_signal("detected"):
		GameState.detected.connect(_on_detected)

	if SceneRouter != null and SceneRouter.has_signal("level_loaded"):
		SceneRouter.level_loaded.connect(_on_level_loaded)

func _on_level_loaded(root: Node) -> void:
	var p: Node2D = root.find_child("Player", true, false) as Node2D if root != null else null
	if p == null and is_inside_tree():
		p = get_tree().get_first_node_in_group(&"player") as Node2D
	if p != null:
		target = p
		global_position = p.global_position
		target_y = p.global_position.y
		_connect_player(p)

func _connect_player(p: Node) -> void:
	if p == null:
		return
	var charger = p.get_node_or_null("PulseCharger")
	if charger != null and charger.has_signal("pulse_released") and not charger.pulse_released.is_connected(_on_pulse_released):
		charger.pulse_released.connect(_on_pulse_released)

	if p.has_signal("player_died") and not p.player_died.is_connected(_on_player_died):
		p.player_died.connect(_on_player_died)

func _on_pulse_released(profile: PulseProfile, _origin: Vector2) -> void:
	if profile == null:
		return
	if profile.id == &"normal":
		add_trauma(0.2)
	elif profile.id == &"scream":
		add_trauma(0.9)
		zoom_punch(base_zoom * 1.06, 0.15, 0.5)

func _on_detected() -> void:
	zoom_punch(base_zoom * 1.03, 0.15, 0.15)

func _on_player_died(_cause: StringName) -> void:
	add_trauma(0.6)
	HitStop.freeze(get_tree(), 0.08)

func _process(delta: float) -> void:
	if target == null:
		target = get_tree().get_first_node_in_group(&"player") as Node2D
		if target == null:
			return
		target_y = target.global_position.y
		_connect_player(target)

	var cfg: GameConfigData = GameConfig.data

	# Look-ahead (40 px, lerp 3.0/s)
	var facing: int = 1
	var motor: PlayerMotor = target.get_node_or_null("PlayerMotor") as PlayerMotor
	if motor != null:
		facing = motor.facing
	elif "facing" in target:
		facing = target.get("facing")

	var lookahead_dist: float = 48.0
	var desired_lookahead: float = float(facing) * lookahead_dist
	current_lookahead = lerpf(current_lookahead, desired_lookahead, 3.0 * delta)

	# Dynamic combat zoom (1.8x base, 1.45x combat)
	var combat_ctrl = target.get_node_or_null("CombatController")
	var in_combat: bool = false
	if combat_ctrl != null:
		var c_state = combat_ctrl.get("current_state")
		if c_state != null and int(c_state) != 0:
			in_combat = true

	var target_zoom_val: float = 1.45 if in_combat else 1.8
	if zoom_tween == null or not zoom_tween.is_valid():
		current_target_zoom = lerpf(current_target_zoom, target_zoom_val, 2.5 * delta)
		if camera != null:
			camera.zoom = Vector2(current_target_zoom, current_target_zoom)

	# Vertical deadzone (24 px)
	var diff_y: float = target.global_position.y - target_y
	if absf(diff_y) > 24.0:
		target_y += signf(diff_y) * (absf(diff_y) - 24.0)

	global_position = Vector2(target.global_position.x + current_lookahead, target_y)

	# Shake calculation
	if trauma > 0.0:
		trauma = maxf(0.0, trauma - 1.5 * delta)
		shake_time += delta * 25.0
		var shake_amount: float = trauma * trauma
		var offset_x: float = sin(shake_time) * 10.0 * shake_amount
		var offset_y: float = cos(shake_time * 1.3) * 10.0 * shake_amount
		if camera != null:
			camera.offset = Vector2(offset_x, offset_y)
	else:
		if camera != null and camera.offset != Vector2.ZERO:
			camera.offset = Vector2.ZERO

func set_limits(rect: Rect2i) -> void:
	if camera == null:
		return
	camera.limit_left = rect.position.x
	camera.limit_top = rect.position.y
	camera.limit_right = rect.position.x + rect.size.x
	camera.limit_bottom = rect.position.y + rect.size.y

func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)

func zoom_punch(target_zoom_val: float, t_in: float, t_out: float) -> void:
	if camera == null:
		return
	if zoom_tween != null and zoom_tween.is_valid():
		zoom_tween.kill()

	zoom_tween = create_tween()
	zoom_tween.tween_property(camera, "zoom", Vector2(target_zoom_val, target_zoom_val), t_in).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	zoom_tween.tween_property(camera, "zoom", Vector2(base_zoom, base_zoom), t_out).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
