class_name TestResources
extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []

	var tres_paths: Array[String] = [
		"res://resources/config/default_config.tres",
		"res://resources/pulses/pulse_whisper.tres",
		"res://resources/pulses/pulse_normal.tres",
		"res://resources/pulses/pulse_scream.tres",
		"res://resources/pulses/pulse_decoy.tres",
		"res://resources/enemies/enemy_listener.tres",
		"res://resources/enemies/enemy_sentry.tres",
		"res://resources/enemies/enemy_hunter.tres",
		"res://resources/enemies/enemy_brute.tres",
		"res://resources/theme/palette_default.tres",
		"res://resources/theme/palette_colorblind.tres",
		"res://resources/config/combat_config.tres"
	]

	for path in tres_paths:
		var res: Resource = load(path)
		if res == null:
			failures.append("Failed to load resource: %s" % path)

	# Check pulse profiles noise radii
	var whisper: PulseProfile = load("res://resources/pulses/pulse_whisper.tres") as PulseProfile
	var normal: PulseProfile = load("res://resources/pulses/pulse_normal.tres") as PulseProfile
	var scream: PulseProfile = load("res://resources/pulses/pulse_scream.tres") as PulseProfile

	if whisper != null:
		var r_whisper: float = whisper.noise_radius()
		if absf(r_whisper - 90.0) > 1.0:
			failures.append("Whisper noise radius expected ~90.0, got %f" % r_whisper)
	else:
		failures.append("whisper pulse is null")

	if normal != null:
		var r_normal: float = normal.noise_radius()
		if absf(r_normal - 350.0) > 1.0:
			failures.append("Normal noise radius expected ~350.0, got %f" % r_normal)
	else:
		failures.append("normal pulse is null")

	if scream != null:
		var r_scream: float = scream.noise_radius()
		if absf(r_scream - 910.0) > 1.0:
			failures.append("Scream noise radius expected ~910.0, got %f" % r_scream)
	else:
		failures.append("scream pulse is null")

	# Check MathUtil.bubble_brightness curve values
	if normal != null:
		var t_exp: float = normal.expand_time()
		var hold: float = normal.hold_time
		var fade: float = normal.fade_time

		var b_early: float = MathUtil.bubble_brightness(0.05, t_exp, hold, fade)
		if absf(b_early - 1.0) > 0.001:
			failures.append("bubble_brightness at t=0.05 expected 1.0, got %f" % b_early)

		var b_pre_ghost: float = MathUtil.bubble_brightness(t_exp + hold + fade - 0.01, t_exp, hold, fade)
		if b_pre_ghost >= 0.2 or b_pre_ghost < 0.0:
			failures.append("bubble_brightness before ghost expected in [0.0, 0.2), got %f" % b_pre_ghost)

		var b_dead: float = MathUtil.bubble_brightness(t_exp + hold + fade + 2.0 + 0.1, t_exp, hold, fade)
		if absf(b_dead - (-1.0)) > 0.001:
			failures.append("bubble_brightness when dead expected -1.0, got %f" % b_dead)

	# Verify UI Theme
	var ui_theme: Theme = load("res://resources/theme/ui_theme.tres") as Theme
	if ui_theme == null:
		failures.append("ui_theme.tres is null or failed to load")
	else:
		if ui_theme.default_font_size != 22:
			failures.append("ui_theme default_font_size expected 22, got %d" % ui_theme.default_font_size)
		if ui_theme.get_font_size(&"font_size", &"TitleLabel") != 96:
			failures.append("TitleLabel font_size expected 96, got %d" % ui_theme.get_font_size(&"font_size", &"TitleLabel"))
		if ui_theme.get_font_size(&"font_size", &"HudLabel") != 22:
			failures.append("HudLabel font_size expected 22, got %d" % ui_theme.get_font_size(&"font_size", &"HudLabel"))
		if ui_theme.get_font_size(&"font_size", &"LevelNameLabel") != 26:
			failures.append("LevelNameLabel font_size expected 26, got %d" % ui_theme.get_font_size(&"font_size", &"LevelNameLabel"))

	# Verify Combat Configuration
	var combat_cfg: CombatConfigData = load("res://resources/config/combat_config.tres") as CombatConfigData
	if combat_cfg == null:
		failures.append("combat_config.tres is null or failed to load as CombatConfigData")
	else:
		if combat_cfg.health_segments_base != 3:
			failures.append("combat_cfg health_segments_base expected 3, got %d" % combat_cfg.health_segments_base)
		if combat_cfg.hero_poise_max != 100.0:
			failures.append("combat_cfg hero_poise_max expected 100.0, got %f" % combat_cfg.hero_poise_max)
		if combat_cfg.parry_window_frames != 6:
			failures.append("combat_cfg parry_window_frames expected 6, got %d" % combat_cfg.parry_window_frames)
		if combat_cfg.dash_i_frames != 12:
			failures.append("combat_cfg dash_i_frames expected 12, got %d" % combat_cfg.dash_i_frames)
		if combat_cfg.attack_token_limit != 2:
			failures.append("combat_cfg attack_token_limit expected 2, got %d" % combat_cfg.attack_token_limit)

	# Verify AttackData class
	var attack_data: AttackData = AttackData.new()
	if attack_data == null:
		failures.append("AttackData failed to instantiate")
	else:
		if attack_data.total_frames() != 21:
			failures.append("AttackData default total_frames expected 21, got %d" % attack_data.total_frames())

	return failures

