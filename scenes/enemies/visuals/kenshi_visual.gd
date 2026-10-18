class_name KenshiVisual
extends Node2D

## KenshiVisual
## Ronin Sword Enemy Visual Controller:
## Primary rendering via AnimatedSprite2D using ronin_frames.tres.
## Features flip_h facing, animation playback (idle, walk, run, attack1/2/3, hurt, die, stun, evade, block),
## damage flash, parry sparks, tell label, and debug procedural rig fallback.

const FONT: Font = preload("res://assets/fonts/Rajdhani-SemiBold.ttf")
const RONIN_FRAMES: SpriteFrames = preload("res://resources/sprites/ronin_frames.tres")

@export var use_sprite_art: bool = true
@export var debug_use_procedural_rig: bool = false

@onready var tell_label: Label = get_node_or_null("TellLabel") as Label
@onready var silhouette: Polygon2D = get_node_or_null("Silhouette") as Polygon2D
@onready var cape: Polygon2D = get_node_or_null("Cape") as Polygon2D
@onready var katana: Line2D = get_node_or_null("Katana") as Line2D
@onready var parry_spark: Line2D = get_node_or_null("ParrySpark") as Line2D

var sprite: AnimatedSprite2D = null
var tell_tween: Tween = null
var flash_tween: Tween = null


func _ready() -> void:
	sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		sprite = AnimatedSprite2D.new()
		sprite.name = "AnimatedSprite2D"
		sprite.sprite_frames = RONIN_FRAMES
		sprite.scale = Vector2(0.35, 0.35)
		sprite.position = Vector2(0.0, 12.0)
		sprite.centered = true
		sprite.offset = Vector2(0.0, -45.0)
		add_child(sprite)

	if tell_label != null:
		tell_label.visible = false
		tell_label.add_theme_font_override(&"font", FONT)
		tell_label.add_theme_font_size_override(&"font_size", 14)
		var mat := CanvasItemMaterial.new()
		mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		tell_label.material = mat
		tell_label.pivot_offset = Vector2(10.0, 10.0)

	if parry_spark != null:
		parry_spark.visible = false

	_update_visibility()
	play_anim(&"idle")


func _update_visibility() -> void:
	var show_procedural: bool = debug_use_procedural_rig or not use_sprite_art
	if sprite != null:
		sprite.visible = use_sprite_art and not debug_use_procedural_rig

	for node in [silhouette, cape, katana]:
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


func show_tell(glyph: String = "!") -> void:
	if tell_label == null:
		return

	tell_label.text = glyph
	tell_label.modulate = Color(1.0, 0.1, 0.1, 1.0)
	tell_label.scale = Vector2.ZERO
	tell_label.visible = true

	if tell_tween != null and tell_tween.is_valid():
		tell_tween.kill()

	tell_tween = create_tween()
	tell_tween.tween_property(tell_label, "scale", Vector2(1.5, 1.5), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tell_tween.tween_property(tell_label, "scale", Vector2(1.0, 1.0), 0.08)
	tell_tween.tween_interval(0.4)
	tell_tween.tween_property(tell_label, "modulate:a", 0.0, 0.15)
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
	if katana != null:
		katana.default_color = Color.WHITE
	flash_tween = create_tween()
	flash_tween.tween_property(silhouette, "color", orig_color, 0.12)
	if katana != null:
		flash_tween.parallel().tween_property(katana, "default_color", Color(0.9, 0.15, 0.15, 1.0), 0.12)


func trigger_parry_spark() -> void:
	if parry_spark != null:
		parry_spark.visible = true
		parry_spark.modulate = Color(1.0, 1.0, 0.4, 1.0)
		var tw: Tween = create_tween()
		tw.tween_property(parry_spark, "modulate:a", 0.0, 0.12)
		tw.tween_callback(func() -> void:
			if parry_spark != null:
				parry_spark.visible = false
		)
	play_anim(&"block")


func set_alert(val: float) -> void:
	if silhouette != null:
		silhouette.color = Color(0.6 + 0.4 * val, 0.1 * (1.0 - val), 0.1 * (1.0 - val), 1.0)
	if sprite != null and sprite.visible:
		sprite.modulate = Color(0.85 + 0.3 * val, 0.85 - 0.2 * val, 0.85 - 0.2 * val, 1.0)
