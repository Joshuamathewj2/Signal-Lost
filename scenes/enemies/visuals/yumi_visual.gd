class_name YumiVisual
extends Node2D

## YumiVisual
## Procedural rendering for the Yumi Balcony Archer:
## Hooded crouching silhouette, asymmetrical acoustic longbow,
## and dynamic aiming laser sight line.

const FONT: Font = preload("res://assets/fonts/Rajdhani-SemiBold.ttf")

@onready var tell_label: Label = $TellLabel
@onready var silhouette: Polygon2D = $Silhouette
@onready var bow: Line2D = $Bow
@onready var laser_sight: Line2D = $LaserSight

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

	if laser_sight != null:
		laser_sight.visible = false


func set_aim_target(target_local: Vector2, charging_progress: float) -> void:
	if laser_sight == null:
		return

	laser_sight.visible = true
	laser_sight.points = PackedVector2Array([Vector2.ZERO, target_local])
	# Laser pulses from faint red to intense solid red as charge approaches 1.0
	laser_sight.default_color = Color(1.0, 0.1, 0.1, 0.3 + 0.7 * charging_progress)
	laser_sight.width = 1.0 + 1.5 * charging_progress


func stop_aim() -> void:
	if laser_sight != null:
		laser_sight.visible = false


func show_tell(glyph: String = "!") -> void:
	if tell_label == null:
		return

	tell_label.text = glyph
	tell_label.modulate = Color(1.0, 0.2, 0.2, 1.0)
	tell_label.scale = Vector2.ZERO
	tell_label.visible = true

	if tell_tween != null and tell_tween.is_valid():
		tell_tween.kill()

	tell_tween = create_tween()
	tell_tween.tween_property(tell_label, "scale", Vector2(1.4, 1.4), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tell_tween.tween_property(tell_label, "scale", Vector2(1.0, 1.0), 0.08)
	tell_tween.tween_interval(0.4)
	tell_tween.tween_property(tell_label, "modulate:a", 0.0, 0.15)
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
		silhouette.color = Color(0.6 + 0.4 * val, 0.1 * (1.0 - val), 0.1 * (1.0 - val), 1.0)
