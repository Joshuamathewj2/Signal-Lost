class_name StBruteWander
extends State

var pause_timer: float = 0.0
var step_timer: float = 0.0
var patrol_bounds: Vector2 = Vector2.ZERO

func enter(_msg: Dictionary = {}) -> void:
	pause_timer = 0.0
	step_timer = 0.7
	_resume_patrol()

func _resume_patrol() -> void:
	if actor == null:
		return
	var mover: PlatformMover = actor.get_node_or_null("PlatformMover") as PlatformMover
	if mover != null:
		patrol_bounds = mover.patrol_segment()
		var speed: float = actor.profile.walk_speed if actor.profile != null else 40.0
		var target_x: float = patrol_bounds.y if actor.facing > 0 else patrol_bounds.x
		mover.move_to(Vector2(target_x, actor.global_position.y), speed)

func update(delta: float) -> void:
	if actor == null:
		return

	# Heard noise -> CHARGE
	if actor.hearing != null and not actor.last_noise.is_empty():
		var n_pos: Vector2 = actor.last_noise.get("pos", actor.global_position)
		actor.last_noise.clear()
		transition(&"Charge", {"pos": n_pos})
		return

	# Step footsteps / thud ripples
	var mover: PlatformMover = actor.get_node_or_null("PlatformMover") as PlatformMover
	if mover != null and mover.is_moving:
		step_timer -= delta
		if step_timer <= 0.0:
			step_timer = 0.7
			_emit_step_thud()

	if pause_timer > 0.0:
		pause_timer -= delta
		if pause_timer <= 0.0:
			pause_timer = 0.0
			actor.face(-actor.facing)
			_resume_patrol()

func _emit_step_thud() -> void:
	if actor == null:
		return
	# ENEMY noise event, loudness 0.0 -> no enemy reacts
	var ev := NoiseEvent.make(actor.global_position, 64.0, 0.0, NoiseEvent.NoiseType.ENEMY, actor)
	NoiseBus.emit_noise_event(ev)

	# Camera trauma request if within 160 px of player
	var player_nodes: Array[Node] = actor.get_tree().get_nodes_in_group("player")
	if not player_nodes.is_empty():
		var p_node: Node2D = player_nodes[0] as Node2D
		if p_node != null and actor.global_position.distance_to(p_node.global_position) <= 160.0:
			actor.get_tree().call_group("camera_rig", "add_trauma", 0.03)

func physics_update(_delta: float) -> void:
	if pause_timer > 0.0:
		return
	var mover: PlatformMover = actor.get_node_or_null("PlatformMover") as PlatformMover if actor != null else null
	if mover != null and not mover.is_moving:
		pause_timer = 0.6
