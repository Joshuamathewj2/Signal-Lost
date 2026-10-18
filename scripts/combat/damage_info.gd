class_name DamageInfo
extends Resource

## DamageInfo
## One hit, described once and applied to anything with a HealthComponent
## (hero, enemy, destructible). Used by the Step 0C interactions (execution,
## wall slam, shockwaves) and by new hazards / enemies from Step 1 on.

enum Faction { PLAYER, ENEMY, HAZARD, NEUTRAL }

@export var amount: int = 1
var source: Node = null  ## not exported: Resources cannot export Node refs
@export var faction: Faction = Faction.NEUTRAL
@export var knockback: Vector2 = Vector2.ZERO
@export var poise_damage: float = 0.0
@export var parryable: bool = true
@export var unblockable: bool = false
@export var hitstop_ms: int = 0
@export var shake: float = 0.0
@export var is_projectile: bool = false
@export var is_hazard: bool = false
@export var cause: StringName = &"hit"


static func make(p_amount: int, p_source: Node, p_faction: Faction, p_knockback: Vector2 = Vector2.ZERO, p_cause: StringName = &"hit") -> DamageInfo:
	var d := DamageInfo.new()
	d.amount = p_amount
	d.source = p_source
	d.faction = p_faction
	d.knockback = p_knockback
	d.cause = p_cause
	return d


## Applies to `target` (a body with HealthComponent / PoiseComponent children).
## Returns true when health was reduced.
func apply_to(target: Node) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	var hc: HealthComponent = target.get_node_or_null("HealthComponent") as HealthComponent
	if hc == null or not hc.is_alive():
		return false
	var applied: bool = hc.take_damage(amount, knockback, cause)
	var pc: PoiseComponent = target.get_node_or_null("PoiseComponent") as PoiseComponent
	if pc != null and poise_damage > 0.0:
		pc.damage_poise(poise_damage)
	if applied and target.is_inside_tree():
		if hitstop_ms > 0:
			HitStop.freeze(target.get_tree(), float(hitstop_ms) / 1000.0)
		if shake > 0.0:
			target.get_tree().call_group(&"camera_rig", &"add_trauma", shake)
	return applied
