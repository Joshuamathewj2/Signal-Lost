class_name Bomb
extends Area2D

## Bomb
## Lobbed explosive projectile thrown in an arc by Bomber enemies.
## Can be deflected mid-air by the player's parry to reverse direction back at hostiles.
## Explodes on timeout or impact, dealing AoE damage and shattering glass.

@export var fuse_time: float = 2.2
@export var explosion_radius: float = 48.0
@export var damage: int = 1
@export var poise_damage: float = 40.0

var velocity: Vector2 = Vector2.ZERO
var arc_gravity: float = 600.0
var is_deflected: bool = false
var source_bomber: Node = null
var _exploded: bool = false

var reticle_scene: PackedScene = preload("res://scenes/ui/world_reticle.tscn")
var reticle: Node2D = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(6, true) # Projectile layer
	set_collision_mask_value(1, true) # World
	set_collision_mask_value(3, true) # Player
	set_collision_mask_value(4, true) # Hurtboxes

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	reticle = reticle_scene.instantiate() as Node2D
	if reticle != null:
		if "reticle_type" in reticle:
			reticle.set("reticle_type", 0) # PROJECTILE
		add_child(reticle)

func _physics_process(delta: float) -> void:
	if _exploded:
		return

	velocity.y += arc_gravity * delta
	position += velocity * delta

	fuse_time -= delta
	if fuse_time <= 0.0:
		explode()
	else:
		queue_redraw()

func _draw() -> void:
	# Bomb sphere
	var col := Color(0.9, 0.95, 1.0) if is_deflected else Color(0.95, 0.25, 0.2)
	draw_circle(Vector2.ZERO, 6.0, col)
	draw_circle(Vector2.ZERO, 4.0, Color.BLACK)
	# Burning fuse tip
	var fuse_col := Color(1.0, 0.8, 0.1) if (int(fuse_time * 10.0) % 2 == 0) else Color.WHITE
	draw_circle(Vector2(0, -7), 2.0, fuse_col)

func deflect(by_actor: Node = null) -> void:
	if is_deflected or _exploded:
		return
	is_deflected = true

	if source_bomber != null and is_instance_valid(source_bomber) and source_bomber is Node2D:
		var target_pos: Vector2 = (source_bomber as Node2D).global_position
		var dir := (target_pos - global_position).normalized()
		velocity = dir * 380.0 + Vector2(0, -100.0)
	else:
		velocity.x = -velocity.x * 1.3
		velocity.y = -abs(velocity.y) - 80.0

	fuse_time = maxf(fuse_time, 1.5) # Reset fuse to give room to strike
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if _exploded:
		return
	if is_deflected:
		if body != null and body.is_in_group(&"enemies"):
			explode()
		elif body != null and not body.is_in_group(&"player"):
			explode()
	else:
		if body != null and body.is_in_group(&"player"):
			explode()
		elif body != null:
			# Bounce lightly on floor until fuse expires, or explode on direct impact
			velocity.y = -velocity.y * 0.4
			velocity.x *= 0.7

func _on_area_entered(area: Area2D) -> void:
	if _exploded:
		return
	if is_deflected and area.is_in_group(&"enemies"):
		explode()
	elif not is_deflected and area.is_in_group(&"player"):
		explode()

func explode() -> void:
	if _exploded:
		return
	_exploded = true

	# Emit loud acoustic explosion
	if NoiseBus != null:
		var ev := NoiseEvent.make(global_position, 320.0, 2.5, NoiseEvent.NoiseType.COMBAT, null)
		NoiseBus.emit_noise(ev)

	# Shatter glass in radius
	var glass_nodes := get_tree().get_nodes_in_group(&"glass")
	for g in glass_nodes:
		if g is Node2D and (g as Node2D).global_position.distance_to(global_position) <= explosion_radius:
			if g.has_method("shatter"):
				g.call("shatter")

	# Damage entities in explosion radius
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = explosion_radius
	query.shape = circle
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = 8 | 4 # enemies and player hurtboxes

	var hits := space_state.intersect_shape(query, 16)
	for hit in hits:
		var collider: Object = hit.get("collider")
		if collider is Area2D:
			var parent := (collider as Node).get_parent()
			if is_deflected:
				if parent != null and parent.is_in_group(&"enemies"):
					var hc: Node = parent.get_node_or_null("HealthComponent")
					if hc != null and hc.has_method("take_damage"):
						hc.call("take_damage", damage * 2, (parent.global_position - global_position).normalized() * 200.0, &"deflected_bomb")
					elif parent.has_method("die"):
						parent.call("die", &"deflected_bomb")
			else:
				if parent != null and parent.is_in_group(&"player"):
					var hc: Node = parent.get_node_or_null("HealthComponent")
					if hc != null and hc.has_method("take_damage"):
						hc.call("take_damage", damage, (parent.global_position - global_position).normalized() * 150.0, &"bomb_blast")
					elif parent.has_method("die"):
						parent.call("die", &"bomb_blast")

	queue_free()
