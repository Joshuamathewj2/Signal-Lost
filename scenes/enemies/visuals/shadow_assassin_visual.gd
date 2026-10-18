class_name ShadowAssassinVisual
extends Node2D

## ShadowAssassinVisual
## Procedural rendering for the cloaked Shadow Assassin:
## Dual kunai daggers, flowing frayed ninja scarf, faint active-camouflage shimmer,
## and a 0.4s red strike telegraph.

@onready var tell_label: Label = $TellLabel
@onready var silhouette: Polygon2D = $Silhouette
@onready var cloak: Polygon2D = $Cloak
@onready var dagger_l: Line2D = $DaggerL
@onready var dagger_r: Line2D = $DaggerR

var is_cloaked: bool = true
var shimmer_phase: float = 0.0
var flash_tween: Tween = null

func _ready() -> void:
	if tell_label != null:
		tell_label.visible = false
	update_cloak_alpha()

func _process(delta: float) -> void:
	if is_cloaked:
		shimmer_phase += delta * 6.0
		# Faint optical distortion shimmer
		modulate.a = 0.08 + 0.05 * sin(shimmer_phase)
	else:
		modulate.a = 1.0

func set_cloaked(cloaked: bool) -> void:
	is_cloaked = cloaked
	update_cloak_alpha()

func update_cloak_alpha() -> void:
	modulate.a = 0.08 if is_cloaked else 1.0

func show_tell(type: StringName) -> void:
	if tell_label == null:
		return
	tell_label.text = "!"
	tell_label.modulate = Color(1.0, 0.1, 0.1, 1.0)
	tell_label.scale = Vector2.ZERO
	tell_label.visible = true

	var tw := create_tween()
	tw.tween_property(tell_label, "scale", Vector2(1.5, 1.5), 0.08)
	tw.tween_property(tell_label, "scale", Vector2(1.0, 1.0), 0.06)
	tw.tween_interval(0.4)
	tw.tween_callback(func() -> void:
		if tell_label != null:
			tell_label.visible = false
	)

func flash() -> void:
	if silhouette == null:
		return
	if flash_tween != null and flash_tween.is_valid():
		flash_tween.kill()
	var orig_col := silhouette.color
	silhouette.color = Color.WHITE
	flash_tween = create_tween()
	flash_tween.tween_property(silhouette, "color", orig_col, 0.12)
