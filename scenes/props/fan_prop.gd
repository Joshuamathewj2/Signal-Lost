class_name FanProp
extends Node2D

## FanProp
## Industrial ventilation fan with rotating blades and safety housing.
## Spins continuously, providing kinetic movement in backgrounds and corridors.

@export var rotation_speed: float = 240.0 # deg/sec
@export var blade_count: int = 4
@export var radius: float = 24.0
@export var prop_color: Color = Color(0.24, 0.24, 0.24, 1.0)

var rotor: Node2D = null

func _ready() -> void:
	z_index = -5
	_build_visuals()

func _build_visuals() -> void:
	# Material: unshaded so it's readable against the dark void
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED

	# 1. Outer Housing Frame (Ring)
	var housing := Line2D.new()
	housing.name = "Housing"
	housing.width = 2.0
	housing.default_color = prop_color
	housing.material = mat
	var ring_pts := PackedVector2Array()
	var segments: int = 24
	for i in range(segments + 1):
		var angle: float = float(i) * TAU / float(segments)
		ring_pts.append(Vector2(cos(angle), sin(angle)) * radius)
	housing.points = ring_pts
	add_child(housing)

	# 2. Safety Slats (behind blades)
	for i in range(3):
		var y_off: float = (float(i) - 1.0) * (radius * 0.55)
		var slat_half_w: float = sqrt(maxf(0.0, radius * radius - y_off * y_off))
		var slat := Line2D.new()
		slat.width = 1.0
		slat.default_color = Color(prop_color.r * 0.7, prop_color.g * 0.7, prop_color.b * 0.7, 1.0)
		slat.material = mat
		slat.points = PackedVector2Array([Vector2(-slat_half_w, y_off), Vector2(slat_half_w, y_off)])
		add_child(slat)

	# 3. Rotating Rotor
	rotor = Node2D.new()
	rotor.name = "Rotor"
	add_child(rotor)

	# Rotor Hub
	var hub := Polygon2D.new()
	hub.color = prop_color
	hub.material = mat
	var hub_pts := PackedVector2Array()
	var hub_r: float = radius * 0.25
	for i in range(12):
		var angle: float = float(i) * TAU / 12.0
		hub_pts.append(Vector2(cos(angle), sin(angle)) * hub_r)
	hub.polygon = hub_pts
	rotor.add_child(hub)

	# Rotor Blades
	for b in range(blade_count):
		var base_angle: float = float(b) * TAU / float(blade_count)
		var blade := Polygon2D.new()
		blade.color = Color(prop_color.r * 1.15, prop_color.g * 1.15, prop_color.b * 1.15, 1.0)
		blade.material = mat

		var b_len: float = radius * 0.92
		var b_w: float = radius * 0.26
		var p1 := Vector2(cos(base_angle), sin(base_angle)) * hub_r
		var p2 := Vector2(cos(base_angle + 0.18), sin(base_angle + 0.18)) * b_len
		var p3 := Vector2(cos(base_angle - 0.14), sin(base_angle - 0.14)) * b_len
		blade.polygon = PackedVector2Array([p1, p2, p3])
		rotor.add_child(blade)

func _process(delta: float) -> void:
	if rotor != null:
		rotor.rotation += deg_to_rad(rotation_speed) * delta
