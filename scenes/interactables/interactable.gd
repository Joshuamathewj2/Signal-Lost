class_name Interactable
extends Area2D

@export var cell: Vector2i = Vector2i.ZERO

@onready var visual: Node2D = get_node_or_null("Visual") as Node2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(5, true)
	set_collision_mask_value(3, true)
	set_collision_mask_value(4, true)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_on_player_entered(body as Player)
	elif body is EnemyBase:
		_on_enemy_entered(body as EnemyBase)

func _on_player_entered(_p: Player) -> void:
	pass

func _on_enemy_entered(_e: EnemyBase) -> void:
	pass

func emit_noise(radius: float, loudness: float, type: NoiseEvent.NoiseType = NoiseEvent.NoiseType.FOOTSTEP) -> void:
	var event := NoiseEvent.make(global_position, radius, loudness, type, self)
	NoiseBus.emit_noise_event(event)
