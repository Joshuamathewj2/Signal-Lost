class_name StPatrol
extends State

var pause_timer: float = 0.0
var patrol_bounds: Vector2 = Vector2.ZERO

func enter(_msg: Dictionary = {}) -> void:
	pause_timer = 0.0
	_resume_patrol()

func _resume_patrol() -> void:
	if actor == null:
		return
	var mover: PlatformMover = actor.get_node_or_null("PlatformMover") as PlatformMover
	if mover != null:
		patrol_bounds = mover.patrol_segment()
		var speed: float = 50.0
		if "profile" in actor and actor.profile != null:
			speed = actor.profile.walk_speed
		var target_x: float = patrol_bounds.y if ("facing" in actor and actor.facing > 0) else patrol_bounds.x
		mover.move_to(Vector2(target_x, actor.global_position.y), speed)

func update(delta: float) -> void:
	if actor == null:
		return

	# Check transitions
	if "vision" in actor and actor.vision != null and actor.vision.is_spotted:
		transition(&"Chase")
		return

	if "hearing" in actor and actor.hearing != null and "last_noise" in actor and not actor.last_noise.is_empty():
		var n_pos: Vector2 = actor.last_noise.get("pos", actor.global_position)
		actor.last_noise.clear()
		if machine != null and machine.has_node("Track"):
			transition(&"Track", {"pos": n_pos})
		else:
			transition(&"Investigate", {"pos": n_pos})
		return

	if pause_timer > 0.0:
		pause_timer -= delta
		if pause_timer <= 0.0:
			pause_timer = 0.0
			actor.face(-actor.facing)
			_resume_patrol()

func physics_update(_delta: float) -> void:
	if pause_timer > 0.0:
		return
	var mover: PlatformMover = actor.get_node_or_null("PlatformMover") as PlatformMover if actor != null else null
	if mover != null and not mover.is_moving:
		# Reached end or blocked -> pause 0.6s then turn
		pause_timer = 0.6
