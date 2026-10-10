class_name HitStop
extends RefCounted

static func freeze(tree: SceneTree, dur: float = 0.08) -> void:
	if tree == null:
		return
	Engine.time_scale = 0.05
	var timer := tree.create_timer(dur, true, false, true)
	timer.timeout.connect(func() -> void:
		Engine.time_scale = 1.0
	)
