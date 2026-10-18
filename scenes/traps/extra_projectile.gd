class_name ExtraProjectile
extends Area2D

## ExtraProjectile
## Multi-archetype projectile utility supporting the 6 atlas ammunition types:
## knife, spear, fireball, dart (poison/slow), spike ball, and chain blade.

enum ProjectileType {
	KNIFE,
	SPEAR,
	FIREBALL,
	DART,
	SPIKE_BALL,
	CHAIN_BLADE
}

@export var projectile_type: ProjectileType = ProjectileType.KNIFE
@export var speed: float = 380.0
@export var damage: int = 1
@export var lifetime: float = 3.0
@export var affects_enemies: bool = true

var direction: Vector2 = Vector2.RIGHT
var is_deflected: bool = false
var source_node: Node = null

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

func _ready() -> void:
	collision_layer = 128
	collision_mask = 7

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	_configure_type()

func _configure_type() -> void:
	var anim_name: StringName = &"knife"
	match projectile_type:
		ProjectileType.KNIFE:
			anim_name = &"knife"
			speed = 460.0
			damage = 1
		ProjectileType.SPEAR:
			anim_name = &"spear"
			speed = 520.0
			damage = 2
		ProjectileType.FIREBALL:
			anim_name = &"fireball"
			speed = 320.0
			damage = 2
		ProjectileType.DART:
			anim_name = &"dart"
			speed = 360.0
			damage = 1
		ProjectileType.SPIKE_BALL:
			anim_name = &"spike_ball"
			speed = 260.0
			damage = 3
		ProjectileType.CHAIN_BLADE:
			anim_name = &"chain_blade"
			speed = 440.0
			damage = 2

	if sprite != null and sprite.sprite_frames != null:
		if sprite.sprite_frames.has_animation(anim_name):
			sprite.play(anim_name)

	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

	# Spike ball rotates while flying
	if projectile_type == ProjectileType.SPIKE_BALL:
		rotation += delta * 12.0
	else:
		rotation = direction.angle()

	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func deflect(_by_actor: Node = null) -> void:
	if is_deflected:
		return
	is_deflected = true
	direction = -direction
	rotation = direction.angle()
	speed *= 1.2
	modulate = Color(1.5, 1.5, 2.0, 1.0)

func _on_body_entered(body: Node2D) -> void:
	_handle_impact(body)

func _on_area_entered(area: Area2D) -> void:
	var parent: Node = area.get_parent()
	if parent is Node2D:
		_handle_impact(parent as Node2D)

func _handle_impact(target: Node2D) -> void:
	if target == source_node and not is_deflected:
		return

	var did_hit: bool = false

	# Player hit
	if not is_deflected and (target.is_in_group(&"player") or target.name == "Player"):
		if target.has_method("take_damage"):
			target.call("take_damage", damage, direction * 120.0)
			did_hit = true
		elif target.get("health") != null and target.health.has_method("take_damage"):
			target.health.call("take_damage", damage, direction * 120.0)
			did_hit = true

		# Dart applies slow
		if projectile_type == ProjectileType.DART and target.has_method("apply_slow"):
			target.call("apply_slow", 0.5, 2.0)

	# Enemy hit
	elif is_deflected or (affects_enemies and target.is_in_group(&"enemies")):
		var hc: Node = target.get_node_or_null("HealthComponent")
		if hc != null and hc.has_method("take_damage"):
			var dmg: int = damage * 2 if is_deflected else damage
			hc.call("take_damage", dmg, direction * 180.0, &"deflected_projectile" if is_deflected else &"trap")
			did_hit = true
		elif target.has_method("take_damage"):
			target.call("take_damage", damage)
			did_hit = true

	# World hit (solids)
	if did_hit or target is TileMap or target is StaticBody2D:
		# Fireball creates small blast
		if projectile_type == ProjectileType.FIREBALL and NoiseBus != null:
			var blast := NoiseEvent.make(global_position, 160.0, 1.5, NoiseEvent.NoiseType.IMPACT, self)
			NoiseBus.emit_noise(blast)
		queue_free()
