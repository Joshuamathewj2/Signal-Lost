class_name GlassFloor
extends StaticBody2D

signal glass_broken(pos: Vector2)

@export var cell: Vector2i = Vector2i.ZERO

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var occluder: LightOccluder2D = $LightOccluder2D
@onready var visual: ColorRect = $Visual
@onready var sensor: Area2D = $Sensor
@onready var particles: CPUParticles2D = $ShardsParticles

var crack_amount: float = 0.0
var is_broken: bool = false
var graph_ref: PlatformGraph = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(1, true)
	add_to_group(&"wave_reactive")

	if visual != null and visual.material is ShaderMaterial:
		var sm := visual.material as ShaderMaterial
		sm.set_shader_parameter("seed_val", float(cell.x * 73 + cell.y * 37))
		sm.set_shader_parameter("crack", crack_amount)
		sm.set_shader_parameter("tint", Palette.color(&"near"))

	if sensor != null:
		sensor.body_entered.connect(_on_sensor_body_entered)

func _on_sensor_body_entered(body: Node2D) -> void:
	if not is_broken and body.is_in_group(&"brute"):
		break_glass()

func on_wavefront(profile: PulseProfile, _origin: Vector2) -> void:
	if is_broken:
		return
	if profile.id == &"scream":
		break_glass()
	elif profile.id == &"normal":
		set_crack(0.4)

func set_crack(amount: float) -> void:
	crack_amount = maxf(crack_amount, amount)
	if visual != null and visual.material is ShaderMaterial:
		(visual.material as ShaderMaterial).set_shader_parameter("crack", crack_amount)

func break_glass() -> void:
	if is_broken:
		return
	is_broken = true
	set_crack(1.0)

	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	if occluder != null:
		occluder.set_deferred("visible", false)
	if visual != null:
		visual.visible = false

	if particles != null:
		particles.emitting = true

	var noise_ev := NoiseEvent.make(global_position, 360.0, 3.0, NoiseEvent.NoiseType.GLASS, self)
	NoiseBus.emit_noise_event(noise_ev)

	glass_broken.emit(global_position)

	if graph_ref != null:
		var stand_cell := cell - Vector2i(0, 1)
		graph_ref.set_standable(stand_cell, false)
