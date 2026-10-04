class_name CameraRig
extends Node2D

@export var target: Node2D
@onready var camera: Camera2D = $Camera2D

var current_lookahead: float = 0.0
var target_y: float = 0.0
var warned_trauma: bool = false
var warned_zoom: bool = false

func _ready() -> void:
	var cfg: GameConfigData = GameConfig.data
	if camera != null:
		camera.zoom = Vector2(cfg.camera_zoom, cfg.camera_zoom)
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = cfg.camera_smoothing

	if target == null:
		target = get_tree().get_first_node_in_group(&"player") as Node2D

	if target != null:
		global_position = target.global_position
		target_y = target.global_position.y

func _process(delta: float) -> void:
	if target == null:
		target = get_tree().get_first_node_in_group(&"player") as Node2D
		if target == null:
			return
		target_y = target.global_position.y

	var cfg: GameConfigData = GameConfig.data

	# Determine target facing direction
	var facing: int = 1
	var motor: PlayerMotor = target.get_node_or_null("PlayerMotor") as PlayerMotor
	if motor != null:
		facing = motor.facing
	elif "facing" in target:
		facing = target.get("facing")

	# Look-ahead (40 px, lerp 3.0/s)
	var desired_lookahead: float = float(facing) * cfg.camera_lookahead
	current_lookahead = lerpf(current_lookahead, desired_lookahead, 3.0 * delta)

	# Vertical deadzone (24 px)
	var diff_y: float = target.global_position.y - target_y
	if absf(diff_y) > 24.0:
		target_y += signf(diff_y) * (absf(diff_y) - 24.0)

	global_position = Vector2(target.global_position.x + current_lookahead, target_y)

func set_limits(rect: Rect2i) -> void:
	if camera == null:
		return
	camera.limit_left = rect.position.x
	camera.limit_top = rect.position.y
	camera.limit_right = rect.position.x + rect.size.x
	camera.limit_bottom = rect.position.y + rect.size.y

func add_trauma(_a: float) -> void:
	if not warned_trauma:
		warned_trauma = true
		push_warning("CameraRig.add_trauma is a stub until P6-T2")

func zoom_punch(_amount: float, _t_in: float, _t_out: float) -> void:
	if not warned_zoom:
		warned_zoom = true
		push_warning("CameraRig.zoom_punch is a stub until P6-T2")
