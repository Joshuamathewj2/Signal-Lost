class_name TestPuzzleResonance
extends RefCounted

## Unit tests for ResonancePanel, HarmonicLantern, SealLock, PuzzleController and HintBeacon.

func run() -> Array[String]:
	var failures: Array[String] = []

	var panel_script := load("res://scenes/interactables/resonance_panel.gd")
	var lantern_script := load("res://scenes/interactables/harmonic_lantern.gd")
	var seal_script := load("res://scenes/interactables/seal_lock.gd")
	var controller_script := load("res://scenes/interactables/puzzle_controller.gd")
	var beacon_script := load("res://scenes/player/hint_beacon.gd")

	if panel_script == null or lantern_script == null or seal_script == null or controller_script == null or beacon_script == null:
		failures.append("Failed to load one or more puzzle scripts")
		return failures

	# 1. Test ResonancePanel matching & mismatching
	var panel = panel_script.new()
	panel.required_tier = &"whisper"
	panel._ready()

	var pulse_w := PulseProfile.new()
	pulse_w.id = &"whisper"
	panel.on_wavefront(pulse_w, Vector2.ZERO)
	if not panel.is_active:
		failures.append("ResonancePanel failed to activate on matching whisper tier")

	panel.reset()
	var pulse_s := PulseProfile.new()
	pulse_s.id = &"scream"
	panel.on_wavefront(pulse_s, Vector2.ZERO)
	if not panel.is_locked:
		failures.append("ResonancePanel expected to lock out on mismatched tier")

	# 2. Test HarmonicLantern
	var lantern = lantern_script.new()
	lantern.pitch_index = 2
	lantern._ready()
	lantern.ring()
	if not lantern.is_rung:
		failures.append("HarmonicLantern expected is_rung=true after ring()")

	# 3. Test SealLock
	var seal = seal_script.new()
	seal.required_keys = 2
	seal._ready()
	seal.insert_key()
	if seal.current_keys != 1 or seal.is_unlocked:
		failures.append("SealLock should have 1 key and remain locked")
	seal.insert_key()
	if not seal.is_unlocked:
		failures.append("SealLock expected to unlock after 2 keys")

	# 4. Test PuzzleController (Sequential)
	var ctrl = controller_script.new()
	ctrl.is_sequential = true
	var seq_order: Array[int] = [1, 2, 3]
	ctrl.sequence_order = seq_order
	ctrl.sequence_timeout = 8.0
	ctrl._ready()

	var l1 = lantern_script.new()
	l1.pitch_index = 1
	var l2 = lantern_script.new()
	l2.pitch_index = 2
	var l3 = lantern_script.new()
	l3.pitch_index = 3

	ctrl.register_element(l1, 1)
	ctrl.register_element(l2, 2)
	ctrl.register_element(l3, 3)

	# Correct sequence: 1 -> 2 -> 3
	ctrl._on_element_triggered(l1, 1)
	ctrl._on_element_triggered(l2, 2)
	ctrl._on_element_triggered(l3, 3)
	if not ctrl.is_solved:
		failures.append("PuzzleController failed to solve sequential 1->2->3 sequence")

	# Test reset on out-of-order sequence
	ctrl.reset_puzzle()
	ctrl._on_element_triggered(l1, 1)
	ctrl._on_element_triggered(l3, 3) # Out of order!
	if not ctrl.current_sequence.is_empty():
		failures.append("PuzzleController should reset sequence on out-of-order element")

	# 5. Test HintBeacon cooldown & noise
	var beacon = beacon_script.new()
	beacon.cooldown_duration = 5.0
	beacon._ready()

	var fired_1: bool = beacon.try_fire()
	if not fired_1:
		failures.append("HintBeacon try_fire() expected true on first attempt")
	if beacon.current_cooldown <= 0.0:
		failures.append("HintBeacon cooldown should be > 0.0 after firing")

	var fired_2: bool = beacon.try_fire()
	if fired_2:
		failures.append("HintBeacon try_fire() expected false while on cooldown")

	panel.free()
	lantern.free()
	seal.free()
	l1.free()
	l2.free()
	l3.free()
	ctrl.free()
	beacon.free()

	return failures
