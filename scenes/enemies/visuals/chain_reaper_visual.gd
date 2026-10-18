class_name ChainReaperVisual
extends Node2D

## ChainReaperVisual
## Visual for the Chain Reaper:
## Hooded executioner silhouette, heavy scythe blade, iron chain links,
## dynamic chain line rendering to active hook.

@onready var tell_label: Label = $TellLabel
@onready var silhouette: Polygon2D = $Silhouette
@onready var hood: Polygon2D = $Hood
@onready var scythe: Line2D = $Scythe
@onready var chain_line: Line2D = $ChainLine

var is_hook_active: bool = false
var hook_pos: Vector2 = Vector2.ZERO
var flash_tween: Tween = null

func _ready() -> void:
	if tell_label != null:
		tell_label.visible = false
	if chain_line != null:
		chain_line.visible = false

func _process(_delta: float) -> void:
	if is_hook_active and chain_line != null:
		chain_line.visible = true
		chain_line.clear_points()
		chain_line.add_point(Vector2(6, -14)) # Hand position
		chain_line.add_point(to_local(hook_pos))
	elif chain_line != null:
		chain_line.visible = false

func set_hook_active(active: bool, global_hook_pos: Vector2 = Vector2.ZERO) -> void:
	is_hook_active = active
	hook_pos = global_hook_pos

func show_tell(type: StringName) -> void:
	if tell_label == null:
		return
	tell_label.text = "!"
	tell_label.modulate = Color(1.0, 0.3, 0.1, 1.0)
	tell_label.scale = Vector2.ZERO
	tell_label.visible = true

	var tw := create_tween()
	tw.tween_property(tell_label, "scale", Vector2(1.5, 1.5), 0.1)
	tw.tween_property(tell_label, "scale", Vector2(1.0, 1.0), 0.08)
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
	var orig_col := silhouette.color
	silhouette.color = Color.WHITE
	flash_tween = create_tween()
	flash_tween.tween_property(silhouette, "color", orig_col, 0.12)
