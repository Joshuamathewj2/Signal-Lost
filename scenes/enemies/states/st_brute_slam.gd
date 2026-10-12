class_name StBruteSlam
extends State

## StBruteSlam
## Oni Brute Club Ground Slam attack state:
## - 36f (0.60s) startup with ground rumble and tell.
## - 6f (0.10s) active club slam dealing 2 damage & 60 poise dmg.
## - Emits 180 px shockwave noise.
## - Shatters glass floors in slam radius (80 px).
## - 30f (0.50s) recovery before returning to Wander or Chase.

const STARTUP_TIME: float = 0.60 # 36 frames at 60 FPS
const ACTIVE_TIME: float = 0.10 # 6 frames
const RECOVERY_TIME: float = 0.50 # 30 frames
const TOTAL_TIME: float = 1.20
const REACH: float = 60.0

var elapsed: float = 0.0
var slammed: bool = false
var has_token: bool = false


func enter(_msg: Dictionary = {}) -> void:
	elapsed = 0.0
	slammed = false
	has_token = false

	if AttackTokenManager != null and actor != null:
		has_token = AttackTokenManager.request_token(actor)

	if actor != null:
		actor.velocity = Vector2.ZERO
		var vis: Node = actor.get_node_or_null("Visual")
		if vis != null and vis.has_method("show_tell"):
			vis.call("show_tell", &"exclamation")
		if vis != null and vis.has_method("flash"):
			vis.call("flash")


func update(delta: float) -> void:
	if actor == null:
		return

	elapsed += delta

	# Startup phase
	if elapsed < STARTUP_TIME:
		pass
	# Active phase
	elif not slammed and elapsed >= STARTUP_TIME and elapsed < (STARTUP_TIME + ACTIVE_TIME):
		slammed = true
		_execute_slam()
	# Recovery phase
	elif elapsed >= TOTAL_TIME:
		transition(&"Wander")


func _execute_slam() -> void:
	if actor == null:
		return

	var facing_dir: float = float(actor.facing) if "facing" in actor else 1.0
	var slam_pos: Vector2 = actor.global_position + Vector2(facing_dir * 32.0, 16.0)

	# Shockwave acoustic ripple
	if NoiseBus != null:
		var ev := NoiseEvent.make(slam_pos, 180.0, 2.2, NoiseEvent.NoiseType.COMBAT, actor)
		NoiseBus.emit_noise(ev)

	# Strike player
	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	if player != null:
		var dist: float = actor.global_position.distance_to(player.global_position)
		var x_diff: float = (player.global_position.x - actor.global_position.x) * facing_dir
		if dist <= REACH and x_diff > -10.0:
			var hurtbox: HurtboxComponent = player.get_node_or_null("HurtboxComponent") as HurtboxComponent
			if hurtbox != null:
				var hb: Area2D = actor.get_node_or_null("Hitbox") as Area2D
				if hb != null:
					hb.set("damage", 2)
					hb.set("poise_damage", 60.0)
					hb.set("knockback_force", 320.0)
					hb.set("hitstop_duration", 0.12)
					hurtbox.receive_hit(hb)
			elif player.has_method("die"):
				player.call("die", &"crushed")

	# Shatter nearby glass floors
	var glass_nodes: Array[Node] = get_tree().get_nodes_in_group(&"wave_reactive")
	for node in glass_nodes:
		if node is GlassFloor:
			var g_floor: GlassFloor = node as GlassFloor
			if g_floor.global_position.distance_to(slam_pos) <= 80.0:
				g_floor.break_glass()


func exit() -> void:
	if has_token and AttackTokenManager != null and actor != null:
		AttackTokenManager.release_token(actor)
		has_token = false
