class_name AshigaruVisual
extends Node2D

## AshigaruVisual
## Spearman Enemy Visual Controller:
## Primary rendering via AnimatedSprite2D using spear_frames.tres.
## Features flip_h facing, animation playback (idle, walk, run, thrust, sweep, hurt, die, stun, evade),
## damage flash, tell label, and debug procedural rig fallback.

const FONT: Font = preload("res://assets/fonts/Rajdhani-SemiBold.ttf")
const SPEAR_FRAMES: SpriteFrames = preload("res://resources/sprites/spear_frames.tres")

@export var use_sprite_art: bool = true
@export var debug_use_procedural_rig: bool = false

@onready var tell_label: Label = get_node_or_null("TellLabel") as Label
@onready var silhouette: Polygon2D = get_node_or_null("Silhouette") as Polygon2D
@onready var spear: Line2D = get_node_or_null("Spear") as Line2D
@onready var spear_tip: Polygon2D = get_node_or_null("SpearTip") as Polygon2D

var sprite: AnimatedSprite2D = null
var tell_tween: Tween = null
var flash_tween: Tween = null


func _ready() -> void:
	sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		sprite = AnimatedSprite2D.new()
		sprite.name = "AnimatedSprite2D"
		sprite.sprite_frames = SPEAR_FRAMES
		sprite.scale = Vector2(0.35, 0.35)
		sprite.position = Vector2(0.0, 12.0)
		sprite.centered = true
		sprite.offset = Vector2(0.0, -48.0)
		add_child(sprite)

	if tell_label != null:
		tell_label.visible = false
		tell_label.add_theme_font_override(&"font", FONT)
		tell_label.add_theme_font_size_override(&"font_size", 14)
		var mat := CanvasItemMaterial.new()
		mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		tell_label.material = mat
		tell_label.pivot_offset = Vector2(10.0, 10.0)

	_update_visibility()
	play_anim(&"idle")


func _update_visibility() -> void:
	var show_procedural: bool = debug_use_procedural_rig or not use_sprite_art
	if sprite != null:
		sprite.visible = use_sprite_art and not debug_use_procedural_rig

	for node in [silhouette, spear, spear_tip]:
		if node != null:
			node.visible = show_procedural


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


func show_tell(type: StringName) -> void:
	if tell_label == null:
		return

	tell_label.text = "?" if type == &"question" else "!"
	tell_label.modulate = Color(1.0, 0.2, 0.2, 1.0)
	tell_label.scale = Vector2.ZERO
	tell_label.visible = true

	if tell_tween != null and tell_tween.is_valid():
		tell_tween.kill()

	tell_tween = create_tween()
	tell_tween.tween_property(tell_label, "scale", Vector2(1.4, 1.4), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tell_tween.tween_property(tell_label, "scale", Vector2(1.0, 1.0), 0.08)
	tell_tween.tween_interval(0.5)
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

	if silhouette == null:
		return
	if flash_tween != null and flash_tween.is_valid():
		flash_tween.kill()
	var orig_color: Color = silhouette.color
	silhouette.color = Color.WHITE
	if spear != null:
		spear.default_color = Color.WHITE
	flash_tween = create_tween()
	flash_tween.tween_property(silhouette, "color", orig_color, 0.12)
	if spear != null:
		flash_tween.parallel().tween_property(spear, "default_color", Color(0.8, 0.1, 0.1, 1.0), 0.12)


func set_alert(val: float) -> void:
	if silhouette != null:
		silhouette.color = Color(0.6 + 0.4 * val, 0.1 * (1.0 - val), 0.1 * (1.0 - val), 1.0)
	if sprite != null and sprite.visible:
		sprite.modulate = Color(0.85 + 0.3 * val, 0.85 - 0.2 * val, 0.85 - 0.2 * val, 1.0)
