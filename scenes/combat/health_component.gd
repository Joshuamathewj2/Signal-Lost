class_name HealthComponent
extends Node

## HealthComponent
## Manages integer health segments, temporary invulnerability frames (i-frames),
## and damage/death signals across players, adversaries, and destructible entities.

signal health_changed(current: int, max_health: int)
signal damaged(amount: int, knockback: Vector2)
signal died(cause: StringName)
signal invulnerability_changed(is_invuln: bool)

@export var max_health: int = 3
@export var current_health: int = 3
@export var invulnerability_duration: float = 1.2

var is_invulnerable: bool = false
var _invuln_timer: float = 0.0


func _ready() -> void:
	current_health = max_health


func _process(delta: float) -> void:
	if is_invulnerable:
		_invuln_timer -= delta
		if _invuln_timer <= 0.0:
			is_invulnerable = false
			invulnerability_changed.emit(false)


## Applies damage and optional knockback impulse.
## Returns true if damage was applied, false if blocked by invulnerability or entity already dead.
func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO, cause: StringName = &"hit") -> bool:
	if not is_alive():
		return false
	if is_invulnerable and amount > 0:
		return false

	current_health = maxi(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	damaged.emit(amount, knockback)

	if current_health <= 0:
		died.emit(cause)
	elif amount > 0 and invulnerability_duration > 0.0:
		start_invulnerability(invulnerability_duration)

	return true


## Starts an invulnerability window for the specified duration in seconds.
func start_invulnerability(duration: float) -> void:
	is_invulnerable = true
	_invuln_timer = duration
	invulnerability_changed.emit(true)


## Restores health up to max_health.
func heal(amount: int) -> void:
	if not is_alive():
		return
	current_health = mini(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)


## Returns whether the entity is still alive.
func is_alive() -> bool:
	return current_health > 0


## Resets health back to max.
func reset() -> void:
	current_health = max_health
	is_invulnerable = false
	_invuln_timer = 0.0
	health_changed.emit(current_health, max_health)
	invulnerability_changed.emit(false)
