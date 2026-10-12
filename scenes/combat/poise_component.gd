class_name PoiseComponent
extends Node

## PoiseComponent
## Tracks balance/poise meter (0.0 to 100.0), regenerative posture,
## and triggers stagger or guard-break states upon depletion.

signal poise_changed(current: float, max_poise: float)
signal staggered(duration: float)
signal recovered
signal guard_broken

@export var max_poise: float = 100.0
@export var current_poise: float = 100.0
@export var poise_regen_rate: float = 25.0
@export var regen_delay: float = 1.5
@export var default_stagger_duration: float = 0.60

var is_staggered: bool = false
var _delay_timer: float = 0.0
var _stagger_timer: float = 0.0


func _ready() -> void:
	current_poise = max_poise


func _process(delta: float) -> void:
	if is_staggered:
		_stagger_timer -= delta
		if _stagger_timer <= 0.0:
			is_staggered = false
			reset_poise()
			recovered.emit()
		return

	if _delay_timer > 0.0:
		_delay_timer -= delta
	elif current_poise < max_poise:
		current_poise = minf(max_poise, current_poise + poise_regen_rate * delta)
		poise_changed.emit(current_poise, max_poise)


## Damages poise meter. Returns true if guard was broken / entity staggered.
func damage_poise(amount: float, stagger_dur: float = -1.0) -> bool:
	_delay_timer = regen_delay
	current_poise = maxf(0.0, current_poise - amount)
	poise_changed.emit(current_poise, max_poise)

	if current_poise <= 0.0 and not is_staggered:
		is_staggered = true
		var duration: float = stagger_dur if stagger_dur > 0.0 else default_stagger_duration
		_stagger_timer = duration
		guard_broken.emit()
		staggered.emit(duration)
		return true

	return false


## Resets poise back to maximum.
func reset_poise() -> void:
	current_poise = max_poise
	_delay_timer = 0.0
	poise_changed.emit(current_poise, max_poise)
