class_name ShieldBearerVisual
extends Node2D

@onready var tell_label: Label = get_node_or_null("TellLabel") as Label
@onready var silhouette: Polygon2D = get_node_or_null("Silhouette") as Polygon2D
@onready var shield: Polygon2D = get_node_or_null("Shield") as Polygon2D
@onready var shield_crest: Polygon2D = get_node_or_null("ShieldCrest") as Polygon2D

var tell_tween: Tween = null
var flash_tween: Tween = null

func _ready() -> void:
	if tell_label != null:
		tell_label.visible = false

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
	tell_tween.tween_property(tell_label, "scale", Vector2.ONE, 0.08)
	tell_tween.tween_interval(0.5)
	tell_tween.tween_property(tell_label, "modulate:a", 0.0, 0.2)
	tell_tween.tween_callback(func() -> void:
		if tell_label != null:
			tell_label.visible = false
	)
	flash()

func flash() -> void:
	if shield == null:
		return
	if flash_tween != null and flash_tween.is_valid():
		flash_tween.kill()
	var orig_color: Color = shield.color
	flash_tween = create_tween()
	flash_tween.tween_property(shield, "color", Color.WHITE, 0.05)
	flash_tween.tween_property(shield, "color", orig_color, 0.15)
