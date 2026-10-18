class_name DustParticles
extends CPUParticles2D

## DustParticles
## Ambient floating atmospheric dust motes giving tangible depth to the facility air.

func _ready() -> void:
	z_index = -2
	amount = 32
	lifetime = 6.0
	preprocess = 3.0
	explosiveness = 0.0
	randomness = 0.4

	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = mat

	emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	emission_rect_extents = Vector2(960.0, 540.0)

	color = Color(0.9, 0.95, 1.0, 0.18)
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 1.0, 1.0, 0.0))
	grad.set_offset(0, 0.0)
	grad.add_point(0.2, Color(1.0, 1.0, 1.0, 0.22))
	grad.add_point(0.8, Color(1.0, 1.0, 1.0, 0.22))
	grad.add_point(1.0, Color(1.0, 1.0, 1.0, 0.0))
	color_ramp = grad

	direction = Vector2(0.3, -0.7)
	spread = 35.0
	gravity = Vector2(-2.0, -4.0)
	initial_velocity_min = 6.0
	initial_velocity_max = 16.0
	scale_amount_min = 1.0
	scale_amount_max = 2.2
	emitting = true
