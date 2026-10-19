class_name DoorTransition
extends Area2D

signal transition_requested(target_room: String, target_spawn: String)

@export var target_room: String = ""
@export var target_spawn: String = "default"
@export var label: String = ""
## Chapter seals needed to pass (0 = always open). Asked of the "chapter_host".
@export var required_seals: int = 0
## Trigger size in px (for drawing the sealed barrier).
@export var rect_size: Vector2 = Vector2(64.0, 96.0)
## Which side of the trigger faces out of the room (-1 left, 1 right); the
## sealed barrier is solid there so the hero cannot walk off the map.
@export var outer_side: int = -1

var is_active: bool = true
var _was_locked: bool = false
var _blocker: CollisionShape2D = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(3, true) # Layer 3: player
	body_entered.connect(_on_body_entered)
	if required_seals > 0:
		var mat := CanvasItemMaterial.new()
		mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		material = mat
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		_blocker = CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(12.0, rect_size.y)
		_blocker.shape = shape
		_blocker.position = Vector2(6.0 if outer_side < 0 else rect_size.x - 6.0, rect_size.y * 0.5)
		body.add_child(_blocker)
		add_child(body)
		_was_locked = is_locked()
		_blocker.set_deferred("disabled", not _was_locked)

func seals_broken() -> int:
	var host: Node = get_tree().get_first_node_in_group(&"chapter_host") if is_inside_tree() else null
	if host != null and host.has_method("seal_count"):
		return int(host.call("seal_count"))
	return required_seals

func is_locked() -> bool:
	return required_seals > 0 and seals_broken() < required_seals

func _process(_delta: float) -> void:
	if required_seals <= 0:
		return
	var locked: bool = is_locked()
	if locked != _was_locked:
		_was_locked = locked
		if _blocker != null:
			_blocker.set_deferred("disabled", not locked)
	queue_redraw()

func _draw() -> void:
	if required_seals <= 0 or not _was_locked:
		return
	# Sealed barrier: pulsing red bars across the doorway.
	var a: float = 0.55 + 0.25 * sin(float(Time.get_ticks_msec()) / 180.0)
	var col := Color(1.0, 0.1, 0.1, a)
	var bars: int = 4
	for i in bars:
		var x: float = rect_size.x * (float(i) + 0.5) / float(bars)
		draw_line(Vector2(x, 0.0), Vector2(x, rect_size.y), col, 2.0)
	draw_rect(Rect2(Vector2.ZERO, rect_size), Color(0.8, 0.0, 0.0, 0.08))

func _on_body_entered(body: Node2D) -> void:
	if not is_active:
		return
	if body != null and body.is_in_group(&"player"):
		if is_locked():
			var hud: Node = get_tree().get_first_node_in_group(&"hud")
			if hud != null and hud.has_method("show_tutorial_prompt"):
				hud.call("show_tutorial_prompt", "THE SANCTUM IS SEALED - %d / %d SEALS BROKEN" % [seals_broken(), required_seals])
			if AudioManager != null:
				AudioManager.play_sfx(&"pulse_fail", global_position)
			return
		is_active = false
		transition_requested.emit(target_room, target_spawn)
