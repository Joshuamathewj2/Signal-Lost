class_name Bomber
extends EnemyBase

## Bomber
## Ranged demolitionist that lobs arc-trajectory timed bombs.
## Bombs explode after a fuse or upon impact, dealing AoE damage and shattering glass.
## Player can parry the bomb mid-air to deflect it back at enemies or obstacles.

signal bomb_thrown(bomb: Node)

const BOMB_SCENE: PackedScene = preload("res://scenes/combat/bomb.tscn")

var throw_cooldown: float = 0.0
var throw_interval: float = 2.4

func _ready() -> void:
	kind = &"bomber"
	super._ready()
	if health_component != null:
		health_component.max_health = 2
		health_component.current_health = 2
	if poise_component != null:
		poise_component.max_poise = 40.0
		poise_component.current_poise = 40.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if throw_cooldown > 0.0:
		throw_cooldown -= delta

	# Check for throwing opportunity when player is spotted
	if throw_cooldown <= 0.0 and awareness != null and awareness.is_alert:
		var target := _get_target_pos()
		var dist := global_position.distance_to(target)
		if dist >= 40.0 and dist <= 260.0:
			attempt_throw(target)

func _get_target_pos() -> Vector2:
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player != null and is_instance_valid(player):
		return player.global_position
	return global_position + Vector2(float(facing) * 100.0, 0)

func attempt_throw(target_pos: Vector2) -> void:
	throw_cooldown = throw_interval
	face(1 if target_pos.x > global_position.x else -1)

	var vis := get_node_or_null("Visual")
	if vis != null and vis.has_method("animate_throw"):
		vis.call("animate_throw", func() -> void:
			_spawn_bomb(target_pos)
		)
	else:
		_spawn_bomb(target_pos)

func _spawn_bomb(target_pos: Vector2) -> void:
	var bomb := BOMB_SCENE.instantiate() as Area2D
	if bomb == null:
		return

	var spawn_offset := Vector2(float(facing) * 12.0, -14.0)
	bomb.global_position = global_position + spawn_offset
	bomb.set("source_bomber", self)

	# Calculate arc velocity
	var dx := target_pos.x - bomb.global_position.x
	var dy := target_pos.y - bomb.global_position.y
	var time_to_target := clampf(abs(dx) / 180.0, 0.4, 1.0)
	var vx := dx / time_to_target
	var vy := (dy - 0.5 * 600.0 * time_to_target * time_to_target) / time_to_target

	bomb.set("velocity", Vector2(vx, vy))

	get_parent().add_child(bomb)
	bomb_thrown.emit(bomb)

	if NoiseBus != null:
		var ev := NoiseEvent.make(global_position, 80.0, 0.8, NoiseEvent.NoiseType.COMBAT, self)
		NoiseBus.emit_noise(ev)
