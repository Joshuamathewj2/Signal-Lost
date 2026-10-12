class_name PlayerVisual
extends Node2D

## PlayerVisual
## Articulated Samurai Hero (Cipher-0) vector rig:
## Kabuto helmet with crest, wide sode shoulders, flared hakama, scabbard, and flowing Verlet scarf.

const DEATH_BURST_SCENE: PackedScene = preload("res://scenes/player/death_burst.tscn")

@onready var body_polygon: Polygon2D = get_node_or_null("Body") as Polygon2D
@onready var head_polygon: Polygon2D = get_node_or_null("Head") as Polygon2D
@onready var crest_polygon: Polygon2D = get_node_or_null("Head/KabutoCrest") as Polygon2D
@onready var eye_polygon: Polygon2D = get_node_or_null("Eye") as Polygon2D
@onready var hakama_polygon: Polygon2D = get_node_or_null("Hakama") as Polygon2D
@onready var sode_l: Polygon2D = get_node_or_null("SodeL") as Polygon2D
@onready var sode_r: Polygon2D = get_node_or_null("SodeR") as Polygon2D
@onready var scabbard_line: Line2D = get_node_or_null("Scabbard") as Line2D
@onready var scarf_line: Line2D = get_node_or_null("Scarf") as Line2D
@onready var leg_l: Line2D = get_node_or_null("LegL") as Line2D
@onready var leg_r: Line2D = get_node_or_null("LegR") as Line2D
@onready var arm_l: Line2D = get_node_or_null("ArmL") as Line2D
@onready var arm_r: Line2D = get_node_or_null("ArmR") as Line2D

var current_pose: StringName = &"idle"
var current_facing: int = 1
var anim_time: float = 0.0
var walk_phase: float = 0.0
var land_tween: Tween = null
var is_dead: bool = false
var eye_state: StringName = &"normal"


func _ready() -> void:
	update_colors()
	if Palette != null and Palette.has_signal("palette_changed"):
		Palette.palette_changed.connect(update_colors)
	if GameState != null and GameState.has_signal("detected"):
		GameState.detected.connect(func() -> void: set_eye_state(&"detected"))


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
	for node in [body_polygon, head_polygon, crest_polygon, hakama_polygon, sode_l, sode_r]:
		if node != null:
			node.color = c
	for line in [scabbard_line, scarf_line, leg_l, leg_r, arm_l, arm_r]:
		if line != null:
			line.default_color = c
	set_eye_state(eye_state)


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
		&"idle": _animate_idle(delta)
		&"run": _animate_run(delta)
		&"sneak": _animate_sneak()
		&"jump", &"fall": _animate_airborne()
		&"charge": _animate_charge()
		&"attack_1", &"attack_2", &"attack_3": _animate_attack()
		&"parry", &"guard": _animate_defend()
		&"dash": _animate_dash()
		_: _reset_pose()


func _animate_idle(_delta: float) -> void:
	_reset_pose()
	var bob: float = sin(anim_time * 2.2) * 0.8
	if body_polygon != null: body_polygon.position.y = bob
	if head_polygon != null: head_polygon.position.y = bob
	if eye_polygon != null: eye_polygon.position.y = -24.0 + bob


func _animate_run(delta: float) -> void:
	_reset_pose()
	walk_phase += delta * 14.0
	var leg_ang: float = sin(walk_phase) * deg_to_rad(35.0)
	if leg_l != null: leg_l.rotation = leg_ang
	if leg_r != null: leg_r.rotation = -leg_ang
	if arm_l != null: arm_l.rotation = -leg_ang * 0.7
	if arm_r != null: arm_r.rotation = leg_ang * 0.7
	if body_polygon != null: body_polygon.position.y = absf(sin(walk_phase)) * 1.5
	rotation = deg_to_rad(7.0)


func _animate_sneak() -> void:
	_reset_pose()
	position.y = 4.0
	if body_polygon != null: body_polygon.scale.y = 0.75
	if hakama_polygon != null: hakama_polygon.scale.y = 0.8
	if scabbard_line != null: scabbard_line.rotation = deg_to_rad(15.0)


func _animate_airborne() -> void:
	_reset_pose()
	if leg_l != null: leg_l.rotation = deg_to_rad(25.0)
	if leg_r != null: leg_r.rotation = deg_to_rad(-25.0)
	if arm_l != null: arm_l.rotation = deg_to_rad(-45.0)
	if arm_r != null: arm_r.rotation = deg_to_rad(-45.0)


func _animate_charge() -> void:
	_reset_pose()
	position.x = randf_range(-0.5, 0.5)


func _animate_attack() -> void:
	_reset_pose()
	if arm_r != null: arm_r.rotation = deg_to_rad(65.0)
	if arm_l != null: arm_l.rotation = deg_to_rad(-30.0)
	rotation = deg_to_rad(10.0)


func _animate_defend() -> void:
	_reset_pose()
	if arm_r != null: arm_r.rotation = deg_to_rad(-60.0)
	if arm_l != null: arm_l.rotation = deg_to_rad(-60.0)
	position.x = -2.0


func _animate_dash() -> void:
	_reset_pose()
	rotation = deg_to_rad(25.0)
	position.y = 3.0


func _reset_pose() -> void:
	position = Vector2.ZERO
	rotation = 0.0
	for p in [body_polygon, head_polygon, hakama_polygon]:
		if p != null:
			p.position = Vector2.ZERO
			p.scale = Vector2.ONE
	if eye_polygon != null: eye_polygon.position = Vector2(2.0, -24.0)
	for l in [leg_l, leg_r, arm_l, arm_r]:
		if l != null: l.rotation = 0.0
	if scabbard_line != null: scabbard_line.rotation = 0.0


func flash() -> void:
	modulate = Color(2.0, 2.0, 2.0, 1.0)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)


func play_death() -> void:
	if is_dead:
		return
	is_dead = true
	var burst: Node2D = DEATH_BURST_SCENE.instantiate() as Node2D
	burst.global_position = global_position + Vector2(0.0, -12.0)
	get_parent().get_parent().add_child(burst)

	visible = false
