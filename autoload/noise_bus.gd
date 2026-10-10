extends Node

signal noise_emitted(event: NoiseEvent)

func emit_noise_event(event: NoiseEvent) -> void:
	emit_noise(event)

func emit_noise(event: NoiseEvent) -> void:
	# Vent routing: if event within 96 px of an intake and event.source is not a vent -> after 0.2s emit at outlet
	if not (event.source is Vent):
		var intakes: Array[Node] = get_tree().get_nodes_in_group(&"vent_intakes")
		for intake_node in intakes:
			if intake_node is Vent:
				var intake: Vent = intake_node as Vent
				if intake.outlet != null and event.position.distance_to(intake.global_position + Vector2(16, 16)) <= 96.0:
					var out_vent: Vent = intake.outlet
					var out_r: float = maxf(event.radius * 4.0, 240.0)
					var out_loud: float = event.loudness + 1.5
					var out_type: int = event.type
					get_tree().create_timer(0.2).timeout.connect(func() -> void:
						if is_instance_valid(out_vent):
							var vent_ev := NoiseEvent.make(out_vent.global_position + Vector2(16, 16), out_r, out_loud, out_type, out_vent)
							emit_noise(vent_ev)
					)

	noise_emitted.emit(event)
	DebugFlags.log(&"noise", "Noise emitted type=%d at %s r=%.1f loud=%.2f" % [event.type, str(event.position), event.radius, event.loudness])

	var listeners: Array[Node] = get_tree().get_nodes_in_group(&"listeners")
	for l in listeners:
		if l.has_method("consider"):
			l.call("consider", event)
