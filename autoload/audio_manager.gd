extends Node

var library: Dictionary = {}
var player_pool: Array[AudioStreamPlayer] = []
var player_2d_pool: Array[AudioStreamPlayer2D] = []
var pulse_player: AudioStreamPlayer = null
var pulse_reverb_fx: AudioEffectReverb = null

func _ready() -> void:
	library = SfxLibrary.build()

	# 1. Non-positional SFX player pool (12)
	for i in range(12):
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		player_pool.append(p)

	# 2. Positional SFX player pool (8)
	for i in range(8):
		var p2d := AudioStreamPlayer2D.new()
		p2d.bus = &"SFX"
		p2d.attenuation = 1.5
		add_child(p2d)
		player_2d_pool.append(p2d)

	# 3. Dedicated Pulse player
	pulse_player = AudioStreamPlayer.new()
	pulse_player.bus = &"Pulse"
	add_child(pulse_player)

	# 4. Find Pulse Reverb effect
	var pulse_bus_idx: int = AudioServer.get_bus_index(&"Pulse")
	if pulse_bus_idx != -1:
		for j in range(AudioServer.get_bus_effect_count(pulse_bus_idx)):
			var fx: AudioEffect = AudioServer.get_bus_effect(pulse_bus_idx, j)
			if fx is AudioEffectReverb:
				pulse_reverb_fx = fx as AudioEffectReverb
				break

	# 5. Connect signals
	if NoiseBus != null and NoiseBus.has_signal("noise_emitted"):
		NoiseBus.noise_emitted.connect(_on_noise_emitted)

	if SceneRouter != null and SceneRouter.has_signal("level_loaded"):
		SceneRouter.level_loaded.connect(_on_level_loaded)

	if GameState != null:
		if GameState.has_signal("keycard_changed"):
			GameState.keycard_changed.connect(func(has_it: bool) -> void:
				if has_it:
					play_sfx(&"key_pickup")
			)
		if GameState.has_signal("level_completed"):
			GameState.level_completed.connect(func(_stats: Dictionary) -> void:
				play_sfx(&"terminal_restore")
			)

func _on_level_loaded(_root: Node) -> void:
	var p: Node = get_tree().get_first_node_in_group(&"player")
	if p != null:
		var charger: PulseCharger = p.get_node_or_null("PulseCharger") as PulseCharger
		if charger != null:
			if not charger.pulse_released.is_connected(_on_pulse_released):
				charger.pulse_released.connect(_on_pulse_released)
			if not charger.pulse_failed.is_connected(_on_pulse_failed):
				charger.pulse_failed.connect(_on_pulse_failed)

func _on_pulse_released(profile: PulseProfile, _origin: Vector2) -> void:
	if profile == null:
		return
	var tier: int = 0
	if profile.id == &"normal":
		tier = 1
	elif profile.id == &"scream":
		tier = 2
	set_pulse_reverb(tier)

	var sfx_id: StringName = &"ping_whisper"
	if tier == 1:
		sfx_id = &"ping_normal"
	elif tier == 2:
		sfx_id = &"ping_scream"

	if library.has(sfx_id) and pulse_player != null:
		pulse_player.stream = library[sfx_id]
		pulse_player.play()

func _on_pulse_failed() -> void:
	play_sfx(&"pulse_fail")

func _on_noise_emitted(event: NoiseEvent) -> void:
	if event == null:
		return
	match event.type:
		NoiseEvent.NoiseType.FOOTSTEP:
			play_sfx(&"step_soft", event.position, randf_range(0.96, 1.04))
		NoiseEvent.NoiseType.LAND:
			play_sfx(&"land", event.position)
		NoiseEvent.NoiseType.GLASS:
			play_sfx(&"glass_break", event.position)
		NoiseEvent.NoiseType.CLINK:
			play_sfx(&"lantern_clink", event.position, randf_range(0.96, 1.04))
		NoiseEvent.NoiseType.PLATE:
			play_sfx(&"plate_click", event.position)
		NoiseEvent.NoiseType.IMPACT:
			play_sfx(&"sentry_fire", event.position)

func set_pulse_reverb(tier: int) -> void:
	if pulse_reverb_fx == null:
		return
	match tier:
		0:
			pulse_reverb_fx.room_size = 0.2
			pulse_reverb_fx.wet = 0.1
		1:
			pulse_reverb_fx.room_size = 0.55
			pulse_reverb_fx.wet = 0.25
		2:
			pulse_reverb_fx.room_size = 0.95
			pulse_reverb_fx.wet = 0.45

func play_sfx(id: StringName, pos: Vector2 = Vector2.INF, pitch: float = 1.0) -> void:
	if not library.has(id):
		return

	var stream: AudioStream = library[id]

	if pos != Vector2.INF:
		for p2d in player_2d_pool:
			if not p2d.playing:
				p2d.stream = stream
				p2d.global_position = pos
				p2d.pitch_scale = pitch
				p2d.play()
				return
		# If all busy, steal first
		var stolen2d: AudioStreamPlayer2D = player_2d_pool[0]
		stolen2d.stream = stream
		stolen2d.global_position = pos
		stolen2d.pitch_scale = pitch
		stolen2d.play()
	else:
		for p in player_pool:
			if not p.playing:
				p.stream = stream
				p.pitch_scale = pitch
				p.play()
				return
		# If all busy, steal first
		var stolen: AudioStreamPlayer = player_pool[0]
		stolen.stream = stream
		stolen.pitch_scale = pitch
		stolen.play()
