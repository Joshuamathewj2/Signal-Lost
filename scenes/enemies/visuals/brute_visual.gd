class_name BruteVisual
extends Node2D

## BruteVisual
## Heavy Enemy (Brute) Visual Controller:
## Primary rendering via AnimatedSprite2D using brute_frames.tres.
## Features flip_h facing, animation playback (idle, walk, run, smash, swing, hurt, die, stun, enrage),
## damage flash, tell label, and debug procedural rig fallback.

const FONT: Font = preload("res://assets/fonts/Rajdhani-SemiBold.ttf")
const BRUTE_FRAMES: SpriteFrames = preload("res://resources/sprites/brute_frames.tres")

@export var use_sprite_art: bool = true
@export var debug_use_procedural_rig: bool = false

@onready var poly: Polygon2D = get_node_or_null("Silhouette") as Polygon2D
@onready var tell_label: Label = get_node_or_null("TellLabel") as Label

var sprite: AnimatedSprite2D = null
var tell_tween: Tween = null
var stun_timer: float = 0.0
var original_poly_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		sprite = AnimatedSprite2D.new()
		sprite.name = "AnimatedSprite2D"
		sprite.sprite_frames = BRUTE_FRAMES
		sprite.scale = Vector2(0.40, 0.40)
		sprite.position = Vector2(0.0, 12.0)
		sprite.centered = true
		sprite.offset = Vector2(0.0, -60.0)
		add_child(sprite)

	if tell_label != null:
		tell_label.visible = false
		tell_label.add_theme_font_override(&"font", FONT)
		tell_label.add_theme_font_size_override(&"font_size", 14)
		var mat := CanvasItemMaterial.new()
		mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		tell_label.material = mat
		tell_label.pivot_offset = Vector2(10.0, 10.0)

	if poly != null:
		original_poly_pos = poly.position

	_update_visibility()
	play_anim(&"idle")


func _update_visibility() -> void:
	var show_procedural: bool = debug_use_procedural_rig or not use_sprite_art
	if sprite != null:
		sprite.visible = use_sprite_art and not debug_use_procedural_rig

	if poly != null:
		poly.visible = show_procedural


func set_facing(dir: int) -> void:
	if sprite != null and sprite.visible:
		sprite.flip_h = (dir < 0)
	else:
		scale.x = 1.0 if dir > 0 else -1.0


func play_anim(anim_name: StringName) -> void:
	if sprite == null or sprite.sprite_frames == null or not sprite.visible:
		return
	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
	elif anim_name == &"hurt":
		if sprite.sprite_frames.has_animation(&"hurt"):
			sprite.play(&"hurt")
	elif anim_name == &"die":
		if sprite.sprite_frames.has_animation(&"die"):
			sprite.play(&"die")


func _process(delta: float) -> void:
	if stun_timer > 0.0:
		stun_timer -= delta
		if poly != null:
			poly.rotation = sin(stun_timer * TAU * 10.0) * deg_to_rad(8.0)
		if stun_timer <= 0.0:
			stun_timer = 0.0
			if poly != null:
				poly.rotation = 0.0
				poly.position = original_poly_pos


func show_tell(type: StringName) -> void:
	if tell_label == null:
		return

	tell_label.text = "?" if type == &"question" else "!"
	tell_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	tell_label.scale = Vector2.ZERO
	tell_label.visible = true

	if tell_tween != null and tell_tween.is_valid():
		tell_tween.kill()

	tell_tween = create_tween()
	tell_tween.tween_property(tell_label, "scale", Vector2(1.3, 1.3), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tell_tween.tween_property(tell_label, "scale", Vector2(1.0, 1.0), 0.08)
	tell_tween.tween_interval(0.6)
	tell_tween.tween_property(tell_label, "modulate:a", 0.0, 0.2)
	tell_tween.tween_callback(func() -> void:
		if tell_label != null:
			tell_label.visible = false
	)

	flash()


func flash() -> void:
	if sprite != null and sprite.visible:
		var orig_mod: Color = sprite.modulate
		sprite.modulate = Color(2.5, 2.5, 2.5, 1.0)
		var tw := create_tween()
		tw.tween_property(sprite, "modulate", orig_mod, 0.12)
		return

	if poly == null:
		return
	var orig_color: Color = poly.color
	poly.color = Color.WHITE
	var tw: Tween = create_tween()
	tw.tween_property(poly, "color", orig_color, 0.12)


func trigger_stun(duration: float) -> void:
	stun_timer = duration
	play_anim(&"stun")


func set_alert(val: float) -> void:
	if poly != null:
		poly.color = Color(0.7 + 0.3 * val, 0.1 * (1.0 - val), 0.1 * (1.0 - val), 1.0)
	if sprite != null and sprite.visible:
		sprite.modulate = Color(0.85 + 0.3 * val, 0.85 - 0.2 * val, 0.85 - 0.2 * val, 1.0)
