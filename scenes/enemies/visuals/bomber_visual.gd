class_name BomberVisual
extends Node2D

## BomberVisual
## Procedural rendering for the Bomber hostile:
## Heavy explosives satchel on back, industrial blast visor, throwing arm with live fuse glow.

const FONT: Font = preload("res://assets/fonts/Rajdhani-SemiBold.ttf")

@onready var tell_label: Label = $TellLabel
@onready var silhouette: Polygon2D = $Silhouette
@onready var satchel: Polygon2D = $Satchel
@onready var bomb_held: Polygon2D = $BombHeld
@onready var arm: Line2D = $Arm

var tell_tween: Tween = null
var flash_tween: Tween = null

func _ready() -> void:
	if tell_label != null:
		tell_label.visible = false
		tell_label.add_theme_font_override(&"font", FONT)
		tell_label.add_theme_font_size_override(&"font_size", 14)
		var mat := CanvasItemMaterial.new()
		mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		tell_label.material = mat
		tell_label.pivot_offset = Vector2(10.0, 10.0)

func show_tell(type: StringName) -> void:
	if tell_label == null:
		return
	tell_label.text = "?" if type == &"question" else "!"
	tell_label.modulate = Color(1.0, 0.4, 0.1, 1.0)
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
	if silhouette == null:
		return
	if flash_tween != null and flash_tween.is_valid():
		flash_tween.kill()
	var orig_color: Color = silhouette.color
	silhouette.color = Color.WHITE
	flash_tween = create_tween()
	flash_tween.tween_property(silhouette, "color", orig_color, 0.12)

func set_alert(val: float) -> void:
	if silhouette != null:
		silhouette.color = Color(0.4 + 0.5 * val, 0.2 + 0.1 * val, 0.1, 1.0)

func animate_throw(callback: Callable) -> void:
	if arm == null or bomb_held == null:
		if callback.is_valid():
			callback.call()
		return

	var tw := create_tween()
	# Wind-up
	tw.tween_property(arm, "rotation", -0.8, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(bomb_held, "position", Vector2(-10, -18), 0.35)
	# Release
	tw.tween_property(arm, "rotation", 0.7, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(bomb_held, "position", Vector2(12, -10), 0.15)
	tw.tween_callback(callback)
	# Reset
	tw.tween_interval(0.2)
	tw.tween_property(arm, "rotation", 0.0, 0.2)
	tw.parallel().tween_property(bomb_held, "position", Vector2(6, -12), 0.2)
