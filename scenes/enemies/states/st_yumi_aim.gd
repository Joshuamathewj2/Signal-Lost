class_name StYumiAim
extends State

## StYumiAim
## Balcony Archer Aiming and Firing State:
## - 400 px range line of sight check.
## - 42f (0.70s) red laser sight charge.
## - Fires high-velocity acoustic arrow (520 px/s).
## - Flee / Reposition if player gets within 60 px.

const AIM_DURATION: float = 0.70 # 42 frames at 60 FPS
const FLEE_DISTANCE: float = 60.0
const PROJECTILE_SCENE: PackedScene = preload("res://scenes/enemies/projectile.tscn")

var elapsed: float = 0.0
var fired: bool = false
var has_token: bool = false


func enter(_msg: Dictionary = {}) -> void:
	elapsed = 0.0
	fired = false
	has_token = false

	if AttackTokenManager != null and actor != null:
		has_token = AttackTokenManager.request_token(actor)

	if actor != null:
		actor.velocity = Vector2.ZERO
		var vis: Node = actor.get_node_or_null("Visual")
		if vis != null and vis.has_method("show_tell"):
			vis.call("show_tell", "!")


func update(delta: float) -> void:
	if actor == null:
		return

	elapsed += delta
	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		transition(&"Patrol")
		return

	var dist: float = actor.global_position.distance_to(player.global_position)

	# Flee trigger if player closes distance
	if dist <= FLEE_DISTANCE:
		_drop_flash_pellet()
		transition(&"Patrol")
		return

	# Face towards player
	if actor.has_method("face"):
		var dir: int = 1 if player.global_position.x >= actor.global_position.x else -1
		actor.face(dir)

	var vis: Node = actor.get_node_or_null("Visual")
	var local_target: Vector2 = actor.to_local(player.global_position)

	if elapsed < AIM_DURATION:
		var progress: float = clampf(elapsed / AIM_DURATION, 0.0, 1.0)
		if vis != null and vis.has_method("set_aim_target"):
			vis.call("set_aim_target", local_target, progress)
	elif not fired:
		fired = true
		if vis != null and vis.has_method("stop_aim"):
			vis.call("stop_aim")
		_fire_arrow(player.global_position)
	elif elapsed >= (AIM_DURATION + 0.35): # Recovery duration
		transition(&"Chase")


func _fire_arrow(target_pos: Vector2) -> void:
	if actor == null or not is_inside_tree():
		return

	var arrow: Node2D = PROJECTILE_SCENE.instantiate() as Node2D
	if arrow == null:
		return

	var dir: Vector2 = (target_pos - actor.global_position).normalized()
	arrow.global_position = actor.global_position + dir * 16.0
	arrow.set("direction", dir)
	arrow.set("speed", 520.0)
	arrow.set("damage", 1)
	arrow.set("poise_damage", 20.0)
	arrow.set("source_turret", actor)

	get_parent().get_parent().add_child(arrow)

	# Bowstring twang acoustic ripple
	if NoiseBus != null:
		var ev := NoiseEvent.make(actor.global_position, 180.0, 1.4, NoiseEvent.NoiseType.COMBAT, actor)
		NoiseBus.emit_noise(ev)


func _drop_flash_pellet() -> void:
	if actor == null:
		return
	# Flash pellet acoustic smoke
	if NoiseBus != null:
		var ev := NoiseEvent.make(actor.global_position, 140.0, 1.2, NoiseEvent.NoiseType.PULSE, actor)
		NoiseBus.emit_noise(ev)
	var vis: Node = actor.get_node_or_null("Visual")
	if vis != null and vis.has_method("flash"):
		vis.call("flash")


func exit() -> void:
	var vis: Node = actor.get_node_or_null("Visual") if actor != null else null
	if vis != null and vis.has_method("stop_aim"):
		vis.call("stop_aim")

	if has_token and AttackTokenManager != null and actor != null:
		AttackTokenManager.release_token(actor)
		has_token = false
