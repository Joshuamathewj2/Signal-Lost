class_name OneWayDoor
extends StaticBody2D

@export var dir: int = 1 # +1 for '>', -1 for '<'
@export var cell: Vector2i = Vector2i.ZERO

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sensor: Area2D = $Sensor
@onready var visual: Node2D = $Visual

var _tracked_players: Array[Player] = []

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(1, true)

	if visual != null:
		visual.scale.x = 1.0 if dir >= 0 else -1.0

	if sensor != null:
		sensor.body_entered.connect(_on_sensor_body_entered)
		sensor.body_exited.connect(_on_sensor_body_exited)

func _physics_process(_delta: float) -> void:
	if _tracked_players.is_empty():
		return

	var allow_pass: bool = false
	for p in _tracked_players:
		if is_instance_valid(p):
			if p.velocity.x * float(dir) >= -5.0:
				allow_pass = true
				break

	if collision_shape != null:
		collision_shape.set_deferred("disabled", allow_pass)

func _on_sensor_body_entered(body: Node2D) -> void:
	if body is Player:
		var p: Player = body as Player
		if not _tracked_players.has(p):
			_tracked_players.append(p)

func _on_sensor_body_exited(body: Node2D) -> void:
	if body is Player:
		var p: Player = body as Player
		_tracked_players.erase(p)
		if _tracked_players.is_empty() and collision_shape != null:
			collision_shape.set_deferred("disabled", false)
