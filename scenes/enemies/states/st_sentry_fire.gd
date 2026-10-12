class_name StSentryFire
extends State

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/enemies/projectile.tscn")

var target_pos: Vector2 = Vector2.ZERO
var is_tracking: bool = false
var shots_fired: int = 0
var timer: float = 0.9

func enter(msg: Dictionary = {}) -> void:
	target_pos = msg.get("target", Vector2.ZERO)
	is_tracking = msg.get("tracking", false)
	shots_fired = msg.get("shots_fired", 0) + 1
	timer = 0.9

	if actor == null:
		return

	# 1. Spawn Projectile
	var proj = PROJECTILE_SCENE.instantiate()
	var fire_dir: Vector2 = (target_pos - actor.global_position).normalized()
	if fire_dir.is_zero_approx():
		fire_dir = actor.facing_direction
	if "direction" in proj:
		proj.direction = fire_dir
	if "source_turret" in proj:
		proj.source_turret = actor
	if proj is Node2D:
		(proj as Node2D).position = actor.global_position + fire_dir * 16.0
	actor.get_parent().add_child(proj)

	# 2. Emit ENEMY noise ripple (radius 160)
	var noise_ev := NoiseEvent.make(actor.global_position, 160.0, 2.0, NoiseEvent.NoiseType.ENEMY, actor)
	NoiseBus.emit_noise_event(noise_ev)

func physics_update(delta: float) -> void:
	if actor == null:
		return

	timer -= delta
	if timer <= 0.0:
		if actor.vision != null and actor.vision.is_spotted:
			transition(&"aim", { "target": actor.last_seen, "tracking": true, "shots_fired": 0 })
		elif not is_tracking and shots_fired < 3:
			transition(&"aim", { "target": target_pos, "tracking": false, "shots_fired": shots_fired })
		else:
			transition(&"idle")
