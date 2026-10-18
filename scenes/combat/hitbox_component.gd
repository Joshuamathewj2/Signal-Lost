class_name HitboxComponent
extends Area2D

## HitboxComponent
## Area2D specialization that inflicts typed damage, poise trauma, and knockback
## upon intersecting an active HurtboxComponent.

signal hit_landed(target: Area2D)

@export var damage: int = 1
@export var poise_damage: float = 20.0
@export var knockback_force: float = 250.0
@export var hitstop_duration: float = 0.08
@export var attack_data: AttackData
@export var is_active: bool = false

var hit_targets: Array[Area2D] = []


func _ready() -> void:
	# Ensure mask includes layer 4 (enemies) and layer 5 (interactables)
	set_collision_mask_value(4, true)
	set_collision_mask_value(5, true)
	monitoring = is_active
	monitorable = is_active
	area_entered.connect(_on_area_entered)


func activate() -> void:
	hit_targets.clear()
	is_active = true
	monitoring = true
	monitorable = true


func deactivate() -> void:
	is_active = false
	monitoring = false
	monitorable = false
	hit_targets.clear()


func _on_area_entered(area: Area2D) -> void:
	if not is_active:
		return
	if hit_targets.has(area):
		return
	if area.has_method("receive_hit"):
		hit_targets.append(area)
		var applied: bool = area.receive_hit(self)
		if applied:
			hit_landed.emit(area)
	elif area.has_method("on_hit"):
		hit_targets.append(area)
		area.on_hit(self)
		hit_landed.emit(area)
