class_name ArrowTrapProjectile
extends Area2D

## ArrowTrapProjectile
## High-velocity arrow projectile fired by ArrowTrap.
## Can be deflected 180 degrees back by the hero's parry, turning lethal to enemies.

@export var speed: float = 460.0
@export var damage: int = 1
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT
var is_deflected: bool = false
var source_trap: Node = null

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

func _ready() -> void:
	collision_layer = 128 # Hazard / projectile
	collision_mask = 7   # World (1) + Player (2) + Enemies (4)

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func deflect(_by_actor: Node = null) -> void:
	if is_deflected:
		return
	is_deflected = true
	direction = -direction
	rotation = direction.angle()
	speed *= 1.25 # Deflected bolt accelerates

	# Visual flash
	modulate = Color(1.5, 1.5, 2.0, 1.0)
	if NoiseBus != null:
		var clink := NoiseEvent.make(global_position, 140.0, 1.5, NoiseEvent.NoiseType.COMBAT, self)
		NoiseBus.emit_noise(clink)

func _on_body_entered(body: Node2D) -> void:
	_handle_impact(body)

func _on_area_entered(area: Area2D) -> void:
	var parent: Node = area.get_parent()
	if parent is Node2D:
		_handle_impact(parent as Node2D)

func _handle_impact(target: Node2D) -> void:
	if target == source_trap and not is_deflected:
		return

	var did_hit: bool = false

	# Player hit
	if not is_deflected and (target.is_in_group(&"player") or target.name == "Player"):
		if target.has_method("take_damage"):
			target.call("take_damage", damage, direction * 150.0)
			did_hit = true
		elif target.get("health") != null and target.health.has_method("take_damage"):
			target.health.call("take_damage", damage, direction * 150.0)
			did_hit = true

	# Enemy hit (always hits enemies if deflected, or if trap affects enemies)
	elif is_deflected or target.is_in_group(&"enemies"):
		var hc: Node = target.get_node_or_null("HealthComponent")
		if hc != null and hc.has_method("take_damage"):
			var dmg: int = damage * 2 if is_deflected else damage
			hc.call("take_damage", dmg, direction * 220.0, &"deflected_bolt" if is_deflected else &"trap")
			did_hit = true
		elif target.has_method("take_damage"):
			target.call("take_damage", damage)
			did_hit = true

	# World hit (solids)
	if did_hit or target is TileMap or target is StaticBody2D:
		queue_free()
