class_name BansheeVisual
extends Node2D

## BansheeVisual
## Procedural rendering for the spectral Wraith / Banshee:
## Floating hagoromo ethereal ribbons, porcelain noh mask with weeping black tears,
## and a 1.2s inhalation distortion telegraph.

@onready var tell_label: Label = $TellLabel
@onready var robe: Polygon2D = $Robe
@onready var mask: Polygon2D = $Mask
@onready var tears: Line2D = $Tears

var is_inhaling: bool = false
var inhalation_time: float = 0.0
var float_time: float = 0.0
var flash_tween: Tween = null

func _ready() -> void:
	if tell_label != null:
		tell_label.visible = false

func _process(delta: float) -> void:
	float_time += delta
	position.y = sin(float_time * 3.0) * 3.5

	if is_inhaling:
		inhalation_time += delta
		queue_redraw()

func _draw() -> void:
	if is_inhaling:
		# Contracting suction rings towards the mask
		var phase: float = fmod(inhalation_time * 2.0, 1.0)
		var r: float = (1.0 - phase) * 36.0 + 4.0
		var alpha: float = phase * 0.8
		draw_arc(Vector2(0, -22), r, 0.0, TAU, 24, Color(0.3, 0.8, 1.0, alpha), 1.5, true)
		draw_circle(Vector2(0, -22), 2.0 + phase * 3.0, Color(1.0, 0.1, 0.2, alpha))

func start_inhalation() -> void:
	is_inhaling = true
	inhalation_time = 0.0
	if tell_label != null:
		tell_label.text = "!"
		tell_label.modulate = Color(0.2, 0.9, 1.0, 1.0)
		tell_label.scale = Vector2.ZERO
		tell_label.visible = true
		var tw := create_tween()
		tw.tween_property(tell_label, "scale", Vector2(1.6, 1.6), 0.15)
		tw.tween_property(tell_label, "scale", Vector2(1.0, 1.0), 0.1)

func stop_inhalation() -> void:
	is_inhaling = false
	inhalation_time = 0.0
	if tell_label != null:
		tell_label.visible = false
	queue_redraw()

func flash() -> void:
	if robe == null:
		return
	if flash_tween != null and flash_tween.is_valid():
		flash_tween.kill()
	var orig_col := robe.color
	robe.color = Color.WHITE
	flash_tween = create_tween()
	flash_tween.tween_property(robe, "color", orig_col, 0.12)
