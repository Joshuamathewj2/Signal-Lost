class_name VerletScarf
extends Line2D

## VerletScarf
## 6-node Verlet integration scarf trailing hero movement with dynamic inertia,
## air drag, and gravity. Tapers from 4.0 px at neck to 1.5 px at tip.

@export var point_count: int = 6
@export var segment_length: float = 5.0
@export var gravity: Vector2 = Vector2(0.0, 240.0)
@export var drag: float = 0.88
@export var neck_offset: Vector2 = Vector2(-2.0, -20.0)

var positions: Array[Vector2] = []
var prev_positions: Array[Vector2] = []
var anchor_node: Node2D = null


func _ready() -> void:
	z_index = -1
	default_color = Color.WHITE
	width = 3.5

	# Setup width curve tapering from 4.0 px to 1.5 px
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.4))
	width_curve = curve

	var start_pos: Vector2 = neck_offset
	positions.clear()
	prev_positions.clear()
	for i in range(point_count):
		var p: Vector2 = start_pos + Vector2(float(-i) * segment_length, 0.0)
		positions.append(p)
		prev_positions.append(p)

	anchor_node = get_parent() as Node2D


func _physics_process(delta: float) -> void:
	if positions.is_empty():
		return

	# Anchor point 0 to neck
	var anchor_pos: Vector2 = neck_offset
	positions[0] = anchor_pos

	# Extract hero velocity for inertial lag if available
	var player_body: CharacterBody2D = get_tree().get_first_node_in_group(&"player") as CharacterBody2D
	var hero_vx: float = player_body.velocity.x if player_body != null else 0.0
	var lag_offset := Vector2(-hero_vx * 0.003, 0.0)

	# 1. Verlet integration for points 1..N-1
	for i in range(1, point_count):
		var cur: Vector2 = positions[i]
		var prev: Vector2 = prev_positions[i]
		var vel: Vector2 = (cur - prev) * drag
		var next: Vector2 = cur + vel + (gravity * delta * delta) + lag_offset

		prev_positions[i] = cur
		positions[i] = next

	# 2. Distance constraint relaxation (3 iterations)
	for _iter in range(3):
		positions[0] = anchor_pos
		for i in range(point_count - 1):
			var p1: Vector2 = positions[i]
			var p2: Vector2 = positions[i + 1]
			var delta_pos: Vector2 = p2 - p1
			var dist: float = delta_pos.length()
			if dist > 0.0001:
				var diff: float = (dist - segment_length) / dist
				if i == 0:
					# p1 is fixed anchor; only move p2
					positions[i + 1] -= delta_pos * diff
				else:
					positions[i] += delta_pos * (diff * 0.5)
					positions[i + 1] -= delta_pos * (diff * 0.5)

	# 3. Update Line2D points
	var pts := PackedVector2Array()
	for p in positions:
		pts.append(p)
	points = pts
