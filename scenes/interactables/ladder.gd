class_name Ladder
extends Area2D

## Ladder
## Vertical climbable ladder for multi-floor corridors.
## Allows hero to ascend or descend vertical shafts.

signal ladder_deployed()

@export var cell: Vector2i = Vector2i.ZERO
@export var height_tiles: int = 6
@export var is_deployed: bool = true

var player_inside: Node2D = null


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(5, true) # interactable layer
	set_collision_mask_value(3, true) # player layer

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Setup collision shape if not already defined
	var cs: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs == null:
		cs = CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(24.0, float(height_tiles * 32))
		cs.shape = rect
		cs.position = Vector2(0.0, float(height_tiles * 16))
		add_child(cs)


func deploy() -> void:
	is_deployed = true
	visible = true
	queue_redraw()
	ladder_deployed.emit()


func _on_body_entered(body: Node2D) -> void:
	if is_deployed and body != null and body.is_in_group(&"player"):
		player_inside = body


func _on_body_exited(body: Node2D) -> void:
	if body == player_inside:
		player_inside = null


func _physics_process(_delta: float) -> void:
	if not is_deployed or player_inside == null:
		return

	# Climb up
	if Input.is_action_pressed(&"jump") or Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		player_inside.velocity.y = -200.0
	# Climb down
	elif Input.is_action_pressed(&"sneak") or Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		player_inside.velocity.y = 140.0


func _draw() -> void:
	if not is_deployed:
		return

	var h: float = float(height_tiles * 32)
	# Vertical rails
	draw_line(Vector2(-8.0, 0.0), Vector2(-8.0, h), Color.WHITE, 2.0)
	draw_line(Vector2(8.0, 0.0), Vector2(8.0, h), Color.WHITE, 2.0)

	# Horizontal rungs
	var y: float = 8.0
	while y < h:
		draw_line(Vector2(-8.0, y), Vector2(8.0, y), Color(0.9, 0.9, 0.9, 0.85), 1.5)
		y += 12.0
