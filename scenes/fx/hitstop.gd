class_name HitStop
extends RefCounted

## Real-time msec at which the current freeze ends; overlapping freezes keep the
## longest instead of a short one restoring time early.
static var _release_at_ms: int = 0
static var _tree: SceneTree = null


static func freeze(tree: SceneTree, dur: float = 0.08) -> void:
	if tree == null:
		return
	var until: int = Time.get_ticks_msec() + int(dur * 1000.0)
	if until <= _release_at_ms:
		return
	_release_at_ms = until
	Engine.time_scale = 0.05
	# Released from a real-time check every idle frame (process_frame fires at the
	# normal rate whatever time_scale is), so a freeze can never get stranded.
	if _tree != tree:
		if _tree != null and is_instance_valid(_tree) and _tree.process_frame.is_connected(_tick):
			_tree.process_frame.disconnect(_tick)
		_tree = tree
	if not tree.process_frame.is_connected(_tick):
		tree.process_frame.connect(_tick)


static func _tick() -> void:
	if Time.get_ticks_msec() < _release_at_ms:
		return
	Engine.time_scale = 1.0
	if _tree != null and is_instance_valid(_tree) and _tree.process_frame.is_connected(_tick):
		_tree.process_frame.disconnect(_tick)
