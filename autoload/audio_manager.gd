extends Node

func play_sfx(id: StringName, pos: Vector2 = Vector2.INF, pitch: float = 1.0) -> void:
	DebugFlags.log(&"audio", "play_sfx: %s at %s (pitch: %.2f)" % [id, str(pos), pitch])

func set_pulse_reverb(tier: int) -> void:
	DebugFlags.log(&"audio", "set_pulse_reverb tier %d" % tier)
