class_name SlashArc
extends Line2D

## SlashArc
## Procedural curved white/cyan Line2D slash trail fading over 0.12s.
## Rendered with unshaded CanvasItemMaterial so it is vividly visible in dark noir lighting.

@export var lifetime: float = 0.12
@export var arc_radius: float = 42.0
@export var arc_angle_deg: float = 120.0

var elapsed: float = 0.0


func _ready() -> void:
	z_index = 25
	# Ensure unshaded material so the slash is fully visible against dark CanvasModulate
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = mat

	default_color = Color(0.85, 0.98, 1.0, 1.0)
	width = 7.0

	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.2))
	curve.add_point(Vector2(0.6, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	width_curve = curve


func setup(facing_dir: int, radius: float = 42.0) -> void:
	arc_radius = radius
	var pts := PackedVector2Array()
	var half_angle: float = deg_to_rad(arc_angle_deg * 0.5)
	var steps: int = 16

	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var ang: float = -half_angle + (t * half_angle * 2.0)
		var offset_x: float = cos(ang) * arc_radius * float(facing_dir)
		var offset_y: float = sin(ang) * arc_radius * 0.75
		pts.append(Vector2(offset_x, offset_y))

	points = pts


func _process(delta: float) -> void:
	elapsed += delta
	var progress: float = clampf(elapsed / lifetime, 0.0, 1.0)
	modulate.a = 1.0 - progress

	if elapsed >= lifetime:
		queue_free()


static func spawn(parent: Node2D, spawn_pos: Vector2, facing: int, radius: float = 42.0) -> Line2D:
	var script_res: Script = load("res://scenes/fx/slash_arc.gd") as Script
	var arc: Line2D = script_res.new() as Line2D
	arc.position = spawn_pos
	parent.add_child(arc)
	arc.call("setup", facing, radius)
	return arc
