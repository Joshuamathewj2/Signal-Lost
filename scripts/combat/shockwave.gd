class_name Shockwave
extends RefCounted

## Shockwave
## Radial ground strike. Hits the hero and - with friendly_fire.shockwaves in
## data/combat.json - every other enemy in range too (enemies can be crushed by
## an ally's slam). Returns the bodies that took damage.

static func strike(tree: SceneTree, origin: Vector2, radius: float, info: DamageInfo, exclude: Node = null) -> Array[Node]:
	var hit: Array[Node] = []
	if tree == null:
		return hit
	var targets: Array[Node] = []
	if CombatTuning.friendly_fire("shockwaves") or info.faction != DamageInfo.Faction.ENEMY:
		targets.append_array(tree.get_nodes_in_group(&"enemies"))
	for t in targets:
		if t == exclude or not (t is Node2D) or (t as Node2D).global_position.distance_to(origin) > radius:
			continue
		var d: DamageInfo = info.duplicate() as DamageInfo
		var dir: float = signf((t as Node2D).global_position.x - origin.x)
		d.knockback = Vector2((dir if dir != 0.0 else 1.0) * absf(info.knockback.x), info.knockback.y)
		if d.apply_to(t):
			hit.append(t)
	return hit
