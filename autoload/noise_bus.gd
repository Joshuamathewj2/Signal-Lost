extends Node

signal noise_emitted(event: NoiseEvent)

func emit_noise(event: NoiseEvent) -> void:
	noise_emitted.emit(event)
	DebugFlags.log(&"noise", "Noise emitted type=%d at %s r=%.1f loud=%.2f" % [event.type, str(event.position), event.radius, event.loudness])

	var listeners: Array[Node] = get_tree().get_nodes_in_group(&"listeners")
	for l in listeners:
		if l.has_method("consider"):
			l.call("consider", event)
