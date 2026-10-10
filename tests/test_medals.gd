class_name TestMedals
extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []

	# Case 1: Ghost — 0 Normal, 0 Scream, 0 detections (whispers allowed)
	var stats_ghost_1: Dictionary = {
		"pulses": {&"whisper": 5, &"normal": 0, &"scream": 0},
		"detections": 0
	}
	var m1: StringName = GameState.compute_medal(stats_ghost_1)
	if m1 != &"ghost":
		failures.append("Expected ghost for 0 normal/0 scream/0 detections, got: %s" % str(m1))

	var stats_ghost_2: Dictionary = {
		"pulses": {0: 0, 1: 0, 2: 0},
		"detections": 0
	}
	var m2: StringName = GameState.compute_medal(stats_ghost_2)
	if m2 != &"ghost":
		failures.append("Expected ghost for empty pulses with 0 detections, got: %s" % str(m2))

	# Case 2: Quiet — 0 Scream, <= 1 detection (Normal pulses allowed)
	var stats_quiet_1: Dictionary = {
		"pulses": {&"whisper": 2, &"normal": 1, &"scream": 0},
		"detections": 0
	}
	var m3: StringName = GameState.compute_medal(stats_quiet_1)
	if m3 != &"quiet":
		failures.append("Expected quiet for 1 normal/0 scream/0 detections, got: %s" % str(m3))

	var stats_quiet_2: Dictionary = {
		"pulses": {&"whisper": 0, &"normal": 0, &"scream": 0},
		"detections": 1
	}
	var m4: StringName = GameState.compute_medal(stats_quiet_2)
	if m4 != &"quiet":
		failures.append("Expected quiet for 0 normal/0 scream/1 detection, got: %s" % str(m4))

	var stats_quiet_3: Dictionary = {
		"pulses": {&"whisper": 1, &"normal": 3, &"scream": 0},
		"detections": 1
	}
	var m5: StringName = GameState.compute_medal(stats_quiet_3)
	if m5 != &"quiet":
		failures.append("Expected quiet for 3 normal/0 scream/1 detection, got: %s" % str(m5))

	# Case 3: Loud — any scream, or > 1 detections
	var stats_loud_1: Dictionary = {
		"pulses": {&"whisper": 0, &"normal": 0, &"scream": 1},
		"detections": 0
	}
	var m6: StringName = GameState.compute_medal(stats_loud_1)
	if m6 != &"loud":
		failures.append("Expected loud for 1 scream/0 detections, got: %s" % str(m6))

	var stats_loud_2: Dictionary = {
		"pulses": {&"whisper": 0, &"normal": 0, &"scream": 0},
		"detections": 2
	}
	var m7: StringName = GameState.compute_medal(stats_loud_2)
	if m7 != &"loud":
		failures.append("Expected loud for 0 scream/2 detections, got: %s" % str(m7))

	var stats_loud_3: Dictionary = {
		"pulses": {&"whisper": 2, &"normal": 2, &"scream": 2},
		"detections": 3
	}
	var m8: StringName = GameState.compute_medal(stats_loud_3)
	if m8 != &"loud":
		failures.append("Expected loud for 2 scream/3 detections, got: %s" % str(m8))

	return failures
