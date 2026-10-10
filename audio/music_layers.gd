class_name MusicLayers
extends Node

var p_l0: AudioStreamPlayer
var p_l1: AudioStreamPlayer
var p_l2: AudioStreamPlayer
var p_l3: AudioStreamPlayer

var lpf_effect: AudioEffectLowPassFilter = null
var death_muffle_timer: float = 0.0

func _ready() -> void:
	# 1. Setup AudioStreamPlayers on Music bus
	p_l0 = AudioStreamPlayer.new()
	p_l0.bus = &"Music"
	p_l0.volume_db = -8.0
	add_child(p_l0)

	p_l1 = AudioStreamPlayer.new()
	p_l1.bus = &"Music"
	p_l1.volume_db = -80.0
	add_child(p_l1)

	p_l2 = AudioStreamPlayer.new()
	p_l2.bus = &"Music"
	p_l2.volume_db = -80.0
	add_child(p_l2)

	p_l3 = AudioStreamPlayer.new()
	p_l3.bus = &"Music"
	p_l3.volume_db = -80.0
	add_child(p_l3)

	# 2. Render 8s loops at boot
	p_l0.stream = _build_l0_drone()
	p_l1.stream = _build_l1_pulse()
	p_l2.stream = _build_l2_tension()
	p_l3.stream = _build_l3_chase()

	# Start all 4 synchronously
	p_l0.play()
	p_l1.play()
	p_l2.play()
	p_l3.play()

	# 3. Locate Music LPF
	var music_bus_idx: int = AudioServer.get_bus_index(&"Music")
	if music_bus_idx != -1:
		for i in range(AudioServer.get_bus_effect_count(music_bus_idx)):
			var fx: AudioEffect = AudioServer.get_bus_effect(music_bus_idx, i)
			if fx is AudioEffectLowPassFilter:
				lpf_effect = fx as AudioEffectLowPassFilter
				break

	if SceneRouter != null and SceneRouter.has_signal("level_loaded"):
		SceneRouter.level_loaded.connect(_on_level_loaded)

func _exit_tree() -> void:
	if p_l0 != null:
		p_l0.stop()
		p_l0.stream = null
	if p_l1 != null:
		p_l1.stop()
		p_l1.stream = null
	if p_l2 != null:
		p_l2.stop()
		p_l2.stream = null
	if p_l3 != null:
		p_l3.stop()
		p_l3.stream = null

func _on_level_loaded(_root: Node) -> void:
	var player: Node = get_tree().get_first_node_in_group(&"player")
	if player is Player:
		var pl: Player = player as Player
		if not pl.player_died.is_connected(_on_player_died):
			pl.player_died.connect(_on_player_died)

func _on_player_died(_cause: StringName) -> void:
	death_muffle_timer = 0.6
	if lpf_effect != null:
		lpf_effect.cutoff_hz = 800.0

func _process(delta: float) -> void:
	if death_muffle_timer > 0.0:
		death_muffle_timer -= delta
		if death_muffle_timer <= 0.0:
			death_muffle_timer = 0.0
			if lpf_effect != null:
				lpf_effect.cutoff_hz = 18000.0

	# Volume curve driving by alert level
	var alert: float = GameState.alert_level if GameState != null else 0.0
	var chasing: bool = GameState.is_any_enemy_chasing if GameState != null else false

	var tgt_l0: float = -8.0
	var tgt_l1: float = -12.0 if alert >= 0.2 else -80.0
	var tgt_l2: float = -10.0 if alert >= 0.5 else -80.0
	var tgt_l3: float = -6.0 if chasing else -80.0

	var fade_rate: float = 80.0 * delta / 0.8
	p_l0.volume_db = move_toward(p_l0.volume_db, tgt_l0, fade_rate)
	p_l1.volume_db = move_toward(p_l1.volume_db, tgt_l1, fade_rate)
	p_l2.volume_db = move_toward(p_l2.volume_db, tgt_l2, fade_rate)
	p_l3.volume_db = move_toward(p_l3.volume_db, tgt_l3, fade_rate)

func _build_l0_drone() -> AudioStreamWAV:
	# 55 Hz + 82.5 Hz sines, slow 0.1 Hz LFO, pink noise -30 dB
	var total: int = int(8.0 * 44100.0)
	var arr := PackedFloat32Array()
	arr.resize(total)
	for i in range(total):
		var t: float = float(i) / 44100.0
		var s1: float = sin(t * TAU * 55.0)
		var s2: float = sin(t * TAU * 82.5)
		var lfo: float = 0.8 + 0.2 * sin(t * TAU * 0.1)
		var n: float = randf_range(-0.03, 0.03)
		arr[i] = ((s1 + s2 * 0.7) * 0.3 * lfo) + n
	var wav: AudioStreamWAV = Synth.to_wav(arr)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = total
	return wav

func _build_l1_pulse() -> AudioStreamWAV:
	# Filtered noise heartbeat at 60 BPM (1 beat/sec)
	var total: int = int(8.0 * 44100.0)
	var arr := PackedFloat32Array()
	arr.resize(total)
	var beat_len: int = 44100
	for b in range(8):
		var start: int = b * beat_len
		var pulse_samples: int = int(0.12 * 44100.0)
		for j in range(pulse_samples):
			var idx: int = start + j
			if idx < total:
				var t: float = float(j) / 44100.0
				var env: float = exp(-t / 0.04)
				var s: float = sin(t * TAU * 60.0) * env * 0.4
				arr[idx] = s
	var wav: AudioStreamWAV = Synth.to_wav(arr)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = total
	return wav

func _build_l2_tension() -> AudioStreamWAV:
	# Detuned saw pad 110/116 Hz, low-passed 600 Hz
	var saw1 := Synth.saw(110.0, 8.0)
	var saw2 := Synth.saw(116.0, 8.0)
	for i in range(saw1.size()):
		saw1[i] = (saw1[i] + saw2[i]) * 0.25
	var filtered: PackedFloat32Array = Synth.lowpass_onepole(saw1, 600.0)
	var wav: AudioStreamWAV = Synth.to_wav(filtered)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = filtered.size()
	return wav

func _build_l3_chase() -> AudioStreamWAV:
	# 120 BPM kick (sine 60 Hz) + hat (noise 8 ms)
	var total: int = int(8.0 * 44100.0)
	var arr := PackedFloat32Array()
	arr.resize(total)
	var half_beat: int = int(0.5 * 44100.0)
	for b in range(16):
		var start: int = b * half_beat
		# Kick (0.08 s)
		for j in range(int(0.08 * 44100.0)):
			var idx: int = start + j
			if idx < total:
				var t: float = float(j) / 44100.0
				var env: float = exp(-t / 0.03)
				arr[idx] += sin(t * TAU * 60.0) * env * 0.5
		# Hat (8 ms)
		var hat_start: int = start + int(half_beat * 0.5)
		for j in range(int(0.008 * 44100.0)):
			var idx: int = hat_start + j
			if idx < total:
				arr[idx] += randf_range(-0.15, 0.15)
	var wav: AudioStreamWAV = Synth.to_wav(arr)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = total
	return wav
