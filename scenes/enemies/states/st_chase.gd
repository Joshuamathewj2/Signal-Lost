class_name StChase
extends State

var lost_timer: float = 0.0
var repath_timer: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	lost_timer = 0.0
	repath_timer = 0.0

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

	if actor.vision != null and actor.vision.is_spotted:
		lost_timer = 0.0
		repath_timer -= delta
		if repath_timer <= 0.0:
			repath_timer = 0.25
			var mover: PlatformMover = actor.get_node_or_null("PlatformMover") as PlatformMover
			if mover != null:
				var speed: float = actor.profile.run_speed if actor.profile != null else 120.0
				mover.move_to(actor.vision.last_known_pos, speed)
	else:
		lost_timer += delta
		if lost_timer >= 1.5:
			transition(&"Investigate", {"pos": actor.last_seen})
