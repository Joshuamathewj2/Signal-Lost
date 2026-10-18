class_name AssassinationSystem
extends Node

## AssassinationSystem
## Detects and executes instant lethal stealth rear finishers on unaware guards:
## <= 28 px distance, rear 60-degree cone, awareness < 0.35, muted 60 px noise profile.

signal assassination_executed(target: Node2D)

const MAX_ASSASSIN_DISTANCE: float = 32.0
const REAR_CONE_ANGLE_DEG: float = 60.0 # 30 degrees either side of rear vector
const MAX_AWARENESS_THRESHOLD: float = 0.35
const TAKEDOWN_DURATION: float = 0.40


## Evaluates whether the player can assassinate the target entity.
static func can_assassinate(player: Node2D, target: Node2D) -> bool:
	if player == null or target == null:
		return false

	# 1. Distance check
	var dist: float = player.global_position.distance_to(target.global_position)
	if dist > MAX_ASSASSIN_DISTANCE:
		return false

	# 2. Awareness check
	var awareness_val: float = 0.0
	var aw_comp: Node = target.get_node_or_null("Awareness")
	if aw_comp == null:
		aw_comp = target.get_node_or_null("AwarenessComponent")
	if aw_comp != null and aw_comp.get("value") != null:
		awareness_val = float(aw_comp.get("value"))
	elif aw_comp != null and aw_comp.get("awareness") != null:
		awareness_val = float(aw_comp.get("awareness"))
	elif target.get("awareness") != null:
		awareness_val = float(target.get("awareness"))
	elif target.has_meta(&"awareness"):
		awareness_val = float(target.get_meta(&"awareness"))

	if awareness_val >= MAX_AWARENESS_THRESHOLD:
		return false

	# 3. Rear cone angle check
	var target_facing: int = 1
	if target.get("facing") != null:
		target_facing = int(target.get("facing"))
	elif target.has_meta(&"facing"):
		target_facing = int(target.get_meta(&"facing"))
	elif target.get_node_or_null("Motor") != null and target.get_node_or_null("Motor").get("facing") != null:
		target_facing = int(target.get_node_or_null("Motor").get("facing"))
	elif target.scale.x < 0.0:
		target_facing = -1

	var target_forward := Vector2(float(target_facing), 0.0)
	var rear_vector := -target_forward
	var to_player := (player.global_position - target.global_position).normalized()

	# Dot product for cone: angle between to_player and rear_vector <= 30 deg
	var half_cone_rad := deg_to_rad(REAR_CONE_ANGLE_DEG * 0.5)
	var dot := to_player.dot(rear_vector)
	if dot < cos(half_cone_rad):
		return false

	return true

## Static helper to execute stealth takedown on target
static func execute_assassination(player: CharacterBody2D, target: Node2D) -> bool:
	if not can_assassinate(player, target):
		return false
	if NoiseBus != null:
		var ev := NoiseEvent.make(target.global_position, 60.0, 0.6, NoiseEvent.NoiseType.COMBAT, player)
		NoiseBus.emit_noise(ev)
	var hc: Node = target.get_node_or_null("HealthComponent")
	if hc == null:
		for c in target.get_children():
			if c is HealthComponent or c.get_script() == HealthComponent:
				hc = c
				break
	if hc != null and hc.has_method("take_damage"):
		hc.call("take_damage", 999, Vector2.ZERO, &"assassination")
	elif target.has_method("die"):
		target.call("die")
	elif target.has_method("take_damage"):
		target.call("take_damage", 999)
	return true


## Executes stealth takedown on target. Returns true if assassination commenced.
func execute(player: CharacterBody2D, target: Node2D) -> bool:
	if not can_assassinate(player, target):
		return false

	# Muted flesh-cut acoustic ripple
	if NoiseBus != null:
		var ev := NoiseEvent.make(target.global_position, 60.0, 0.6, NoiseEvent.NoiseType.COMBAT, player)
		NoiseBus.emit_noise(ev)

	# Apply lethal damage to target
	var hc: Node = target.get_node_or_null("HealthComponent")
	if hc == null:
		for c in target.get_children():
			if c is HealthComponent or c.get_script() == HealthComponent:
				hc = c
				break
	if hc != null and hc.has_method("take_damage"):
		hc.call("take_damage", 999, Vector2.ZERO, &"assassination")
	elif target.has_method("die"):
		target.call("die")
	elif target.has_method("take_damage"):
		target.call("take_damage", 999)

	if is_inside_tree() and get_tree() != null:
		HitStop.freeze(get_tree(), 0.15)

	assassination_executed.emit(target)
	return true
