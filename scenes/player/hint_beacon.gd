class_name HintBeacon
extends Node2D

## HintBeacon
## Emergency acoustic homing ping. Pressing H emits a directional acoustic arrow
## pointing towards Exit Terminal E, generating 120 px noise with a 5.0s cooldown.

signal beacon_fired(direction: Vector2)

@export var cooldown_duration: float = 5.0
@export var noise_radius: float = 120.0
@export var arrow_lifetime: float = 1.5

var current_cooldown: float = 0.0
var active_arrow_time: float = 0.0
var arrow_direction: Vector2 = Vector2.RIGHT


func _ready() -> void:
	add_to_group(&"hint_beacons")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"hint") or (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_H):
		try_fire()


func try_fire() -> bool:
	if current_cooldown > 0.0:
		return false

	var exit_node: Node2D = _find_exit_terminal()
	if exit_node != null:
		arrow_direction = (exit_node.global_position - global_position).normalized()
	else:
		arrow_direction = Vector2.RIGHT

	current_cooldown = cooldown_duration
	active_arrow_time = arrow_lifetime

	# Emit acoustic noise on NoiseBus (r = 120 px, loudness 1.0)
	if NoiseBus != null:
		NoiseBus.emit_noise(NoiseEvent.make(global_position, noise_radius, 1.0, NoiseEvent.NoiseType.PULSE, self))

	if AudioManager != null:
		AudioManager.play_sfx(&"decoy_bounce", global_position)

	beacon_fired.emit(arrow_direction)
	queue_redraw()
	return true


func _find_exit_terminal() -> Node2D:
	var tree: SceneTree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree == null:
		return null

	var exits := tree.get_nodes_in_group(&"exit_terminal")
	if not exits.is_empty():
		return exits[0] as Node2D

	var interactables := tree.get_nodes_in_group(&"interactable")
	for item in interactables:
		if item.name.to_lower().contains("exit"):
			return item as Node2D
	return null


func _process(delta: float) -> void:
	if current_cooldown > 0.0:
		current_cooldown = maxf(0.0, current_cooldown - delta)

	if active_arrow_time > 0.0:
		active_arrow_time = maxf(0.0, active_arrow_time - delta)
		queue_redraw()


func _draw() -> void:
	if active_arrow_time <= 0.0:
		return

	var alpha: float = active_arrow_time / arrow_lifetime
	var col := Color(0.2, 0.9, 1.0, alpha)

	# Draw directional acoustic arrow (40 px length)
	var arrow_end: Vector2 = arrow_direction * 40.0
	draw_line(Vector2.ZERO, arrow_end, col, 2.5)

	# Arrow head
	var left_wing: Vector2 = arrow_end + (-arrow_direction.rotated(PI * 0.25)) * 12.0
	var right_wing: Vector2 = arrow_end + (-arrow_direction.rotated(-PI * 0.25)) * 12.0
	draw_line(arrow_end, left_wing, col, 2.0)
	draw_line(arrow_end, right_wing, col, 2.0)

	# Expanding acoustic ripple arc
	var wave_r: float = (1.0 - alpha) * 48.0
	draw_arc(Vector2.ZERO, wave_r, arrow_direction.angle() - 0.6, arrow_direction.angle() + 0.6, 12, col * 0.8, 1.5)
