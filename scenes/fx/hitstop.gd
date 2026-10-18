class_name HitStop
extends RefCounted

## Real-time msec at which the current freeze ends; overlapping freezes keep the
## longest instead of a short one restoring time early.
static var _release_at_ms: int = 0


static func freeze(tree: SceneTree, dur: float = 0.08) -> void:
	if tree == null:
		return
	var until: int = Time.get_ticks_msec() + int(dur * 1000.0)
	if until <= _release_at_ms:
		return
	_release_at_ms = until
	Engine.time_scale = 0.05
	var timer := tree.create_timer(dur, true, false, true)
	timer.timeout.connect(func() -> void:
		if Time.get_ticks_msec() >= _release_at_ms - 2:
			Engine.time_scale = 1.0
	)
