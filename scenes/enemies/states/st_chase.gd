class_name StChase
extends State

var lost_timer: float = 0.0
var repath_timer: float = 0.0
var ping_timer: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	lost_timer = 0.0
	repath_timer = 0.0
	ping_timer = 0.0

	if GameState != null:
		GameState.register_detection(actor)

	if actor != null:
		var ev := NoiseEvent.make(actor.global_position, 120.0, 0.0, NoiseEvent.NoiseType.ENEMY, actor)
		NoiseBus.emit_noise(ev)

		var vis: Node = actor.get_node_or_null("Visual")
		if vis != null and vis.has_method("show_tell"):
			vis.call("show_tell", &"exclamation")

		var mover: PlatformMover = actor.get_node_or_null("PlatformMover") as PlatformMover
		if mover != null and actor.vision != null:
			var speed: float = actor.profile.run_speed if actor.profile != null else 120.0
			mover.move_to(actor.vision.last_known_pos, speed)

func update(delta: float) -> void:
	if actor == null:
		return

	if machine != null and machine.has_node("Track"):
		ping_timer += delta
		if ping_timer >= 1.0:
			ping_timer = 0.0
			var ev := NoiseEvent.make(actor.global_position, 96.0, 0.0, NoiseEvent.NoiseType.ENEMY, actor)
			NoiseBus.emit_noise_event(ev)

	if actor.vision != null and actor.vision.is_spotted:
		lost_timer = 0.0

		# Attack range check
		if machine != null and machine.has_node("Thrust"):
			var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
			if player != null and actor.global_position.distance_to(player.global_position) <= 44.0:
				if AttackTokenManager == null or AttackTokenManager.request_token(actor):
					transition(&"Thrust")
					return
		elif machine != null and machine.has_node("Duel"):
			var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
			if player != null and actor.global_position.distance_to(player.global_position) <= 48.0:
				if AttackTokenManager == null or AttackTokenManager.request_token(actor):
					transition(&"Duel")
					return
		elif machine != null and machine.has_node("Aim"):
			var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
			if player != null and actor.global_position.distance_to(player.global_position) <= 400.0:
				if AttackTokenManager == null or AttackTokenManager.request_token(actor):
					transition(&"Aim")
					return

		repath_timer -= delta
		if repath_timer <= 0.0:
			repath_timer = 0.25
			var mover: PlatformMover = actor.get_node_or_null("PlatformMover") as PlatformMover
			if mover != null:
				var speed: float = actor.profile.run_speed if actor.profile != null else 120.0
				mover.move_to(actor.vision.last_known_pos, speed)
	else:
		lost_timer += delta
		var is_hunter: bool = machine != null and machine.has_node("Track")
		var max_lost: float = 2.0 if is_hunter else 1.5
		if lost_timer >= max_lost:
			if is_hunter:
				var enemy: EnemyBase = actor as EnemyBase
				if enemy != null and enemy.memory != null:
					var fake_ev := NoiseEvent.make(actor.last_seen, 48.0, 1.0, NoiseEvent.NoiseType.PULSE, null)
					enemy.memory.push_noise(fake_ev, 1.0)
				transition(&"Track")
			else:
				transition(&"Investigate", {"pos": actor.last_seen})
