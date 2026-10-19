class_name StChase
extends State

var lost_timer: float = 0.0
var repath_timer: float = 0.0
var ping_timer: float = 0.0

func enter(msg: Dictionary = {}) -> void:
	lost_timer = 0.0
	repath_timer = 0.0
	ping_timer = 0.0

	if msg.get("resume", false):
		return  # back from an attack: already alerted, no new tell / detection

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
		if machine != null and machine.has_node("Attack"):
			if _try_villain_attack():
				return
		elif machine != null and machine.has_node("Thrust"):
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
			if mover != null and _holding_range():
				mover.stop()
			elif mover != null:
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


## Manifest villains (StVillainAttack): pick an in-range attack from JSON.
## Melee swings need an attack token; ranged shots and repositions do not.
func _try_villain_attack() -> bool:
	var atk_state: StVillainAttack = machine.get_node("Attack") as StVillainAttack
	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	if atk_state == null or player == null:
		return false
	var atk: Dictionary = atk_state.pick_attack(player)
	if atk.is_empty():
		return false
	var token: bool = false
	if atk_state.is_melee(atk) and AttackTokenManager != null:
		token = AttackTokenManager.request_token(actor)
		if not token:
			return false
	transition(&"Attack", {"attack": atk, "has_token": token})
	return true


## Ranged villains (enemy_data.keep_distance) hold position once close enough.
func _holding_range() -> bool:
	if not ("enemy_data" in actor):
		return false
	var keep: float = float((actor.get("enemy_data") as Dictionary).get("keep_distance", 0.0))
	if keep <= 0.0:
		return false
	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		return false
	if actor.has_method("face"):
		actor.call("face", 1 if player.global_position.x >= actor.global_position.x else -1)
	return absf(player.global_position.x - actor.global_position.x) <= keep
