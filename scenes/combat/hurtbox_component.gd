class_name HurtboxComponent
extends Area2D

## HurtboxComponent
## Area2D specialization that receives hits from HitboxComponent instances,
## checks defensive state (parry/guard) via sibling/owner controllers,
## and routes damage and poise trauma to sibling HealthComponent and PoiseComponent.

signal hit_received(hitbox: Area2D)
signal hit_blocked(hitbox: Area2D, is_parry: bool)

@export var health_component: HealthComponent
@export var poise_component: PoiseComponent
@export var is_invulnerable: bool = false


func _ready() -> void:
	if health_component == null:
		health_component = get_parent().get_node_or_null("HealthComponent") as HealthComponent
	if poise_component == null:
		poise_component = get_parent().get_node_or_null("PoiseComponent") as PoiseComponent


## Receives a hit from an active hitbox.
## Returns true if the hit was registered, false if immune.
func receive_hit(hitbox: Area2D) -> bool:
	if is_invulnerable:
		return false

	if health_component != null and not health_component.is_alive():
		return false

	# Check defensive interception on parent/sibling combat controller
	var parent_node: Node = get_parent()
	if parent_node != null and parent_node.has_method("intercept_hit"):
		var handled: bool = parent_node.intercept_hit(hitbox)
		if handled:
			hit_blocked.emit(hitbox, true)
			return true

	# Extract hit parameters safely
	var dmg: int = int(hitbox.get("damage")) if hitbox.get("damage") != null else 1
	var poise_dmg: float = float(hitbox.get("poise_damage")) if hitbox.get("poise_damage") != null else 20.0
	var kb_force: float = float(hitbox.get("knockback_force")) if hitbox.get("knockback_force") != null else 150.0
	var hs_dur: float = float(hitbox.get("hitstop_duration")) if hitbox.get("hitstop_duration") != null else 0.06

	# Calculate knockback vector pointing away from hitbox
	var kb_dir: Vector2 = Vector2.RIGHT if hitbox.global_position.x <= global_position.x else Vector2.LEFT
	var kb_vector: Vector2 = kb_dir * kb_force

	# Apply damage
	var took_damage: bool = false
	if health_component != null:
		took_damage = health_component.take_damage(dmg, kb_vector, &"combat")

	if poise_component != null:
		poise_component.damage_poise(poise_dmg)

	# Apply hit-stop micro-freeze
	if took_damage and hs_dur > 0.0 and is_inside_tree() and get_tree() != null:
		HitStop.freeze(get_tree(), hs_dur)

	hit_received.emit(hitbox)
	return true
