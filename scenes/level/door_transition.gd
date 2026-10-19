class_name DoorTransition
extends Area2D

signal transition_requested(target_room: String, target_spawn: String)

@export var target_room: String = ""
@export var target_spawn: String = "default"
@export var label: String = ""

var is_active: bool = true

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(3, true) # Layer 3: player
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not is_active:
		return
	if body != null and body.is_in_group(&"player"):
		is_active = false
		transition_requested.emit(target_room, target_spawn)
