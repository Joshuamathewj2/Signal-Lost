class_name KunaiProjectile
extends Area2D

## KunaiProjectile
## Thrown stealth ninja kunai sub-weapon traveling at 600 px/s.
## Has a tiny 40 px acoustic radius for silent takedowns and inflicts a 1.5s stun on target impact.

signal impacted(at_position: Vector2, hit_entity: Node)

@export var speed: float = 600.0
@export var damage: int = 1
@export var poise_damage: float = 35.0
@export var stun_duration: float = 1.5
@export var noise_radius: float = 40.0
@export var max_lifetime: float = 2.0

var direction: Vector2 = Vector2.RIGHT
var is_stuck: bool = false
var _lifetime: float = 0.0


func _ready() -> void:
	z_index = 20
	collision_layer = 32 # Layer 6: projectile
	collision_mask = 1 | 8 # Layer 1: world, Layer 4: enemy

	if get_node_or_null("CollisionShape2D") == null:
		var col_shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 5.0
		col_shape.shape = circle
		add_child(col_shape)

	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if is_stuck:
		return

	_lifetime += delta
	if _lifetime >= max_lifetime:
		queue_free()
		return

	global_position += direction * speed * delta
	rotation = direction.angle()


func _draw() -> void:
	# Draw sleek aerodynamic kunai blade with ring handle
	# Blade diamond
	var blade_pts := PackedVector2Array([
		Vector2(10.0, 0.0),
		Vector2(2.0, -3.5),
		Vector2(-4.0, 0.0),
		Vector2(2.0, 3.5)
	])
	draw_colored_polygon(blade_pts, Color(0.92, 0.98, 1.0, 1.0))
	# Central ridge line
	draw_line(Vector2(-4.0, 0.0), Vector2(10.0, 0.0), Color(0.5, 0.6, 0.7, 1.0), 1.0)
	# Handle grip
	draw_line(Vector2(-4.0, 0.0), Vector2(-10.0, 0.0), Color(0.3, 0.35, 0.4, 1.0), 2.0)
	# Pommel ring
	draw_arc(Vector2(-12.0, 0.0), 2.5, 0.0, TAU, 12, Color(0.85, 0.9, 1.0, 1.0), 1.2)


func _on_body_entered(body: Node) -> void:
	if is_stuck:
		return
	_handle_impact(body)


func _on_area_entered(area: Area2D) -> void:
	if is_stuck:
		return
	if area is HurtboxComponent:
		_handle_impact(area.get_parent())


func _handle_impact(entity: Node) -> void:
	is_stuck = true

	# Emit silent acoustic lure (40 px radius per spec)
	if NoiseBus != null:
		var ev := NoiseEvent.make(global_position, noise_radius, 0.6, NoiseEvent.NoiseType.COMBAT, self)
		NoiseBus.emit_noise(ev)

	if entity != null:
		var hc: Node = entity.get_node_or_null("HealthComponent")
		if hc != null and hc.has_method("take_damage"):
			hc.call("take_damage", damage, direction * 60.0, &"kunai")

		var pc: Node = entity.get_node_or_null("PoiseComponent")
		if pc != null and pc.has_method("damage_poise"):
			pc.call("damage_poise", poise_damage)

		# Apply 1.5s stun to hit enemy
		if entity.has_method("stagger"):
			entity.call("stagger", stun_duration)
		elif entity.has_method("stun"):
			entity.call("stun", stun_duration)
		elif entity.has_method("apply_stun"):
			entity.call("apply_stun", stun_duration)

	impacted.emit(global_position, entity)

	if is_inside_tree() and get_tree() != null:
		var timer := get_tree().create_timer(0.2)
		timer.timeout.connect(queue_free)
	else:
		queue_free()
