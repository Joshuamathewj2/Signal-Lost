class_name WeaponKunai
extends RefCounted

## WeaponKunai
## Generates AttackData profiles for Twin Kunai dual daggers:
## Rapid 4-hit flurry (0.18s recovery, 20 px reach) with low noise profile (<= 90 px).

const REACH_HORIZONTAL: float = 20.0

static func get_attack_data(combo_index: int) -> AttackData:
	var data := AttackData.new()
	data.reach = REACH_HORIZONTAL
	match combo_index:
		0:
			data.attack_name = &"kunai_flurry_1"
			data.damage = 1
			data.poise_damage = 8.0
			data.knockback_force = 40.0
			data.hitstop_duration = 0.04
			data.noise_radius = 70.0
			data.noise_loudness = 0.8
			data.startup_frames = 3
			data.active_frames = 2
			data.recovery_frames = 8
		1:
			data.attack_name = &"kunai_flurry_2"
			data.damage = 1
			data.poise_damage = 8.0
			data.knockback_force = 40.0
			data.hitstop_duration = 0.04
			data.noise_radius = 75.0
			data.noise_loudness = 0.8
			data.startup_frames = 3
			data.active_frames = 2
			data.recovery_frames = 8
		2:
			data.attack_name = &"kunai_flurry_3"
			data.damage = 1
			data.poise_damage = 12.0
			data.knockback_force = 80.0
			data.hitstop_duration = 0.05
			data.noise_radius = 85.0
			data.noise_loudness = 0.9
			data.startup_frames = 4
			data.active_frames = 3
			data.recovery_frames = 10
		3:
			data.attack_name = &"kunai_flurry_4"
			data.damage = 2
			data.poise_damage = 20.0
			data.knockback_force = 180.0
			data.hitstop_duration = 0.08
			data.noise_radius = 110.0
			data.noise_loudness = 1.2
			data.startup_frames = 6
			data.active_frames = 3
			data.recovery_frames = 14
		_:
			data.attack_name = &"kunai_flurry_1"
			data.damage = 1
			data.poise_damage = 8.0
			data.knockback_force = 40.0
			data.hitstop_duration = 0.04
			data.noise_radius = 70.0
			data.noise_loudness = 0.8
			data.startup_frames = 3
			data.active_frames = 2
			data.recovery_frames = 8
	return data


static func get_heavy_attack_data() -> AttackData:
	var data := AttackData.new()
	data.attack_name = &"kunai_heavy_cross"
	data.reach = 24.0
	data.damage = 2
	data.poise_damage = 30.0
	data.knockback_force = 220.0
	data.hitstop_duration = 0.10
	data.noise_radius = 140.0
	data.noise_loudness = 1.5
	data.startup_frames = 8
	data.active_frames = 3
	data.recovery_frames = 18
	return data
