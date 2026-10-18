class_name FloorSpikes
extends TrapBase

## FloorSpikes
## Floor-mounted concealed spike trap.
## Triggered by proximity/pressure; after a 0.5s tell, spikes shoot up dealing 2 DMG.
## Can be disarmed by stealth Whisper pulse (tier 1).

func _init() -> void:
	if data == null:
		data = TrapData.new(&"floor_spikes", 2, 0.50, 2.0, 40.0, 0.5, true)
		data.display_name = "Floor Spikes"
		data.can_be_disarmed = true
		data.disarm_frequency = 1 # Whisper pulse
		data.poise_damage = 50.0

func _enter_active_state() -> void:
	current_state = State.ACTIVE
	state_timer = data.active_time

	if danger_marker != null:
		danger_marker.visible = false
	if damage_area != null:
		damage_area.monitoring = true
		damage_area.monitorable = true

	# Play rising then full
	if _has_anim(&"rising"):
		_play_anim(&"rising")
		if sprite != null and not sprite.animation_finished.is_connected(_on_rising_finished):
			sprite.animation_finished.connect(_on_rising_finished, CONNECT_ONE_SHOT)
	else:
		_play_anim(&"full")

	if NoiseBus != null:
		var loud_ev := NoiseEvent.make(global_position, data.noise_radius, data.noise_loudness, NoiseEvent.NoiseType.IMPACT, self)
		NoiseBus.emit_noise(loud_ev)

	_check_active_overlaps()

func _on_rising_finished() -> void:
	if current_state == State.ACTIVE:
		_play_anim(&"full")
