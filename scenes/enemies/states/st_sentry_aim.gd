class_name StSentryAim
extends State

var target_pos: Vector2 = Vector2.ZERO
var is_tracking: bool = false
var shots_fired: int = 0
var timer: float = 0.6

func enter(msg: Dictionary = {}) -> void:
	target_pos = msg.get("target", Vector2.ZERO)
	is_tracking = msg.get("tracking", false)
	shots_fired = msg.get("shots_fired", 0)
	timer = 0.6

func exit() -> void:
	if actor != null:
		var visual: Node = actor.get_node_or_null("Visual")
		if visual != null and visual.has_method("set_laser"):
			visual.call("set_laser", false, Vector2.ZERO)

func physics_update(delta: float) -> void:
	if actor == null:
		return

	timer -= delta

	if is_tracking and actor.vision != null and actor.vision.is_spotted:
		target_pos = actor.last_seen

	var to_tgt: Vector2 = target_pos - actor.global_position
	if to_tgt.is_zero_approx():
		to_tgt = Vector2.RIGHT
	var desired_angle: float = to_tgt.angle()

	var cur_angle: float = actor.facing_direction.angle()
	cur_angle = rotate_toward(cur_angle, desired_angle, deg_to_rad(60.0) * delta)
	actor.facing_direction = Vector2.from_angle(cur_angle)

	var visual: Node = actor.get_node_or_null("Visual")
	if visual != null:
		if visual.has_method("set_aim_angle"):
			visual.call("set_aim_angle", cur_angle)
		if visual.has_method("set_laser"):
			visual.call("set_laser", true, target_pos)

	var diff: float = absf(angle_difference(cur_angle, desired_angle))
	if timer <= 0.0 and diff <= deg_to_rad(5.0):
		transition(&"fire", { "target": target_pos, "tracking": is_tracking, "shots_fired": shots_fired })
