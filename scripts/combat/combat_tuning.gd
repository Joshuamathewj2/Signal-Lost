class_name CombatTuning
extends RefCounted

## CombatTuning
## Typed access to data/combat.json and data/noise.json (cached by DataLoader).

const COMBAT_JSON: String = "res://data/combat.json"
const NOISE_JSON: String = "res://data/noise.json"


static func combat(section: String) -> Dictionary:
	return DataLoader.load_json(COMBAT_JSON).get(section, {})


static func noise() -> Dictionary:
	return DataLoader.load_json(NOISE_JSON)


static func weight(weight_class: StringName) -> Dictionary:
	var classes: Dictionary = combat("weight_classes")
	return classes.get(String(weight_class), classes.get("medium", {}))


static func action_intensity(tag: StringName) -> float:
	return float((noise().get("actions", {}) as Dictionary).get(String(tag), 0.0))


static func reaction(tag: StringName) -> Dictionary:
	return (noise().get("reactions", {}) as Dictionary).get(String(tag), {})


static func friendly_fire(kind: String) -> bool:
	return bool(combat("friendly_fire").get(kind, true))
