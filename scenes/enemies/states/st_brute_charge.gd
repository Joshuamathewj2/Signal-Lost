class_name StBruteCharge
extends State

var target_pos: Vector2 = Vector2.ZERO
var charge_timeout: float = 0.0

func enter(msg: Dictionary = {}) -> void:
	if actor == null:
		return

	target_pos = msg.get("pos", actor.global_position)
	charge_timeout = 4.0

	var vis: Node = actor.get_node_or_null("Visual")
	if vis != null:
		if vis.has_method("show_tell"):
			vis.call("show_tell", &"exclamation")
		if vis.has_method("flash"):
			vis.call("flash")

	var dir_x: float = signf(target_pos.x - actor.global_position.x)
	if dir_x != 0.0:
		actor.face(int(dir_x))

	var mover: PlatformMover = actor.get_node_or_null("PlatformMover") as PlatformMover
	if mover != null:
		var speed: float = actor.profile.run_speed if actor.profile != null else 110.0
		mover.move_to(target_pos, speed)

func update(delta: float) -> void:
	if actor == null:
		return

	charge_timeout -= delta
	if charge_timeout <= 0.0:
		transition(&"Stunned")
		return

	var mover: PlatformMover = actor.get_node_or_null("PlatformMover") as PlatformMover
	if mover != null and not mover.is_moving:
		transition(&"Stunned")
		return

	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	if player != null and actor.global_position.distance_to(player.global_position) <= 48.0:
		transition(&"Slam")
		return

	if actor.is_on_wall():
		transition(&"Stunned", {"duration": 2.0})
		return
