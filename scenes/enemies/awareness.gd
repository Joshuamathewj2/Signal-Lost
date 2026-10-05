class_name Awareness
extends Node

signal awareness_changed(new_val: float, old_val: float)

@export var profile: EnemyProfile

var value: float = 0.0

func _process(delta: float) -> void:
	var decay: float = profile.awareness_decay if profile != null else 0.15
	if value > 0.0:
		set_value(value - decay * delta)

func on_heard(_event: NoiseEvent, strength: float) -> void:
	var gain: float = profile.awareness_gain if profile != null else 0.6
	var delta_val: float = gain * (0.35 + 0.65 * strength)
	set_value(value + delta_val)

func on_spotted() -> void:
	set_value(1.0)

func set_value(v: float) -> void:
	var clamped: float = clampf(v, 0.0, 1.0)
	if not is_equal_approx(clamped, value):
		var old: float = value
		value = clamped
		awareness_changed.emit(value, old)
