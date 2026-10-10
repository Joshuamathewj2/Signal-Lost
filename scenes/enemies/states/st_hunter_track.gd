class_name StHunterTrack
extends State

var target_pos: Vector2 = Vector2.ZERO
var track_ripple_timer: float = 0.0
var move_speed: float = 144.0

func enter(_msg: Dictionary = {}) -> void:
	if actor == null:
		return

	var vis: Node = actor.get_node_or_null("Visual")
	if vis != null and vis.has_method("show_tell"):
		vis.call("show_tell", &"question")

	track_ripple_timer = 0.0
	_next_target_or_search()

func _next_target_or_search() -> void:
	var enemy: EnemyBase = actor as EnemyBase
	if enemy == null or enemy.memory == null:
		transition(&"Search")
		return

	var entry: Dictionary = enemy.memory.pop_oldest()
	if entry.is_empty():
		transition(&"Search")
		return

	target_pos = entry.get("pos", enemy.global_position)
	var now_sec: float = float(Time.get_ticks_msec()) / 1000.0

	var has_loud: bool = entry.get("loudness", 0.0) >= 3.0 and (now_sec - entry.get("time", 0.0) <= 2.0)
	if not has_loud:
		for e in enemy.memory.entries:
			if e.get("loudness", 0.0) >= 3.0 and (now_sec - e.get("time", 0.0) <= 2.0):
				has_loud = true
				break

	if enemy.profile != null:
		move_speed = enemy.profile.run_speed if has_loud else (enemy.profile.walk_speed * 1.6)
	else:
		move_speed = 230.0 if has_loud else 144.0

	var mover: PlatformMover = enemy.get_node_or_null("PlatformMover") as PlatformMover
	if mover != null:
		mover.move_to(target_pos, move_speed)

func update(delta: float) -> void:
	var enemy: EnemyBase = actor as EnemyBase
	if enemy == null:
		return

	if enemy.vision != null and enemy.vision.is_spotted:
		transition(&"Chase")
		return

	track_ripple_timer += delta
	if track_ripple_timer >= 1.2:
		track_ripple_timer = 0.0
		var noise_ev := NoiseEvent.make(enemy.global_position, 48.0, 0.0, NoiseEvent.NoiseType.ENEMY, enemy)
		NoiseBus.emit_noise_event(noise_ev)

	if not enemy.last_noise.is_empty():
		var loud: float = enemy.last_noise.get("loudness", 0.0)
		enemy.last_noise.clear()
		if loud >= 3.0 and enemy.profile != null:
			move_speed = enemy.profile.run_speed
			var mover: PlatformMover = enemy.get_node_or_null("PlatformMover") as PlatformMover
			if mover != null:
				mover.move_to(target_pos, move_speed)

	var mover_ref: PlatformMover = enemy.get_node_or_null("PlatformMover") as PlatformMover
	if mover_ref != null and not mover_ref.is_moving:
		_next_target_or_search()
