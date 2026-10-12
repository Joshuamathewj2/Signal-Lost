class_name AshigaruVisual
extends Node2D

## AshigaruVisual
## Procedural rendering for the Ashigaru Spearman:
## Conical jingasa helmet, lean robotic torso, two-handed yari spear (44 px reach), red attack glint.

const FONT: Font = preload("res://assets/fonts/Rajdhani-SemiBold.ttf")

@onready var tell_label: Label = $TellLabel
@onready var silhouette: Polygon2D = $Silhouette
@onready var spear: Line2D = $Spear
@onready var spear_tip: Polygon2D = $SpearTip

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
	tell_label.modulate = Color(1.0, 0.2, 0.2, 1.0) # Red tell for attack glint
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
	if spear != null:
		spear.default_color = Color.WHITE
	flash_tween = create_tween()
	flash_tween.tween_property(silhouette, "color", orig_color, 0.12)
	if spear != null:
		flash_tween.parallel().tween_property(spear, "default_color", Color(0.8, 0.1, 0.1, 1.0), 0.12)


func set_alert(val: float) -> void:
	if silhouette != null:
		# Shift color towards intense red on high awareness
		silhouette.color = Color(0.6 + 0.4 * val, 0.1 * (1.0 - val), 0.1 * (1.0 - val), 1.0)
