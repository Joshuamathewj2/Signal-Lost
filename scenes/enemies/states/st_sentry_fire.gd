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

	var enemy: EnemyBase = actor as EnemyBase
	if enemy == null:
		return

	# 1. Spawn Projectile
	var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
	var fire_dir: Vector2 = (target_pos - enemy.global_position).normalized()
	if fire_dir.is_zero_approx():
		fire_dir = enemy.facing_direction
	proj.direction = fire_dir
	proj.position = enemy.global_position + fire_dir * 16.0
	enemy.get_parent().add_child(proj)

	# 2. Emit ENEMY noise ripple (radius 160)
	var noise_ev := NoiseEvent.make(enemy.global_position, 160.0, 2.0, NoiseEvent.NoiseType.ENEMY, enemy)
	NoiseBus.emit_noise_event(noise_ev)

func physics_update(delta: float) -> void:
	var enemy: EnemyBase = actor as EnemyBase
	if enemy == null:
		return

	timer -= delta
	if timer <= 0.0:
		if enemy.vision != null and enemy.vision.is_spotted:
			transition(&"aim", { "target": enemy.last_seen, "tracking": true, "shots_fired": 0 })
		elif not is_tracking and shots_fired < 3:
			transition(&"aim", { "target": target_pos, "tracking": false, "shots_fired": shots_fired })
		else:
			transition(&"idle")
