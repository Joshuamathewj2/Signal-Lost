class_name Battery
extends Node

signal energy_changed(value: float, max_value: float)

var energy: float = 100.0
var max_energy: float = 100.0
var is_still: bool = false
var is_charging: bool = false
var regen_delay_timer: float = 0.0

func _ready() -> void:
	if GameConfig != null and GameConfig.data != null:
		max_energy = GameConfig.data.battery_max
		energy = max_energy

func _process(delta: float) -> void:
	if regen_delay_timer > 0.0:
		regen_delay_timer -= delta
		return

	if is_charging:
		return

	var cfg: GameConfigData = GameConfig.data
	var rate: float = cfg.regen_still if is_still else cfg.regen_moving
	var new_energy: float = minf(energy + rate * delta, max_energy)
	if absf(new_energy - energy) > 0.0001:
		energy = new_energy
		energy_changed.emit(energy, max_energy)

func try_spend(cost: float) -> bool:
	if energy >= cost:
		energy -= cost
		if GameConfig != null and GameConfig.data != null:
			regen_delay_timer = GameConfig.data.regen_delay
		energy_changed.emit(energy, max_energy)
		return true
	return false
