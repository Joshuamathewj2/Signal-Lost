class_name OniEnforcerVisual
extends Node2D

## OniEnforcerVisual
## Hulking silhouette for the Oni Enforcer mini-boss:
## Broad shoulders, spiked iron kanabo club, horned demonic faceplate,
## and a Phase 2 red blazing horn aura.

@onready var tell_label: Label = $TellLabel
@onready var body: Polygon2D = $Body
@onready var kanabo: Polygon2D = $Kanabo
@onready var horns: Polygon2D = $Horns

var is_enraged: bool = false
var anim_time: float = 0.0
var flash_tween: Tween = null

func _ready() -> void:
	if tell_label != null:
		tell_label.visible = false

func _process(delta: float) -> void:
	anim_time += delta
	if is_enraged:
		queue_redraw()

func _draw() -> void:
	if is_enraged:
		# Blazing rage flames around horns
		var flame_alpha := 0.6 + 0.3 * sin(anim_time * 12.0)
		draw_circle(Vector2(-8, -34), 4.0, Color(1.0, 0.2, 0.1, flame_alpha))
		draw_circle(Vector2(8, -34), 4.0, Color(1.0, 0.2, 0.1, flame_alpha))

func set_enraged(enraged: bool) -> void:
	is_enraged = enraged
	if horns != null:
		horns.color = Color(1.0, 0.15, 0.1, 1.0) if enraged else Color(0.8, 0.7, 0.6, 1.0)
	flash()

func show_slam_tell() -> void:
	if tell_label != null:
		tell_label.text = "SLAM!"
		tell_label.modulate = Color(1.0, 0.1, 0.1, 1.0)
		tell_label.scale = Vector2.ZERO
		tell_label.visible = true
		var tw := create_tween()
		tw.tween_property(tell_label, "scale", Vector2(1.5, 1.5), 0.12)
		tw.tween_interval(0.5)
		tw.tween_callback(func() -> void:
			if tell_label != null:
				tell_label.visible = false
		)
	flash()

func flash() -> void:
	if body == null:
		return
	if flash_tween != null and flash_tween.is_valid():
		flash_tween.kill()
	var orig_col := body.color
	body.color = Color.WHITE
	flash_tween = create_tween()
	flash_tween.tween_property(body, "color", orig_col, 0.12)
