class_name StSentryIdle
extends State

@export var base_angle_deg: float = 135.0

var sweep_time: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	if actor != null:
		var visual: Node = actor.get_node_or_null("Visual")
		if visual != null and visual.has_method("set_laser"):
			visual.call("set_laser", false, Vector2.ZERO)

func physics_update(delta: float) -> void:
	if actor == null:
		return

	# Sweep +-45 degrees around base facing at 30 deg/s
	sweep_time += delta
	var sweep_offset: float = sin(sweep_time * (TAU / 6.0)) * deg_to_rad(45.0)
	var cur_ang: float = deg_to_rad(base_angle_deg) + sweep_offset
	actor.facing_direction = Vector2.from_angle(cur_ang)

	var visual: Node = actor.get_node_or_null("Visual")
	if visual != null and visual.has_method("set_aim_angle"):
		visual.call("set_aim_angle", cur_ang)

	# Transition on spotted
	if actor.vision != null and actor.vision.is_spotted:
		transition(&"aim", { "target": actor.last_seen, "tracking": true, "shots_fired": 0 })
		return

	# Transition on heard (loudness >= 3.0 already filtered by HearingComponent)
	if not actor.last_noise.is_empty():
		var n_pos: Vector2 = actor.last_noise.get("pos", Vector2.ZERO)
		actor.last_noise.clear()
		transition(&"aim", { "target": n_pos, "tracking": false, "shots_fired": 0 })
