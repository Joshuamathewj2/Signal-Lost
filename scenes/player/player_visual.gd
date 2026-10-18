class_name PlayerVisual
extends Node2D

## PlayerVisual
## Articulated Samurai Hero (Cipher-0) Visual Controller:
## Primary rendering via AnimatedSprite2D with sprite frames from White_Ninja_Samurai_Sprite_Sheet.
## Features flip_h facing, speed-scaled locomotion playback, attack synchronization,
## subtle 1px rim outline for noir readability, and a toggleable fallback procedural rig in debug mode.

const DEATH_BURST_SCENE: PackedScene = preload("res://scenes/player/death_burst.tscn")
const HERO_FRAMES: SpriteFrames = preload("res://resources/sprites/hero_frames.tres")
const HERO_SHADER: Shader = preload("res://shaders/hero_silhouette.gdshader")

@export var use_sprite_art: bool = true
@export var debug_use_procedural_rig: bool = false

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

var sprite: AnimatedSprite2D = null
var weapon_line: Line2D = null
var current_weapon_type: int = 0 # 0: Katana, 1: Naginata, 2: Kunai

var current_pose: StringName = &"idle"
var current_facing: int = 1
var anim_time: float = 0.0
var walk_phase: float = 0.0
var land_tween: Tween = null
var is_dead: bool = false
var eye_state: StringName = &"normal"


func _ready() -> void:
	# Initialize AnimatedSprite2D
	sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		sprite = AnimatedSprite2D.new()
		sprite.name = "AnimatedSprite2D"
		sprite.sprite_frames = HERO_FRAMES
		sprite.scale = Vector2(0.24, 0.24)
		# Feet aligned to bottom of collision capsule (y = +5)
		sprite.position = Vector2(0.0, 5.0)
		sprite.centered = true
		sprite.offset = Vector2(0.0, -78.0)
		
		# Material with subtle rim contour
		var mat := ShaderMaterial.new()
		mat.shader = HERO_SHADER
		sprite.material = mat
		add_child(sprite)

	# Create weapon line if not present
	if get_node_or_null("WeaponLine") == null:
		weapon_line = Line2D.new()
		weapon_line.name = "WeaponLine"
		weapon_line.z_index = 6
		var mat := CanvasItemMaterial.new()
		mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		weapon_line.material = mat
		weapon_line.default_color = Color(0.9, 0.98, 1.0, 1.0)
		weapon_line.width = 2.5
		add_child(weapon_line)
	else:
		weapon_line = get_node_or_null("WeaponLine") as Line2D

	_update_rig_visibility()
	update_colors()
	_update_weapon_visual()
	set_pose(&"idle")

	if Palette != null and Palette.has_signal("palette_changed"):
		Palette.palette_changed.connect(update_colors)
	if GameState != null and GameState.has_signal("detected"):
		GameState.detected.connect(func() -> void: set_eye_state(&"detected"))


func _update_rig_visibility() -> void:
	var show_procedural: bool = debug_use_procedural_rig or not use_sprite_art
	if sprite != null:
		sprite.visible = use_sprite_art and not debug_use_procedural_rig

	# Toggle visibility of procedural shapes
	for node in [body_polygon, head_polygon, hakama_polygon, sode_l, sode_r, scabbard_line, scarf_line, leg_l, leg_r, arm_l, arm_r]:
		if node != null:
			node.visible = show_procedural
	if weapon_line != null:
		# Weapon line complements sprite or procedural rig
		weapon_line.visible = show_procedural


func set_use_sprite_art(enable: bool) -> void:
	use_sprite_art = enable
	_update_rig_visibility()


func set_weapon_type(type: int) -> void:
	current_weapon_type = type
	_update_weapon_visual()


func _update_weapon_visual() -> void:
	if weapon_line == null or not weapon_line.visible:
		return

	var is_attacking: bool = str(current_pose).begins_with("attack") or current_pose == &"heavy"

	match current_weapon_type:
		0: # KATANA
			weapon_line.width = 2.5
			weapon_line.default_color = Color(0.92, 0.98, 1.0, 1.0)
			if is_attacking:
				weapon_line.points = PackedVector2Array([Vector2(6, -14), Vector2(22, -18), Vector2(26, -16)])
			elif current_pose == &"parry" or current_pose == &"guard":
				weapon_line.points = PackedVector2Array([Vector2(2, -12), Vector2(4, -26), Vector2(3, -28)])
			else:
				weapon_line.points = PackedVector2Array([Vector2(-4, -12), Vector2(-12, -7)])
		1: # NAGINATA (52 px reach weapon)
			weapon_line.width = 3.0
			weapon_line.default_color = Color(0.85, 0.95, 1.0, 1.0)
			if is_attacking:
				weapon_line.points = PackedVector2Array([Vector2(-6, -12), Vector2(18, -16), Vector2(36, -20), Vector2(40, -24)])
			elif current_pose == &"parry" or current_pose == &"guard":
				weapon_line.points = PackedVector2Array([Vector2(0, -8), Vector2(8, -32), Vector2(10, -36)])
			else:
				weapon_line.points = PackedVector2Array([Vector2(-8, -4), Vector2(4, -20), Vector2(8, -24)])
		2: # KUNAI
			weapon_line.width = 2.0
			weapon_line.default_color = Color(0.7, 0.9, 1.0, 1.0)
			if is_attacking:
				weapon_line.points = PackedVector2Array([Vector2(6, -14), Vector2(16, -14)])
			else:
				weapon_line.points = PackedVector2Array([Vector2(4, -13), Vector2(10, -11)])


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
		if sprite != null and sprite.visible:
			sprite.flip_h = (dir < 0)
			scale.x = 1.0 # Keep root un-flipped to avoid hitbox inversions
		else:
			scale.x = 1.0 if dir > 0 else -1.0


func set_pose(pose: StringName) -> void:
	if current_pose == pose and sprite != null and sprite.is_playing():
		return
	var prev_pose: StringName = current_pose
	current_pose = pose
	_update_weapon_visual()

	if sprite != null and sprite.visible:
		_play_sprite_animation(pose)

	if pose == &"land" and prev_pose == &"fall":
		_play_land_squash()


func _play_sprite_animation(pose: StringName) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return

	var anim_name: StringName = &"idle"
	match pose:
		&"idle": anim_name = &"idle"
		&"run": anim_name = &"run"
		&"jump", &"fall": anim_name = &"jump"
		&"sneak", &"crouch": anim_name = &"crouch"
		&"attack_1", &"attack_2": anim_name = &"attack_thrust"
		&"attack_3": anim_name = &"attack_heavy"
		&"heavy": anim_name = &"attack_heavy"
		&"parry", &"guard": anim_name = &"parry"
		&"dash", &"dash_slash": anim_name = &"dash_slash"
		&"plunge": anim_name = &"plunge"
		&"rising_slash": anim_name = &"rising_slash"
		&"counter_strike": anim_name = &"counter_strike"
		&"shuriken", &"kunai_toss": anim_name = &"kunai_toss"
		&"hurt": anim_name = &"hurt"
		&"dead": anim_name = &"dead"
		&"takedown": anim_name = &"takedown"
		_:
			if sprite.sprite_frames.has_animation(pose):
				anim_name = pose
			else:
				anim_name = &"idle"

	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)


func _play_land_squash() -> void:
	if land_tween != null and land_tween.is_valid():
		land_tween.kill()
	scale = Vector2(1.25, 0.75)
	land_tween = create_tween()
	land_tween.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	if is_dead:
		return
	anim_time += delta

	# Locomotion speed scaling for AnimatedSprite2D run animation
	if sprite != null and sprite.visible and current_pose == &"run":
		var parent_body := get_parent() as CharacterBody2D
		if parent_body != null:
			var speed_ratio: float = absf(parent_body.velocity.x) / 120.0
			sprite.speed_scale = clampf(speed_ratio, 0.6, 2.0)
		else:
			sprite.speed_scale = 1.0

	# Procedural fallback animation loop
	if debug_use_procedural_rig or not use_sprite_art:
		match current_pose:
			&"idle": _animate_idle(delta)
			&"run": _animate_run(delta)
			&"sneak": _animate_sneak()
			&"jump", &"fall": _animate_airborne()
			&"charge": _animate_charge()
			&"attack_1", &"attack_2", &"attack_3": _animate_attack()
			&"heavy": _animate_heavy()
			&"parry", &"guard": _animate_defend()
			&"dash": _animate_dash()
			&"hurt": _animate_hurt()
			&"takedown": _animate_takedown()
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


func _animate_heavy() -> void:
	_reset_pose()
	if arm_r != null: arm_r.rotation = deg_to_rad(85.0)
	if arm_l != null: arm_l.rotation = deg_to_rad(45.0)
	rotation = deg_to_rad(15.0)
	position.x = 2.0


func _animate_defend() -> void:
	_reset_pose()
	if arm_r != null: arm_r.rotation = deg_to_rad(-60.0)
	if arm_l != null: arm_l.rotation = deg_to_rad(-60.0)
	position.x = -2.0


func _animate_dash() -> void:
	_reset_pose()
	rotation = deg_to_rad(25.0)
	position.y = 3.0


func _animate_hurt() -> void:
	_reset_pose()
	position.x = -4.0
	rotation = deg_to_rad(-15.0)


func _animate_takedown() -> void:
	_reset_pose()
	if arm_r != null: arm_r.rotation = deg_to_rad(75.0)
	position.x = 4.0
	rotation = deg_to_rad(12.0)


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
	if sprite != null and sprite.material is ShaderMaterial:
		var sm := sprite.material as ShaderMaterial
		sm.set_shader_parameter("flash", 1.0)
		var t := create_tween()
		t.tween_method(func(v: float) -> void: sm.set_shader_parameter("flash", v), 1.0, 0.0, 0.15)
	else:
		modulate = Color(2.0, 2.0, 2.0, 1.0)
		var tween: Tween = create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, 0.15)


func play_death() -> void:
	if is_dead:
		return
	is_dead = true
	set_pose(&"dead")

	var burst: Node2D = DEATH_BURST_SCENE.instantiate() as Node2D
	burst.global_position = global_position + Vector2(0.0, -12.0)
	if get_parent() != null and get_parent().get_parent() != null:
		get_parent().get_parent().add_child(burst)

	var t := create_tween()
	t.tween_interval(0.4)
	t.tween_property(self, "modulate:a", 0.0, 0.2)
