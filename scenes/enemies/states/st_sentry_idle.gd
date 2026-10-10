class_name StSentryIdle
extends State

@export var base_angle_deg: float = 135.0

var sweep_time: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	var enemy: EnemyBase = actor as EnemyBase
	if enemy != null:
		var visual: SentryVisual = enemy.get_node_or_null("Visual") as SentryVisual
		if visual != null:
			visual.set_laser(false, Vector2.ZERO)

func physics_update(delta: float) -> void:
	var enemy: EnemyBase = actor as EnemyBase
	if enemy == null:
		return

	# Sweep +-45 degrees around base facing at 30 deg/s
	sweep_time += delta
	var sweep_offset: float = sin(sweep_time * (TAU / 6.0)) * deg_to_rad(45.0)
	var cur_ang: float = deg_to_rad(base_angle_deg) + sweep_offset
	enemy.facing_direction = Vector2.from_angle(cur_ang)

	var visual: SentryVisual = enemy.get_node_or_null("Visual") as SentryVisual
	if visual != null:
		visual.set_aim_angle(cur_ang)

	# Transition on spotted
	if enemy.vision != null and enemy.vision.is_spotted:
		transition(&"aim", { "target": enemy.last_seen, "tracking": true, "shots_fired": 0 })
		return

	# Transition on heard (loudness >= 3.0 already filtered by HearingComponent)
	if not enemy.last_noise.is_empty():
		var n_pos: Vector2 = enemy.last_noise.get("pos", Vector2.ZERO)
		enemy.last_noise.clear()
		transition(&"aim", { "target": n_pos, "tracking": false, "shots_fired": 0 })
