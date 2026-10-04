extends Node

signal noise_emitted(event: NoiseEvent)

func emit_noise(event: NoiseEvent) -> void:
	noise_emitted.emit(event)
	DebugFlags.log(&"noise", "Noise emitted type=%d at %s r=%.1f" % [event.type, str(event.position), event.radius])
