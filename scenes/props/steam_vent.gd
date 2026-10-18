class_name SteamVent
extends Node2D

## SteamVent
## Atmospheric industrial steam vent with billowing particles and periodic acoustic bursts.

@export var direction: Vector2 = Vector2.UP
@export var plume_speed: float = 65.0
@export var burst_interval: float = 4.5
@export var emit_noise: bool = true

var particles: CPUParticles2D = null
var burst_timer: float = 0.0

func _ready() -> void:
	z_index = -4
	_build_nozzle()
	_setup_particles()
	burst_timer = randf_range(1.0, burst_interval)

func _build_nozzle() -> void:
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED

	# Nozzle Flange
	var flange := Polygon2D.new()
	flange.color = Color(0.3, 0.3, 0.3, 1.0)
	flange.material = mat
	flange.polygon = PackedVector2Array([
		Vector2(-8, 0), Vector2(8, 0),
		Vector2(6, 4), Vector2(-6, 4)
	])
	add_child(flange)

	# Pipe Collar
	var collar := Line2D.new()
	collar.width = 2.0
	collar.default_color = Color(0.45, 0.45, 0.45, 1.0)
	collar.material = mat
	collar.points = PackedVector2Array([Vector2(-8, 0), Vector2(8, 0)])
	add_child(collar)

func _setup_particles() -> void:
	particles = CPUParticles2D.new()
	particles.name = "SteamPlume"
	particles.amount = 24
	particles.lifetime = 1.4
	particles.preprocess = 0.5
	particles.explosiveness = 0.05
	particles.randomness = 0.3

	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	particles.material = mat

	# Soft white/grey steam with smooth alpha fade
	particles.color = Color(0.9, 0.95, 1.0, 0.28)
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 1.0, 1.0, 0.35))
	grad.set_color(1, Color(0.8, 0.85, 0.9, 0.0))
	particles.color_ramp = grad

	particles.direction = direction
	particles.spread = 22.0
	particles.gravity = Vector2(0.0, -20.0) # gentle upward buoyancy
	particles.initial_velocity_min = plume_speed * 0.7
	particles.initial_velocity_max = plume_speed * 1.3
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 5.5

	add_child(particles)
	particles.emitting = true

func _physics_process(delta: float) -> void:
	burst_timer -= delta
	if burst_timer <= 0.0:
		burst_timer = burst_interval + randf_range(-0.8, 1.2)
		_trigger_burst()

func _trigger_burst() -> void:
	if particles != null:
		# Temporarily surge velocity and amount
		var orig_v: float = particles.initial_velocity_max
		particles.initial_velocity_max = orig_v * 1.8
		var tween: Tween = create_tween()
		tween.tween_property(particles, "initial_velocity_max", orig_v, 0.6)

	if emit_noise and NoiseBus != null:
		var noise_ev := NoiseEvent.make(global_position, 50.0, 0.4, NoiseEvent.NoiseType.CLINK, self)
		NoiseBus.emit_noise_event(noise_ev)
