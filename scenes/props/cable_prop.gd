class_name CableProp
extends Node2D

## CableProp
## Multi-segment catenary cable that sways harmonically in ambient air and swings on sonar wavefront impact.

@export var p1: Vector2 = Vector2(-40.0, 0.0)
@export var p2: Vector2 = Vector2(40.0, 0.0)
@export var base_sag: float = 32.0
@export var cable_width: float = 1.5
@export var cable_color: Color = Color(0.3, 0.3, 0.3, 1.0)

var cable_line: Line2D = null
var current_sag: float = 32.0
var sway_phase: float = 0.0
var sway_velocity: float = 0.0
var spring_k: float = 14.0
var damping_c: float = 1.8

func _ready() -> void:
	z_index = -6
	add_to_group(&"wave_reactive")
	current_sag = base_sag
	sway_phase = randf_range(0.0, TAU)

	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED

	cable_line = Line2D.new()
	cable_line.width = cable_width
	cable_line.default_color = cable_color
	cable_line.material = mat
	add_child(cable_line)
	_update_curve()

func _physics_process(delta: float) -> void:
	# Ambient gentle swaying
	sway_phase += delta * 1.5
	var ambient_offset: float = sin(sway_phase) * 1.8

	# Damped spring toward equilibrium
	var disp: float = current_sag - (base_sag + ambient_offset)
	var accel: float = -spring_k * disp - damping_c * sway_velocity
	sway_velocity += accel * delta
	current_sag += sway_velocity * delta

	_update_curve()

func _update_curve() -> void:
	if cable_line == null:
		return
	var num_pts: int = 14
	var pts := PackedVector2Array()
	for i in range(num_pts + 1):
		var t: float = float(i) / float(num_pts)
		var base_pt: Vector2 = p1.lerp(p2, t)
		var cat_sag: float = 4.0 * current_sag * t * (1.0 - t)
		pts.append(Vector2(base_pt.x, base_pt.y + cat_sag))
	cable_line.points = pts

func on_wavefront(profile: PulseProfile, origin: Vector2) -> void:
	var impulse: float = 12.0
	if profile != null:
		if profile.id == &"scream":
			impulse = 36.0
		elif profile.id == &"normal":
			impulse = 20.0
		elif profile.id == &"whisper":
			impulse = 8.0

	var dir: float = 1.0 if (global_position.x - origin.x) >= 0.0 else -1.0
	sway_velocity += impulse * dir
