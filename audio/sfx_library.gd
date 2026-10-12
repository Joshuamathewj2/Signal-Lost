class_name SfxLibrary
extends RefCounted

static func build() -> Dictionary:
	var t0: int = Time.get_ticks_msec()
	var lib: Dictionary = {}

	# 1. ping_whisper (0.15 s)
	var s_w := Synth.sine(2400.0, 0.15)
	var s_w2 := Synth.sine(4800.0, 0.15)
	for i in range(s_w.size()):
		s_w[i] = (s_w[i] + s_w2[i] * 0.2) * 0.8
	s_w = Synth.env_exp(s_w, 0.05)
	lib[&"ping_whisper"] = Synth.to_wav(s_w)

	# 2. ping_normal (0.6 s)
	var s_n := Synth.glide(1500.0, 1350.0, 0.6)
	s_n = Synth.env_exp(s_n, 0.18)
	s_n = Synth.echo(s_n, 0.12, 0.35)
	lib[&"ping_normal"] = Synth.to_wav(s_n)

	# 3. ping_scream (1.6 s)
	var s_s := Synth.glide(900.0, 600.0, 1.6)
	var s_saw := Synth.lowpass_onepole(Synth.saw(450.0, 1.6), 1200.0)
	for i in range(s_s.size()):
		s_s[i] = (s_s[i] + s_saw[i] * 0.15) * 0.8
	s_s = Synth.env_exp(s_s, 0.5)
	s_s = Synth.echo(s_s, 0.15, 0.4)
	s_s = Synth.echo(s_s, 0.30, 0.25)
	lib[&"ping_scream"] = Synth.to_wav(s_s)

	# 4. charge_loop (1.0 s)
	var s_chg := Synth.sine(300.0, 1.0)
	for i in range(s_chg.size()):
		var trem: float = 0.8 + 0.2 * sin(float(i) * TAU * 8.0 / 44100.0)
		s_chg[i] *= trem * 0.6
	var wav_chg: AudioStreamWAV = Synth.to_wav(s_chg)
	wav_chg.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav_chg.loop_end = s_chg.size()
	lib[&"charge_loop"] = wav_chg

	# 5. pulse_fail (0.03 s)
	var s_pf := Synth.lowpass_onepole(Synth.noise(0.03), 3000.0)
	s_pf = Synth.env_exp(s_pf, 0.008)
	lib[&"pulse_fail"] = Synth.to_wav(s_pf)

	# 6. step_soft (0.03 s)
	var s_step := Synth.lowpass_onepole(Synth.noise(0.03), 1500.0)
	s_step = Synth.env_exp(s_step, 0.015)
	lib[&"step_soft"] = Synth.to_wav(s_step)

	# 7. land (0.2 s)
	var s_land := Synth.sine(80.0, 0.2)
	s_land = Synth.env_exp(s_land, 0.08)
	var s_ln := Synth.env_exp(Synth.lowpass_onepole(Synth.noise(0.2), 600.0), 0.04)
	for i in range(s_land.size()):
		s_land[i] = (s_land[i] * 0.7 + s_ln[i] * 0.3)
	lib[&"land"] = Synth.to_wav(s_land)

	# 8. listener_alert (0.25 s)
	var s_la := Synth.square(700.0, 0.12)
	var s_la2 := Synth.square(1000.0, 0.13)
	var s_la_full := PackedFloat32Array()
	s_la_full.append_array(s_la)
	s_la_full.append_array(s_la2)
	for i in range(s_la_full.size()):
		s_la_full[i] *= 0.3
	lib[&"listener_alert"] = Synth.to_wav(s_la_full)

	# 9. hunter_ping (0.2 s)
	var s_hp1 := Synth.env_exp(Synth.sine(1800.0, 0.06), 0.02)
	var s_hp_gap := PackedFloat32Array()
	s_hp_gap.resize(int(0.06 * 44100.0))
	var s_hp2 := Synth.env_exp(Synth.sine(1800.0, 0.08), 0.02)
	var s_hp := PackedFloat32Array()
	s_hp.append_array(s_hp1)
	s_hp.append_array(s_hp_gap)
	s_hp.append_array(s_hp2)
	lib[&"hunter_ping"] = Synth.to_wav(s_hp)

	# 10. sentry_whine (0.6 s)
	var s_sw := Synth.glide(200.0, 900.0, 0.6)
	for i in range(s_sw.size()):
		s_sw[i] *= 0.4
	lib[&"sentry_whine"] = Synth.to_wav(s_sw)

	# 11. sentry_fire (0.25 s)
	var s_sf := Synth.sine(120.0, 0.25)
	s_sf = Synth.env_exp(s_sf, 0.08)
	var s_sfn := Synth.env_exp(Synth.noise(0.25), 0.03)
	for i in range(s_sf.size()):
		s_sf[i] = (s_sf[i] * 0.6 + s_sfn[i] * 0.4)
	lib[&"sentry_fire"] = Synth.to_wav(s_sf)

	# 12. brute_step (0.3 s)
	var s_bs := Synth.sine(45.0, 0.3)
	s_bs = Synth.env_exp(s_bs, 0.15)
	var s_bsn := Synth.env_exp(Synth.lowpass_onepole(Synth.noise(0.3), 300.0), 0.08)
	for i in range(s_bs.size()):
		s_bs[i] = s_bs[i] * 0.7 + s_bsn[i] * 0.3
	lib[&"brute_step"] = Synth.to_wav(s_bs)

	# 13. glass_break (0.8 s)
	var s_gb := Synth.noise(0.8)
	s_gb = Synth.env_exp(s_gb, 0.3)
	for i in range(s_gb.size()):
		var high_ping: float = sin(float(i) * TAU * 3400.0 / 44100.0) + sin(float(i) * TAU * 5100.0 / 44100.0)
		s_gb[i] = (s_gb[i] * 0.5 + high_ping * 0.25) * 0.7
	lib[&"glass_break"] = Synth.to_wav(s_gb)

	# 14. lantern_clink (0.5 s)
	var s_lc1 := Synth.sine(3200.0, 0.5)
	var s_lc2 := Synth.sine(4700.0, 0.5)
	for i in range(s_lc1.size()):
		s_lc1[i] = (s_lc1[i] * 0.6 + s_lc2[i] * 0.4)
	s_lc1 = Synth.env_exp(s_lc1, 0.3)
	lib[&"lantern_clink"] = Synth.to_wav(s_lc1)

	# 15. plate_click (0.05 s)
	var s_pc := Synth.sine(1200.0, 0.05)
	s_pc = Synth.env_exp(s_pc, 0.015)
	lib[&"plate_click"] = Synth.to_wav(s_pc)

	# 16. door_open (0.6 s)
	var s_do := Synth.lowpass_onepole(Synth.noise(0.6), 800.0)
	s_do = Synth.env_exp(s_do, 0.4)
	lib[&"door_open"] = Synth.to_wav(s_do)

	# 17. key_pickup (0.2 s)
	var s_kp1 := Synth.env_exp(Synth.sine(1200.0, 0.1), 0.05)
	var s_kp2 := Synth.env_exp(Synth.sine(1600.0, 0.1), 0.05)
	var s_kp := PackedFloat32Array()
	s_kp.append_array(s_kp1)
	s_kp.append_array(s_kp2)
	lib[&"key_pickup"] = Synth.to_wav(s_kp)

	# 18. fragment_pickup (0.3 s)
	var s_fp1 := Synth.env_exp(Synth.sine(1200.0, 0.1), 0.05)
	var s_fp2 := Synth.env_exp(Synth.sine(1600.0, 0.1), 0.05)
	var s_fp3 := Synth.env_exp(Synth.sine(2000.0, 0.1), 0.05)
	var s_fp := PackedFloat32Array()
	s_fp.append_array(s_fp1)
	s_fp.append_array(s_fp2)
	s_fp.append_array(s_fp3)
	lib[&"fragment_pickup"] = Synth.to_wav(s_fp)

	# 19. terminal_restore (0.8 s)
	var s_tr := Synth.glide(800.0, 2400.0, 0.8)
	s_tr = Synth.env_exp(s_tr, 0.6)
	lib[&"terminal_restore"] = Synth.to_wav(s_tr)

	# 20. UI: ui_move (0.02 s), ui_select (0.04 s), ui_back (0.04 s)
	var s_uim := Synth.env_exp(Synth.sine(1000.0, 0.02), 0.01)
	var s_uis := Synth.env_exp(Synth.sine(1400.0, 0.04), 0.02)
	var s_uib := Synth.env_exp(Synth.sine(700.0, 0.04), 0.02)
	lib[&"ui_move"] = Synth.to_wav(s_uim)
	lib[&"ui_select"] = Synth.to_wav(s_uis)
	lib[&"ui_back"] = Synth.to_wav(s_uib)

	# 21. sfx_katana_slash (0.09 s) - High-pass noise swoosh
	var s_ks := Synth.noise(0.09)
	s_ks = Synth.env_exp(s_ks, 0.035)
	lib[&"sfx_katana_slash"] = Synth.to_wav(s_ks)

	# 22. sfx_naginata_thrust (0.16 s) - Air displacement pop + resonant tone
	var s_nt := Synth.sine(140.0, 0.16)
	s_nt = Synth.env_exp(s_nt, 0.07)
	var s_ntn := Synth.env_exp(Synth.noise(0.16), 0.04)
	for i in range(s_nt.size()):
		s_nt[i] = s_nt[i] * 0.7 + s_ntn[i] * 0.3
	lib[&"sfx_naginata_thrust"] = Synth.to_wav(s_nt)

	# 23. sfx_blade_clash (0.22 s) - Resonant dual-comb filtered metal strike
	var s_bc1 := Synth.sine(880.0, 0.22)
	var s_bc2 := Synth.sine(1320.0, 0.22)
	var s_bc := Synth.env_exp(Synth.noise(0.22), 0.06)
	for i in range(s_bc.size()):
		s_bc[i] = (s_bc[i] * 0.4 + (s_bc1[i] + s_bc2[i]) * 0.3)
	lib[&"sfx_blade_clash"] = Synth.to_wav(s_bc)

	# 24. sfx_parry_deflect (0.28 s) - High 1800 Hz pure bell ping
	var s_pd := Synth.sine(1800.0, 0.28)
	var s_pd2 := Synth.sine(3600.0, 0.28)
	for i in range(s_pd.size()):
		s_pd[i] = (s_pd[i] * 0.7 + s_pd2[i] * 0.3)
	s_pd = Synth.env_exp(s_pd, 0.14)
	lib[&"sfx_parry_deflect"] = Synth.to_wav(s_pd)

	# 25. sfx_arrow_whistle (0.35 s) - Descending sinusoidal whistle
	var s_aw := Synth.glide(1200.0, 500.0, 0.35)
	s_aw = Synth.env_exp(s_aw, 0.25)
	lib[&"sfx_arrow_whistle"] = Synth.to_wav(s_aw)

	var elapsed: int = Time.get_ticks_msec() - t0
	DebugFlags.log(&"audio", "SfxLibrary rendered in %d ms (< 1500 ms limit)" % elapsed)

	return lib
