class_name PressurePlate
extends Area2D

@export var cell: Vector2i = Vector2i.ZERO

@onready var visual: Node2D = $Visual
@onready var plate_poly: Polygon2D = $Visual/PlatePolygon

var is_pressed: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(5, true)
	set_collision_mask_value(3, true)
	set_collision_mask_value(4, true)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if is_pressed:
		return
	if body != null and (body.is_in_group(&"player") or body.is_in_group(&"enemies")):
		press()

func press() -> void:
	if is_pressed:
		return
	is_pressed = true

	if visual != null:
		visual.position.y += 2.0
	if plate_poly != null:
		plate_poly.color = Color(0.2, 0.9, 0.4, 1)

	get_tree().call_group(&"plate_doors", "on_plate")

	var noise_ev := NoiseEvent.make(global_position, 64.0, 1.0, NoiseEvent.NoiseType.PLATE, self)
	NoiseBus.emit_noise_event(noise_ev)
