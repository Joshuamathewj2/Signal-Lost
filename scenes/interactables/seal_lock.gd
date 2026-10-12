class_name SealLock
extends Area2D

## SealLock
## Multi-node cryptographic airlock gate. Requires inserting multiple keys or
## satisfying dual remote conditions. Disengaging produces a 280 px hydraulic release noise.

signal unlocked(seal: SealLock)
signal key_inserted(seal: SealLock, current: int, total: int)

@export var required_keys: int = 2
@export var target_door: NodePath

var current_keys: int = 0
var is_unlocked: bool = false


func _ready() -> void:
	add_to_group(&"seal_locks")
	add_to_group(&"interactable")

	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(5, true) # interactable layer
	set_collision_mask_value(3, true) # player layer

	var cs: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs == null:
		cs = CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(36.0, 36.0)
		cs.shape = rect
		add_child(cs)


func insert_key() -> void:
	if is_unlocked:
		return

	current_keys = mini(required_keys, current_keys + 1)
	key_inserted.emit(self, current_keys, required_keys)
	queue_redraw()

	if current_keys >= required_keys:
		disengage()


func disengage() -> void:
	if is_unlocked:
		return
	is_unlocked = true

	# Loud hydraulic release noise (r = 280 px, loudness 1.8)
	if NoiseBus != null:
		NoiseBus.emit_noise(NoiseEvent.make(global_position, 280.0, 1.8, NoiseEvent.NoiseType.IMPACT, self))

	if AudioManager != null:
		AudioManager.play_sfx(&"door_open", global_position)

	# Unlock connected blast door
	if not target_door.is_empty():
		var door: Node = get_node_or_null(target_door)
		if door != null:
			if door.has_method("unlock"):
				door.call("unlock")
			elif door.has_method("open"):
				door.call("open")
			elif "is_open" in door:
				door.set("is_open", true)

	unlocked.emit(self)
	queue_redraw()


func reset() -> void:
	is_unlocked = false
	current_keys = 0
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(-18.0, -18.0, 36.0, 36.0)
	draw_rect(rect, Color(0.08, 0.08, 0.08, 0.95), true)
	draw_rect(rect, Color.WHITE if is_unlocked else Color(0.6, 0.6, 0.6), false, 2.0)

	# Key slot indicators
	var slot_spacing: float = 32.0 / float(required_keys + 1)
	for i in range(required_keys):
		var x: float = -16.0 + float(i + 1) * slot_spacing
		var pos := Vector2(x, 0.0)
		var is_slot_filled: bool = (i < current_keys)
		var col: Color = Color(0.2, 0.9, 1.0) if is_slot_filled else Color(0.4, 0.1, 0.1)
		draw_circle(pos, 4.0, col)
		draw_arc(pos, 4.0, 0.0, TAU, 12, Color.WHITE if is_slot_filled else Color(0.3, 0.3, 0.3), 1.0)
