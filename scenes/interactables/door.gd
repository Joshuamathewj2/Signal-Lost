class_name Door
extends StaticBody2D

@export_enum("KEY", "PLATE") var mode: String = "KEY"
@export var cell: Vector2i = Vector2i.ZERO

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var occluder: LightOccluder2D = $LightOccluder2D
@onready var visual: Node2D = $Visual
@onready var sensor: Area2D = $Sensor
@onready var glyph_key: Node2D = $Visual/GlyphKey
@onready var glyph_plate: Node2D = $Visual/GlyphPlate

var is_open: bool = false
var graph_ref: PlatformGraph = null

func _ready() -> void:
	# StaticBody2D layer 1: world
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(1, true)

	if mode == "PLATE":
		add_to_group(&"plate_doors")

	if glyph_key != null:
		glyph_key.visible = (mode == "KEY")
	if glyph_plate != null:
		glyph_plate.visible = (mode == "PLATE")

	if sensor != null:
		sensor.body_entered.connect(_on_sensor_body_entered)

func _on_sensor_body_entered(body: Node2D) -> void:
	if mode == "KEY" and body != null and body.is_in_group(&"player") and GameState.has_keycard:
		open()

func on_plate() -> void:
	if mode == "PLATE":
		open()

func open() -> void:
	if is_open:
		return
	is_open = true

	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	if occluder != null:
		occluder.set_deferred("visible", false)

	if graph_ref != null:
		graph_ref.set_door_open(cell, true)
		graph_ref.set_door_open(cell + Vector2i(0, 1), true)

	var noise_ev := NoiseEvent.make(global_position, 64.0, 0.5, NoiseEvent.NoiseType.PLATE, self)
	NoiseBus.emit_noise_event(noise_ev)

	if visual != null:
		var tween := create_tween()
		tween.tween_property(visual, "position:y", visual.position.y - 64.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
