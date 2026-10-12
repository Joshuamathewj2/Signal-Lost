class_name StThrust
extends State

## StThrust
## Ashigaru spear thrust attack state:
## 27f (0.45s) telegraph with red glint -> 4f (0.067s) active 44 px thrust -> 20f (0.333s) recovery.
## Token managed through AttackTokenManager.

const STARTUP_TIME: float = 0.45 # 27 frames at 60 FPS
const ACTIVE_TIME: float = 0.067 # 4 frames
const RECOVERY_TIME: float = 0.333 # 20 frames
const TOTAL_TIME: float = 0.85
const REACH: float = 44.0

var elapsed: float = 0.0
var hitbox_activated: bool = false
var has_token: bool = false


func enter(_msg: Dictionary = {}) -> void:
	elapsed = 0.0
	hitbox_activated = false
	has_token = true

	if actor != null:
		actor.velocity = Vector2.ZERO

		# Red telegraph glint / tell
		var vis: Node = actor.get_node_or_null("Visual")
		if vis != null and vis.has_method("show_tell"):
			vis.call("show_tell", &"exclamation")
		if vis != null and vis.has_method("flash"):
			vis.call("flash")

		# Acoustic windup whoosh
		if NoiseBus != null:
			var ev := NoiseEvent.make(actor.global_position, 80.0, 0.5, NoiseEvent.NoiseType.ENEMY, actor)
			NoiseBus.emit_noise(ev)


func update(delta: float) -> void:
	if actor == null:
		return

	elapsed += delta

	# Face towards player during startup
	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	if player != null and elapsed < STARTUP_TIME and actor.has_method("face"):
		var dir: int = 1 if player.global_position.x >= actor.global_position.x else -1
		actor.face(dir)

	# Active phase
	if elapsed >= STARTUP_TIME and elapsed < (STARTUP_TIME + ACTIVE_TIME):
		if not hitbox_activated:
			hitbox_activated = true
			_execute_thrust_hit()
	elif elapsed >= (STARTUP_TIME + ACTIVE_TIME) and hitbox_activated:
		hitbox_activated = false

	# Attack complete
	if elapsed >= TOTAL_TIME:
		transition(&"Chase")


func _execute_thrust_hit() -> void:
	if actor == null:
		return

	# Acoustic pierce ripple
	if NoiseBus != null:
		var ev := NoiseEvent.make(actor.global_position, 180.0, 1.4, NoiseEvent.NoiseType.COMBAT, actor)
		NoiseBus.emit_noise(ev)

	# Hitbox strike detection
	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		return

	var facing_dir: float = float(actor.facing) if "facing" in actor else 1.0
	var dist: float = actor.global_position.distance_to(player.global_position)
	var x_diff: float = (player.global_position.x - actor.global_position.x) * facing_dir

	# In front and within reach
	if dist <= REACH and x_diff > 0.0:
		var hurtbox: HurtboxComponent = player.get_node_or_null("HurtboxComponent") as HurtboxComponent
		if hurtbox != null:
			# Create mock or use hitbox to strike player hurtbox
			var hb: Area2D = actor.get_node_or_null("Hitbox") as Area2D
			if hb != null:
				hb.set("damage", 1)
				hb.set("poise_damage", 25.0)
				hb.set("knockback_force", 180.0)
				hb.set("hitstop_duration", 0.08)
				hurtbox.receive_hit(hb)
		elif player.has_method("die"):
			player.call("die", &"stabbed")


func exit() -> void:
	if has_token and AttackTokenManager != null and actor != null:
		AttackTokenManager.release_token(actor)
		has_token = false
