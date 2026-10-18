class_name StKenshiDuel
extends State

## StKenshiDuel
## Kenshi duel state:
## - 40% auto-parry on frontal strikes.
## - Back-dash evasion (12f) against heavy attacks or close pressure.
## - Quick Draw Slash (21f startup, 36 px range, 1 dmg).
## - Spinning Sweep (32f startup, 48 px range, 2 dmg, unblockable tell).

enum AttackMode { NONE, QUICK_DRAW, SPINNING_SWEEP, BACK_DASH }

@export var auto_parry_chance: float = 0.40

var current_mode: AttackMode = AttackMode.NONE
var elapsed: float = 0.0
var hitbox_activated: bool = false
var has_token: bool = false
var evasion_timer: float = 0.0


func enter(msg: Dictionary = {}) -> void:
	elapsed = 0.0
	hitbox_activated = false
	evasion_timer = 0.0
	has_token = false

	if msg.get("force_sweep", false):
		_start_sweep()
	elif msg.get("force_dash", false):
		_start_back_dash()
	elif msg.get("force_quick", false):
		_start_quick_draw()
	else:
		# Acquire attack token if engaging
		if AttackTokenManager != null and actor != null:
			has_token = AttackTokenManager.request_token(actor)

		# Choose action: 70% quick draw, 30% sweep if token granted
		if has_token:
			if randf() < 0.30:
				_start_sweep()
			else:
				_start_quick_draw()
		else:
			current_mode = AttackMode.NONE


func _start_quick_draw() -> void:
	current_mode = AttackMode.QUICK_DRAW
	elapsed = 0.0
	hitbox_activated = false
	if actor != null:
		var vis: Node = actor.get_node_or_null("Visual")
		if vis != null and vis.has_method("flash"):
			vis.call("flash")


func _start_sweep() -> void:
	current_mode = AttackMode.SPINNING_SWEEP
	elapsed = 0.0
	hitbox_activated = false
	if actor != null:
		var vis: Node = actor.get_node_or_null("Visual")
		if vis != null and vis.has_method("show_tell"):
			vis.call("show_tell", "危")


func _start_back_dash() -> void:
	current_mode = AttackMode.BACK_DASH
	elapsed = 0.0
	evasion_timer = 0.20 # 12 frames at 60 FPS
	if actor != null:
		var facing_dir: float = float(actor.facing) if "facing" in actor else 1.0
		actor.velocity.x = -facing_dir * 220.0
		var vis: Node = actor.get_node_or_null("Visual")
		if vis != null and vis.has_method("flash"):
			vis.call("flash")


func intercept_hit(hitbox: Area2D) -> bool:
	if actor == null:
		return false

	var facing_dir: float = float(actor.facing) if "facing" in actor else 1.0
	var is_frontal: bool = (hitbox.global_position.x - actor.global_position.x) * facing_dir >= -8.0

	# Auto-parry frontal attacks
	if is_frontal and randf() <= auto_parry_chance:
		var vis: Node = actor.get_node_or_null("Visual")
		if vis != null and vis.has_method("trigger_parry_spark"):
			vis.call("trigger_parry_spark")

		if NoiseBus != null:
			var ev := NoiseEvent.make(actor.global_position, 160.0, 1.4, NoiseEvent.NoiseType.COMBAT, actor)
			NoiseBus.emit_noise(ev)

		# Immediate counter-attack
		_start_quick_draw()
		return true

	return false


func update(delta: float) -> void:
	if actor == null:
		return

	elapsed += delta
	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D

	# Turn to face player during startup
	if player != null and current_mode != AttackMode.BACK_DASH and actor.has_method("face"):
		var dir: int = 1 if player.global_position.x >= actor.global_position.x else -1
		actor.face(dir)

	match current_mode:
		AttackMode.BACK_DASH:
			evasion_timer -= delta
			if evasion_timer <= 0.0:
				actor.velocity.x = 0.0
				transition(&"Chase")

		AttackMode.QUICK_DRAW:
			# Startup: 0.35s (21f), Active: 0.05s (3f), Recovery: 0.30s (18f)
			if elapsed >= 0.35 and elapsed < 0.40:
				if not hitbox_activated:
					hitbox_activated = true
					_strike(36.0, 1, 20.0, 160.0)
			elif elapsed >= 0.70:
				transition(&"Chase")

		AttackMode.SPINNING_SWEEP:
			# Startup: 0.53s (32f), Active: 0.083s (5f), Recovery: 0.40s (24f)
			if elapsed >= 0.53 and elapsed < 0.61:
				if not hitbox_activated:
					hitbox_activated = true
					_strike(48.0, 2, 40.0, 240.0)
			elif elapsed >= 1.01:
				transition(&"Chase")

		AttackMode.NONE:
			transition(&"Chase")


func _strike(reach: float, dmg: int, poise_dmg: float, knockback: float) -> void:
	if actor == null:
		return
	if actor.has_method("mark_attack_active"):
		actor.call("mark_attack_active", 0.067)

	if NoiseBus != null:
		var ev := NoiseEvent.make(actor.global_position, 200.0, 1.6, NoiseEvent.NoiseType.COMBAT, actor)
		NoiseBus.emit_noise(ev)

	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		return

	var facing_dir: float = float(actor.facing) if "facing" in actor else 1.0
	var dist: float = actor.global_position.distance_to(player.global_position)
	var x_diff: float = (player.global_position.x - actor.global_position.x) * facing_dir

	if dist <= reach and x_diff > 0.0:
		var hurtbox: HurtboxComponent = player.get_node_or_null("HurtboxComponent") as HurtboxComponent
		if hurtbox != null:
			var hb: Area2D = actor.get_node_or_null("Hitbox") as Area2D
			if hb != null:
				hb.set("damage", dmg)
				hb.set("poise_damage", poise_dmg)
				hb.set("knockback_force", knockback)
				hb.set("hitstop_duration", 0.08)
				hurtbox.receive_hit(hb)
		elif player.has_method("die"):
			player.call("die", &"slashed")


func exit() -> void:
	if has_token and AttackTokenManager != null and actor != null:
		AttackTokenManager.release_token(actor)
		has_token = false
