class_name StStunned
extends State

var stun_timer: float = 1.2

func enter(_msg: Dictionary = {}) -> void:
	stun_timer = 1.2
	if actor == null:
		return

	var mover: PlatformMover = actor.get_node_or_null("PlatformMover") as PlatformMover
	if mover != null:
		mover.stop()

	var vis: Node = actor.get_node_or_null("Visual")
	if vis != null and vis.has_method("show_stun"):
		vis.call("show_stun", 1.2)

func update(delta: float) -> void:
	stun_timer -= delta
	if stun_timer <= 0.0:
		transition(&"Search")
