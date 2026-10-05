class_name StReturn
extends State

func enter(_msg: Dictionary = {}) -> void:
	if actor == null:
		return
	var return_pos: Vector2 = actor.get_meta("spawn_pos", actor.global_position)
	var mover: PlatformMover = actor.get_node_or_null("PlatformMover") as PlatformMover
	if mover != null:
		var speed: float = actor.profile.walk_speed if actor.profile != null else 50.0
		mover.move_to(return_pos, speed)

func update(_delta: float) -> void:
	if actor == null:
		return

	if actor.vision != null and actor.vision.is_spotted:
		transition(&"Chase")
		return

	if actor.hearing != null and not actor.last_noise.is_empty():
		var n_pos: Vector2 = actor.last_noise.get("pos", actor.global_position)
		actor.last_noise.clear()
		transition(&"Investigate", {"pos": n_pos})
		return

	var mover_ref: PlatformMover = actor.get_node_or_null("PlatformMover") as PlatformMover
	if mover_ref != null and not mover_ref.is_moving:
		transition(&"Patrol")
