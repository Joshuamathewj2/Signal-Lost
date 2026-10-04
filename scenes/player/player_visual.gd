class_name PlayerVisual
extends Node2D

@onready var body_polygon: Polygon2D = $Body
@onready var head_polygon: Polygon2D = $Head
@onready var antenna_line: Line2D = $Antenna

var current_pose: StringName = &"idle"

func _ready() -> void:
	update_colors()
	if Palette != null and Palette.has_signal("palette_changed"):
		Palette.palette_changed.connect(update_colors)

func update_colors() -> void:
	var c: Color = Palette.color(&"white") if Palette != null else Color.WHITE
	if body_polygon != null:
		body_polygon.color = c
	if head_polygon != null:
		head_polygon.color = c
	if antenna_line != null:
		antenna_line.default_color = c

func set_facing(dir: int) -> void:
	if dir != 0:
		scale.x = 1.0 if dir > 0 else -1.0

func set_pose(pose: StringName) -> void:
	current_pose = pose
	match pose:
		&"crouch", &"sneak":
			position.y = 3.0
		_:
			position.y = 0.0

func set_alert(_v: float) -> void:
	pass

func flash() -> void:
	modulate = Color(2.0, 2.0, 2.0, 1.0)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)

func play_death() -> void:
	visible = false
