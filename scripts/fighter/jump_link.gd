class_name JumpLink
extends Marker2D

## JumpLink
## Hand-authored jump for enemy AI, for spots the automatic PlatformGraph misses
## (long or awkward jumps). Place this marker on the take-off floor (feet height)
## and point `target` at another JumpLink / Marker2D on the landing floor.
## On level load it adds a JUMP edge to the level's PlatformGraph; only fighters
## whose JSON jump height / max gap can make it will path through it.
## Rooms can also list links in data/level.json ("jump_links").

@export var target: NodePath
@export var bidirectional: bool = true


func _ready() -> void:
	add_to_group(&"jump_links")
	call_deferred(&"register")


func register() -> bool:
	var t: Node2D = get_node_or_null(target) as Node2D
	if t == null:
		push_warning("[JumpLink] %s has no valid target" % get_path())
		return false
	var root: Node = get_tree().get_first_node_in_group(&"level_root")
	var graph: PlatformGraph = root.get("platform_graph") as PlatformGraph if root != null else null
	if graph == null:
		push_warning("[JumpLink] %s: no LevelRoot PlatformGraph to register into" % get_path())
		return false
	return graph.add_link(global_position, t.global_position, bidirectional)
