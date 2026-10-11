class_name PlayerVisual
extends Node2D

const DEATH_BURST_SCENE: PackedScene = preload("res://scenes/player/death_burst.tscn")

@onready var body_polygon: Polygon2D = $Body
@onready var head_polygon: Polygon2D = $Head
@onready var eye_polygon: Polygon2D = $Eye
@onready var antenna_line: Line2D = $Antenna
@onready var antenna_tip: Polygon2D = $Antenna/AntennaTip
@onready var leg_l: Line2D = $LegL
@onready var leg_r: Line2D = $LegR
@onready var arm_l: Line2D = $ArmL
@onready var arm_r: Line2D = $ArmR

var current_pose: StringName = &"idle"
var current_facing: int = 1
var anim_time: float = 0.0
var walk_phase: float = 0.0
var land_tween: Tween = null
var is_dead: bool = false

func _ready() -> void:
	update_colors()
	if Palette != null and Palette.has_signal("palette_changed"):
		Palette.palette_changed.connect(update_colors)
	if GameState != null and GameState.has_signal("detected"):
		GameState.detected.connect(func() -> void:
			set_eye_state(&"detected")
		)

var eye_state: StringName = &"normal"

func set_eye_state(state: StringName) -> void:
	eye_state = state
	if eye_polygon == null:
		return
	match state:
		&"charge":
			eye_polygon.color = Palette.color(&"arc") if Palette != null else Color(0.2, 0.9, 1.0, 1.0)
		&"detected":
			eye_polygon.color = Palette.color(&"danger") if Palette != null else Color(1.0, 0.2, 0.2, 1.0)
			var t := create_tween()
			t.tween_interval(1.5)
			t.tween_callback(func() -> void:
				if eye_state == &"detected":
					set_eye_state(&"normal")
			)
		_:
			eye_polygon.color = Palette.color(&"white") if Palette != null else Color.WHITE

func update_colors() -> void:
	var c: Color = Palette.color(&"white") if Palette != null else Color.WHITE
	if body_polygon != null:
		body_polygon.color = c
	if head_polygon != null:
		head_polygon.color = c
	set_eye_state(eye_state)
	if antenna_line != null:
		antenna_line.default_color = c
	if antenna_tip != null:
		antenna_tip.color = c
	if leg_l != null:
		leg_l.default_color = c
	if leg_r != null:
		leg_r.default_color = c
	if arm_l != null:
		arm_l.default_color = c
	if arm_r != null:
		arm_r.default_color = c

func set_facing(dir: int) -> void:
	if dir != 0:
		current_facing = dir
		scale.x = 1.0 if dir > 0 else -1.0

func set_pose(pose: StringName) -> void:
	if current_pose == pose:
		return
	var prev_pose: StringName = current_pose
	current_pose = pose

	if pose == &"land" and prev_pose == &"fall":
		_play_land_squash()

func _play_land_squash() -> void:
	if land_tween != null and land_tween.is_valid():
		land_tween.kill()
	scale = Vector2(scale.x * 1.25, 0.75)
	land_tween = create_tween()
	land_tween.tween_property(self, "scale", Vector2(1.0 if current_facing > 0 else -1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	if is_dead:
		return

	anim_time += delta

	match current_pose:
		&"idle":
			_animate_idle(delta)
		&"run":
			_animate_run(delta)
		&"sneak":
			_animate_sneak()
		&"jump":
			_animate_jump()
		&"fall":
			_animate_fall()
		&"charge":
			_animate_charge()
		_:
			_reset_pose()

func _animate_idle(_delta: float) -> void:
	_reset_pose()
	if body_polygon != null:
		body_polygon.position.y = sin(anim_time * 2.2) * 0.6
	if head_polygon != null:
		head_polygon.position.y = sin(anim_time * 2.2) * 0.6
	if eye_polygon != null:
		eye_polygon.position.y = -23.0 + sin(anim_time * 2.2) * 0.6
	if antenna_line != null:
		antenna_line.rotation = sin(anim_time * 3.1) * deg_to_rad(4.0)

func _animate_run(delta: float) -> void:
	_reset_pose()
	walk_phase += delta * 14.0
	var leg_angle: float = sin(walk_phase) * deg_to_rad(35.0)
	if leg_l != null:
		leg_l.rotation = leg_angle
	if leg_r != null:
		leg_r.rotation = -leg_angle
	if arm_l != null:
		arm_l.rotation = -leg_angle * 0.7
	if arm_r != null:
		arm_r.rotation = leg_angle * 0.7
	if body_polygon != null:
		body_polygon.position.y = absf(sin(walk_phase)) * 1.2
	rotation = deg_to_rad(6.0)

func _animate_sneak() -> void:
	_reset_pose()
	position.y = 4.0
	if body_polygon != null:
		body_polygon.scale.y = 0.7
	if antenna_line != null:
		antenna_line.rotation = deg_to_rad(-30.0)

func _animate_jump() -> void:
	_reset_pose()
	if leg_l != null:
		leg_l.rotation = deg_to_rad(20.0)
	if leg_r != null:
		leg_r.rotation = deg_to_rad(-20.0)
	if arm_l != null:
		arm_l.rotation = deg_to_rad(-40.0)
	if arm_r != null:
		arm_r.rotation = deg_to_rad(-40.0)

func _animate_fall() -> void:
	_reset_pose()
	if leg_l != null:
		leg_l.rotation = deg_to_rad(20.0)
	if leg_r != null:
		leg_r.rotation = deg_to_rad(-20.0)
	if arm_l != null:
		arm_l.rotation = deg_to_rad(-40.0)
	if arm_r != null:
		arm_r.rotation = deg_to_rad(-40.0)

func _animate_charge() -> void:
	_reset_pose()
	if antenna_tip != null:
		var s: float = 1.0 + 0.3 * sin(anim_time * 20.0)
		antenna_tip.scale = Vector2(s, s)
	position.x = randf_range(-0.5, 0.5)

func _reset_pose() -> void:
	position = Vector2.ZERO
	rotation = 0.0
	if body_polygon != null:
		body_polygon.position = Vector2.ZERO
		body_polygon.scale = Vector2.ONE
	if head_polygon != null:
		head_polygon.position = Vector2.ZERO
	if eye_polygon != null:
		eye_polygon.position = Vector2(2.0, -23.0)
	if antenna_line != null:
		antenna_line.rotation = 0.0
	if antenna_tip != null:
		antenna_tip.scale = Vector2.ONE
	if leg_l != null:
		leg_l.rotation = 0.0
	if leg_r != null:
		leg_r.rotation = 0.0
	if arm_l != null:
		arm_l.rotation = 0.0
	if arm_r != null:
		arm_r.rotation = 0.0

func set_alert(_v: float) -> void:
	pass

func flash() -> void:
	modulate = Color(2.0, 2.0, 2.0, 1.0)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)

func play_death() -> void:
	if is_dead:
		return
	is_dead = true

	# Spawn death burst particles
	var burst: Node2D = DEATH_BURST_SCENE.instantiate() as Node2D
	burst.global_position = global_position + Vector2(0.0, -12.0)
	get_parent().get_parent().add_child(burst)

	# Hide body parts, eye lingers 0.3s then pops
	if body_polygon != null:
		body_polygon.visible = false
	if head_polygon != null:
		head_polygon.visible = false
	if antenna_line != null:
		antenna_line.visible = false
	if leg_l != null:
		leg_l.visible = false
	if leg_r != null:
		leg_r.visible = false
	if arm_l != null:
		arm_l.visible = false
	if arm_r != null:
		arm_r.visible = false

	if eye_polygon != null:
		var t := create_tween()
		t.tween_interval(0.3)
		t.tween_property(eye_polygon, "scale", Vector2(1.8, 1.8), 0.06)
		t.tween_callback(func() -> void:
			if eye_polygon != null:
				eye_polygon.visible = false
		)
