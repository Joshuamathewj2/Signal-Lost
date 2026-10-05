class_name StInvestigate
extends State

var target_pos: Vector2 = Vector2.ZERO

func enter(msg: Dictionary = {}) -> void:
	if actor == null:
		return
	target_pos = msg.get("pos", actor.global_position)

	var vis: Node = actor.get_node_or_null("Visual")
	if vis != null and vis.has_method("show_tell"):
		vis.call("show_tell", &"question")

	var mover: PlatformMover = actor.get_node_or_null("PlatformMover") as PlatformMover
	if mover != null:
		var speed: float = (actor.profile.walk_speed * 1.4) if actor.profile != null else 70.0
		mover.move_to(target_pos, speed)

func update(_delta: float) -> void:
	if actor == null:
		return

	if actor.vision != null and actor.vision.is_spotted:
		transition(&"Chase")
		return

	# Retarget on newer noise
	if actor.hearing != null and not actor.last_noise.is_empty():
		target_pos = actor.last_noise.get("pos", target_pos)
		actor.last_noise.clear()
		var mover: PlatformMover = actor.get_node_or_null("PlatformMover") as PlatformMover
		if mover != null:
			var speed: float = (actor.profile.walk_speed * 1.4) if actor.profile != null else 70.0
			mover.move_to(target_pos, speed)

	var mover_ref: PlatformMover = actor.get_node_or_null("PlatformMover") as PlatformMover
	if mover_ref != null and not mover_ref.is_moving:
		transition(&"Search")
