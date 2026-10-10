class_name NoiseMemory
extends Node

@export var profile: EnemyProfile

var entries: Array[Dictionary] = []

func push_noise(event: NoiseEvent, strength: float) -> void:
	if event == null:
		return

	_cleanup_expired()

	var now_sec: float = float(Time.get_ticks_msec()) / 1000.0
	var new_entry: Dictionary = {
		"pos": event.position,
		"time": now_sec,
		"strength": strength,
		"loudness": event.loudness,
		"type": event.type
	}

	for e in entries:
		if (e["pos"] as Vector2).distance_to(event.position) < 48.0:
			e["time"] = now_sec
			e["strength"] = strength
			e["loudness"] = event.loudness
			return

	entries.append(new_entry)

	var max_size: int = profile.memory_size if profile != null else 1
	while entries.size() > max_size:
		entries.pop_front()

func pop_oldest() -> Dictionary:
	_cleanup_expired()
	if entries.is_empty():
		return {}
	return entries.pop_front()

func _cleanup_expired() -> void:
	var now_sec: float = float(Time.get_ticks_msec()) / 1000.0
	var expiry: float = GameConfig.data.memory_expiry if (GameConfig != null and GameConfig.data != null) else 20.0
	var i: int = entries.size() - 1
	while i >= 0:
		if now_sec - entries[i]["time"] > expiry:
			entries.remove_at(i)
		i -= 1

func get_latest() -> Dictionary:
	_cleanup_expired()
	if entries.is_empty():
		return {}
	return entries.back()

func get_all() -> Array[Dictionary]:
	_cleanup_expired()
	return entries.duplicate()

func clear() -> void:
	entries.clear()
