class_name JammerTower
extends StaticBody2D

## JammerTower
## Stationary fortified electronic warfare pylon.
## Emits a 240px active jamming aura that disrupts player sonar pulse and minimap.
## 3-hit structure, registered in EnemyRegistry as an objective hostile.

signal destroyed

@export var jam_radius: float = 240.0

@onready var health_component: HealthComponent = $HealthComponent
@onready var poise_component: PoiseComponent = $PoiseComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var visual: Node2D = $Visual

func _ready() -> void:
	add_to_group(&"enemies")
	add_to_group(&"jammers")

	if EnemyRegistry != null:
		EnemyRegistry.register_enemy(self)

	if health_component != null:
		health_component.max_health = 3
		health_component.current_health = 3
		health_component.damaged.connect(_on_damaged)
		health_component.died.connect(_on_died)

func _on_damaged(_amount: int, _knockback: Vector2) -> void:
	if visual != null and visual.has_method("flash"):
		visual.call("flash")
	if NoiseBus != null:
		var ev := NoiseEvent.make(global_position, 140.0, 1.2, NoiseEvent.NoiseType.CLINK, self)
		NoiseBus.emit_noise(ev)

func _on_died(cause: StringName) -> void:
	destroyed.emit()
	if EnemyRegistry != null:
		EnemyRegistry.unregister_enemy(self, cause)
	if NoiseBus != null:
		var ev := NoiseEvent.make(global_position, 280.0, 2.2, NoiseEvent.NoiseType.COMBAT, self)
		NoiseBus.emit_noise(ev)
	queue_free()

func die(cause: StringName = &"destroyed") -> void:
	if health_component != null:
		health_component.take_damage(99, Vector2.ZERO, cause)
	else:
		_on_died(cause)

func is_player_in_jam_range(player_pos: Vector2) -> bool:
	return global_position.distance_to(player_pos) <= jam_radius
