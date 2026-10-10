class_name StSearch
extends State

var search_timer: float = 4.0
var flip_timer: float = 1.0

func enter(_msg: Dictionary = {}) -> void:
	if actor == null:
		return
	search_timer = actor.profile.search_time if actor.profile != null else 4.0
	flip_timer = 0.6 if (machine != null and machine.has_node("Track")) else 1.0

	var mover: PlatformMover = actor.get_node_or_null("PlatformMover") as PlatformMover
	if mover != null:
		mover.stop()

func update(delta: float) -> void:
	if actor == null:
		return

	if actor.vision != null and actor.vision.is_spotted:
		transition(&"Chase")
		return

	if actor.hearing != null and not actor.last_noise.is_empty():
		var n_pos: Vector2 = actor.last_noise.get("pos", actor.global_position)
		actor.last_noise.clear()
		if machine != null and machine.has_node("Track"):
			transition(&"Track", {"pos": n_pos})
		elif machine != null and machine.has_node("Charge"):
			transition(&"Charge", {"pos": n_pos})
		else:
			transition(&"Investigate", {"pos": n_pos})
		return

	search_timer -= delta
	flip_timer -= delta

	if flip_timer <= 0.0:
		flip_timer = 0.6 if (machine != null and machine.has_node("Track")) else 1.0
		actor.face(-actor.facing)

	if search_timer <= 0.0:
		transition(&"Return")
