extends Node

signal run_stats_changed(stats: Dictionary)
signal detected
signal level_completed(stats: Dictionary)
signal decoy_count_changed(n: int)
signal keycard_changed(has_it: bool)

var level_index: int = 1
var has_keycard: bool = false:
	set(val):
		has_keycard = val
		keycard_changed.emit(has_keycard)

var decoy_count: int = 0:
	set(val):
		decoy_count = val
		decoy_count_changed.emit(decoy_count)

var alert_level: float = 0.0

var stats: Dictionary = {
	"time": 0.0,
	"pulses": {0: 0, 1: 0, 2: 0},
	"loudest": 0,
	"detections": 0,
	"fragments": []
}

func reset_run() -> void:
	has_keycard = false
	stats = {
		"time": 0.0,
		"pulses": {0: 0, 1: 0, 2: 0},
		"loudest": 0,
		"detections": 0,
		"fragments": []
	}
	run_stats_changed.emit(stats)

func collect_fragment(id: int) -> void:
	if not stats["fragments"].has(id):
		stats["fragments"].append(id)
		run_stats_changed.emit(stats)

func register_detection(_enemy: Node = null) -> void:
	stats["detections"] += 1
	detected.emit()
	run_stats_changed.emit(stats)

func complete_level() -> void:
	level_completed.emit(stats)
