class_name KenshiVisual
extends Node2D

## KenshiVisual
## Procedural rendering for the Kenshi Duelist:
## Armored ronin with shoulder cape, high jodan katana stance, blade glints,
## auto-parry spark effect, and spinning sweep tell.

const FONT: Font = preload("res://assets/fonts/Rajdhani-SemiBold.ttf")

@onready var tell_label: Label = $TellLabel
@onready var silhouette: Polygon2D = $Silhouette
@onready var cape: Polygon2D = $Cape
@onready var katana: Line2D = $Katana
@onready var parry_spark: Line2D = $ParrySpark

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

	if parry_spark != null:
		parry_spark.visible = false


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
	if parry_spark == null:
		return
	parry_spark.visible = true
	parry_spark.modulate = Color(1.0, 1.0, 0.4, 1.0)
	var tw: Tween = create_tween()
	tw.tween_property(parry_spark, "modulate:a", 0.0, 0.12)
	tw.tween_callback(func() -> void:
		if parry_spark != null:
			parry_spark.visible = false
	)


func set_alert(val: float) -> void:
	if silhouette != null:
		silhouette.color = Color(0.6 + 0.4 * val, 0.1 * (1.0 - val), 0.1 * (1.0 - val), 1.0)
