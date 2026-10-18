extends Node

signal noise_emitted(event: NoiseEvent)

## Intensity front-end (0.0-1.0, data/noise.json) over the radius/loudness bus.
## Hearing still applies distance falloff + wall attenuation per listener.
func emit_intensity(source: Node, pos: Vector2, intensity: float, tag: StringName = &"", n_type: int = NoiseEvent.NoiseType.COMBAT) -> NoiseEvent:
	var cfg: Dictionary = CombatTuning.noise()
	var i: float = clampf(intensity, 0.0, 1.0)
	var ev := NoiseEvent.make(pos, i * float(cfg.get("intensity_to_radius", 400.0)), i * float(cfg.get("intensity_to_loudness", 2.5)), n_type as NoiseEvent.NoiseType, source)
	ev.tag = tag
	emit_noise(ev)
	return ev


## Emits the intensity configured for a hero/villain action tag (noise.json "actions").
func emit_action(source: Node, pos: Vector2, tag: StringName, n_type: int = NoiseEvent.NoiseType.COMBAT) -> NoiseEvent:
	return emit_intensity(source, pos, CombatTuning.action_intensity(tag), tag, n_type)


func emit_noise_event(event: NoiseEvent) -> void:
	emit_noise(event)

func emit_noise_params(pos: Vector2, rad: float, loud: float, n_type: int = 0, src: Node = null) -> void:
	emit_noise(NoiseEvent.make(pos, rad, loud, n_type as NoiseEvent.NoiseType, src))

func emit_noise(event: NoiseEvent) -> void:
	# Vent routing: if event within 96 px of an intake and event.source is not a vent -> after 0.2s emit at outlet
	var is_source_vent: bool = event.source != null and (event.source.is_in_group(&"vent_intakes") or event.source.is_in_group(&"vent_outlets") or event.source.is_in_group(&"vent_mutes"))
	if not is_source_vent:
		var intakes: Array[Node] = get_tree().get_nodes_in_group(&"vent_intakes")
		for intake_node in intakes:
			if intake_node is Node2D:
				var out_vent: Node2D = intake_node.get("outlet") as Node2D
				if out_vent != null and event.position.distance_to((intake_node as Node2D).global_position + Vector2(16, 16)) <= 96.0:
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
