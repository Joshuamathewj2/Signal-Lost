class_name WeaponSwapManager
extends Node

## WeaponSwapManager
## Cycles active weapon between Katana, Naginata, and Kunai on 'weapon_swap' (Q / D-Pad Up).
## Notifies CombatController and HUD of the active weapon archetype.

signal weapon_swapped(weapon_type: WeaponType, weapon_name: StringName)

enum WeaponType {
	KATANA = 0,
	NAGINATA = 1,
	KUNAI = 2
}

@export var current_weapon: WeaponType = WeaponType.KATANA
var unlocked_weapons: Array[WeaponType] = [WeaponType.KATANA, WeaponType.NAGINATA, WeaponType.KUNAI]


func _unhandled_input(event: InputEvent) -> void:
	var parent_body: Node = get_parent()
	if parent_body != null and "is_alive" in parent_body and not bool(parent_body.get("is_alive")):
		return

	if event.is_action_pressed(&"weapon_swap"):
		cycle_weapon()


func cycle_weapon() -> WeaponType:
	var current_idx: int = unlocked_weapons.find(current_weapon)
	if current_idx == -1:
		current_idx = 0
	var next_idx: int = (current_idx + 1) % unlocked_weapons.size()
	current_weapon = unlocked_weapons[next_idx]
	weapon_swapped.emit(current_weapon, get_weapon_name(current_weapon))
	return current_weapon


func set_weapon(type: WeaponType) -> void:
	if current_weapon != type and unlocked_weapons.has(type):
		current_weapon = type
		weapon_swapped.emit(current_weapon, get_weapon_name(current_weapon))


static func get_weapon_name(type: WeaponType) -> StringName:
	match type:
		WeaponType.KATANA:
			return &"Katana"
		WeaponType.NAGINATA:
			return &"Naginata"
		WeaponType.KUNAI:
			return &"Kunai"
	return &"Unknown"
