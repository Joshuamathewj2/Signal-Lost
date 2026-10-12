class_name Projectile
extends Area2D

## Projectile
## High-velocity plasma bolt fired by Sentry turrets.
## Can be deflected back into the turret via Katana frame-tight parry.

@export var speed: float = 420.0
@export var lifetime: float = 2.5
@export var damage: int = 1
@export var poise_damage: float = 20.0

var direction: Vector2 = Vector2.RIGHT
var is_deflected: bool = false
var source_turret: Node = null

var reticle_scene: PackedScene = preload("res://scenes/ui/world_reticle.tscn")
var reticle: Node2D = null


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(6, true)
	set_collision_mask_value(1, true)
	set_collision_mask_value(3, true)
	set_collision_mask_value(4, true)

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	reticle = reticle_scene.instantiate() as Node2D
	if reticle != null:
		if "reticle_type" in reticle:
			reticle.reticle_type = 0 # Type.PROJECTILE
		add_child(reticle)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _draw() -> void:
	var p_start := -direction * 4.0
	var p_end := direction * 4.0
	var col := Color.WHITE if is_deflected else Palette.color(&"danger")
	draw_line(p_start, p_end, col, 2.5)


## Deflects the projectile back towards the firing turret
func deflect(by_actor: Node = null) -> void:
	if is_deflected:
		return
	is_deflected = true

	if source_turret != null and is_instance_valid(source_turret) and source_turret is Node2D:
		direction = ((source_turret as Node2D).global_position - global_position).normalized()
	else:
		direction = -direction

	speed *= 1.2 # Accelerated return velocity
	queue_redraw()


func _on_area_entered(area: Area2D) -> void:
	if not is_deflected:
		if area is HurtboxComponent:
			var hit_success: bool = area.receive_hit(self)
			if not is_deflected and hit_success:
				queue_free()
	else:
		if area is HurtboxComponent and area.get_parent() != null and area.get_parent().is_in_group(&"enemies"):
			area.receive_hit(self)
			queue_free()


func _on_body_entered(body: Node2D) -> void:
	if is_deflected:
		if body != null and body.is_in_group(&"enemies"):
			var hc: Node = body.get_node_or_null("HealthComponent")
			if hc != null and hc.has_method("take_damage"):
				hc.call("take_damage", 99, direction * 200.0, &"deflected_bolt")
			elif body.has_method("die"):
				body.call("die")
			queue_free()
		elif body != null and not body.is_in_group(&"player"):
			_impact_terrain()
	else:
		if body != null and body.is_in_group(&"player"):
			var hurtbox: HurtboxComponent = body.get_node_or_null("HurtboxComponent") as HurtboxComponent
			if hurtbox != null:
				hurtbox.receive_hit(self)
				if not is_deflected:
					queue_free()
			elif body.has_method("die"):
				body.call("die", &"shot")
				queue_free()
		else:
			_impact_terrain()


func _impact_terrain() -> void:
	var noise_ev := NoiseEvent.make(global_position, 120.0, 1.5, NoiseEvent.NoiseType.IMPACT, null)
	NoiseBus.emit_noise_event(noise_ev)
	ParticlesFactory.spawn_projectile_impact(get_parent(), global_position)
	queue_free()
