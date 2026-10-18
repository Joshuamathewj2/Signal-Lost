class_name MirrorDuelistVisual
extends Node2D

## MirrorDuelistVisual
## Inverted noir visual for the Mirror Duelist mini-boss:
## Monochromatic shadow ninja with high-contrast radiant white scarf,
## glowing crystalline katana, and stance indicator.

@onready var tell_label: Label = $TellLabel
@onready var silhouette: Polygon2D = $Silhouette
@onready var white_scarf: Line2D = $WhiteScarf
@onready var blade: Line2D = $Blade

var flash_tween: Tween = null
var anim_time: float = 0.0

func _ready() -> void:
	if tell_label != null:
		tell_label.visible = false

func _process(delta: float) -> void:
	anim_time += delta
	# Physics-like scarf flutter
	if white_scarf != null:
		white_scarf.set_point_position(1, Vector2(-12 + sin(anim_time * 8.0) * 2.0, -18))
		white_scarf.set_point_position(2, Vector2(-24 + sin(anim_time * 8.0 + 1.0) * 4.0, -14))

func show_parry_tell() -> void:
	if tell_label != null:
		tell_label.text = "PARRY"
		tell_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		tell_label.scale = Vector2.ZERO
		tell_label.visible = true
		var tw := create_tween()
		tw.tween_property(tell_label, "scale", Vector2(1.2, 1.2), 0.1)
		tw.tween_interval(0.4)
		tw.tween_callback(func() -> void:
			if tell_label != null:
				tell_label.visible = false
		)
	flash()

func flash() -> void:
	if silhouette == null:
		return
	if flash_tween != null and flash_tween.is_valid():
		flash_tween.kill()
	silhouette.color = Color.WHITE
	flash_tween = create_tween()
	flash_tween.tween_property(silhouette, "color", Color(0.1, 0.12, 0.14, 1.0), 0.15)
