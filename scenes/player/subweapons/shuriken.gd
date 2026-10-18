class_name Shuriken
extends Area2D

## Shuriken
## Thrown sub-weapon projectile traveling at 580 px/s.
## Features visible spinning 4-point star with unshaded material,
## CollisionShape2D for physics detection, and acoustic noise impact lure.

signal impacted(at_position: Vector2, hit_entity: Node)

@export var speed: float = 580.0
@export var damage: int = 1
@export var poise_damage: float = 10.0
@export var noise_radius: float = 120.0
@export var max_lifetime: float = 2.0

var direction: Vector2 = Vector2.RIGHT
var is_stuck: bool = false
var _lifetime: float = 0.0
var spin_angle: float = 0.0


func _ready() -> void:
	z_index = 20
	collision_layer = 32 # Layer 6: projectile
	collision_mask = 1 | 8 # Layer 1: world, Layer 4: enemy

	# Ensure CollisionShape2D exists even if created via Shuriken.new()
	if get_node_or_null("CollisionShape2D") == null:
		var col_shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 6.0
		col_shape.shape = circle
		add_child(col_shape)

	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	if not is_stuck:
		spin_angle += delta * 30.0
		queue_redraw()


func _physics_process(delta: float) -> void:
	if is_stuck:
		return

	_lifetime += delta
	if _lifetime >= max_lifetime:
		queue_free()
		return

	global_position += direction * speed * delta


func _draw() -> void:
	# Draw spinning 4-pointed metallic shuriken star (unshaded white/cyan)
	var r: float = 6.0
	var inner_r: float = 2.2
	var pts := PackedVector2Array()

	for i in range(8):
		var ang: float = spin_angle + float(i) * (PI / 4.0)
		var rad: float = r if (i % 2 == 0) else inner_r
		pts.append(Vector2(cos(ang) * rad, sin(ang) * rad))

	draw_colored_polygon(pts, Color(0.9, 0.98, 1.0, 1.0))
	draw_circle(Vector2.ZERO, 1.2, Color(0.1, 0.1, 0.1, 1.0))


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

	# Emit acoustic distraction lure for nearby guards to investigate
	if NoiseBus != null:
		var ev := NoiseEvent.make(global_position, noise_radius, 1.5, NoiseEvent.NoiseType.COMBAT, self)
		NoiseBus.emit_noise(ev)

	if entity != null:
		var hc: Node = entity.get_node_or_null("HealthComponent")
		if hc != null and hc.has_method("take_damage"):
			hc.call("take_damage", damage, direction * 80.0, &"shuriken")
		var pc: Node = entity.get_node_or_null("PoiseComponent")
		if pc != null and pc.has_method("damage_poise"):
			pc.call("damage_poise", poise_damage)

	impacted.emit(global_position, entity)

	# Fade out and free
	if is_inside_tree() and get_tree() != null:
		var timer := get_tree().create_timer(0.2)
		timer.timeout.connect(queue_free)
	else:
		queue_free()
