class_name Shuriken
extends Area2D

## Shuriken
## Thrown sub-weapon projectile traveling at 580 px/s.
## Damages enemies or impacts terrain to create a 120 px acoustic distraction ripple.

signal impacted(at_position: Vector2, hit_entity: Node)

@export var speed: float = 580.0
@export var damage: int = 1
@export var poise_damage: float = 10.0
@export var noise_radius: float = 120.0
@export var max_lifetime: float = 2.0

var direction: Vector2 = Vector2.RIGHT
var is_stuck: bool = false
var _lifetime: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 4 | 8 # Solvers, enemies, world
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

	# Emit noise distraction lure
	if NoiseBus != null:
		var ev := NoiseEvent.make(global_position, noise_radius, 1.2, NoiseEvent.NoiseType.COMBAT, self)
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
		var timer := get_tree().create_timer(0.3)
		timer.timeout.connect(queue_free)
	else:
		queue_free()
