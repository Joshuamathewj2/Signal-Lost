class_name Projectile
extends Area2D

@export var speed: float = 420.0
@export var lifetime: float = 2.5

var direction: Vector2 = Vector2.RIGHT
var reticle_scene: PackedScene = preload("res://scenes/ui/world_reticle.tscn")
var reticle: WorldReticle = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(6, true)
	set_collision_mask_value(1, true)
	set_collision_mask_value(3, true)

	body_entered.connect(_on_body_entered)

	reticle = reticle_scene.instantiate() as WorldReticle
	reticle.reticle_type = WorldReticle.Type.PROJECTILE
	add_child(reticle)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _draw() -> void:
	# 6x2 red streak
	var p_start := -direction * 3.0
	var p_end := direction * 3.0
	draw_line(p_start, p_end, Palette.color(&"danger"), 2.0)

func _on_body_entered(body: Node2D) -> void:
	if body is Player or body.is_in_group(&"player"):
		if body.has_method("die"):
			body.call("die", &"shot")
		queue_free()
	else:
		var noise_ev := NoiseEvent.make(global_position, 120.0, 1.5, NoiseEvent.NoiseType.IMPACT, null)
		NoiseBus.emit_noise_event(noise_ev)
		ParticlesFactory.spawn_projectile_impact(get_parent(), global_position)
		queue_free()
