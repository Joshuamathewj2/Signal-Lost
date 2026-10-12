class_name TestCombatWeapons
extends RefCounted

## TestCombatWeapons
## Unit test suite for WeaponSwapManager, WeaponNaginata, WeaponKunai, and Shuriken sub-weapon.

func run() -> Array[String]:
	var failures: Array[String] = []

	# 1. WeaponSwapManager cycling
	var mgr := WeaponSwapManager.new()
	if mgr.current_weapon != WeaponSwapManager.WeaponType.KATANA:
		failures.append("Expected initial weapon KATANA, got %d" % mgr.current_weapon)

	var swapped_signal: Array[int] = [-1]
	mgr.weapon_swapped.connect(func(w_type: WeaponSwapManager.WeaponType, _name: StringName) -> void:
		swapped_signal[0] = int(w_type)
	)

	var next_w := mgr.cycle_weapon()
	if next_w != WeaponSwapManager.WeaponType.NAGINATA or swapped_signal[0] != int(WeaponSwapManager.WeaponType.NAGINATA):
		failures.append("Expected cycle to NAGINATA (1), got %d" % next_w)

	next_w = mgr.cycle_weapon()
	if next_w != WeaponSwapManager.WeaponType.KUNAI or swapped_signal[0] != int(WeaponSwapManager.WeaponType.KUNAI):
		failures.append("Expected cycle to KUNAI (2), got %d" % next_w)

	next_w = mgr.cycle_weapon()
	if next_w != WeaponSwapManager.WeaponType.KATANA or swapped_signal[0] != int(WeaponSwapManager.WeaponType.KATANA):
		failures.append("Expected cycle wrap to KATANA (0), got %d" % next_w)

	# 2. WeaponNaginata frame data & reach
	if WeaponNaginata.REACH_HORIZONTAL != 52.0:
		failures.append("Expected Naginata reach 52.0, got %f" % WeaponNaginata.REACH_HORIZONTAL)
	var nag_t1 := WeaponNaginata.get_attack_data(0)
	if nag_t1.poise_damage != 35.0:
		failures.append("Expected Naginata thrust poise damage 35.0, got %f" % nag_t1.poise_damage)
	var nag_heavy := WeaponNaginata.get_heavy_attack_data()
	if nag_heavy.poise_damage != 60.0 or nag_heavy.damage != 3:
		failures.append("Expected Naginata heavy poise 60.0 and dmg 3, got poise %f, dmg %d" % [nag_heavy.poise_damage, nag_heavy.damage])

	# 3. WeaponKunai flurry & noise
	if WeaponKunai.REACH_HORIZONTAL != 20.0:
		failures.append("Expected Kunai reach 20.0, got %f" % WeaponKunai.REACH_HORIZONTAL)
	var kun_f1 := WeaponKunai.get_attack_data(0)
	if kun_f1.noise_radius > 90.0:
		failures.append("Expected Kunai light strike noise <= 90.0, got %f" % kun_f1.noise_radius)
	var kun_f4 := WeaponKunai.get_attack_data(3)
	if kun_f4.poise_damage != 20.0:
		failures.append("Expected Kunai flurry 4 poise damage 20.0, got %f" % kun_f4.poise_damage)

	# 4. Shuriken Sub-Weapon
	var shuriken := Shuriken.new()
	if shuriken.speed != 580.0:
		failures.append("Expected Shuriken speed 580.0, got %f" % shuriken.speed)
	if shuriken.noise_radius != 120.0:
		failures.append("Expected Shuriken noise radius 120.0, got %f" % shuriken.noise_radius)

	mgr.free()
	shuriken.free()
	return failures
