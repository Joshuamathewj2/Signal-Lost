class_name WeaponNaginata
extends RefCounted

## WeaponNaginata
## Generates AttackData profiles for Naginata spear-blade moves:
## 52 px reach thrusts, group piercing (up to 2 targets), and vertical overhead reach.

const REACH_HORIZONTAL: float = 52.0
const REACH_VERTICAL: float = 36.0
const MAX_PIERCE_TARGETS: int = 2

static func get_attack_data(combo_index: int) -> AttackData:
	var data := AttackData.new()
	match combo_index:
		0:
			data.attack_name = &"naginata_thrust_1"
			data.damage = 1
			data.poise_damage = 35.0
			data.knockback_force = 220.0
			data.hitstop_duration = 0.08
			data.noise_radius = 240.0
			data.noise_loudness = 2.0
			data.startup_frames = 8
			data.active_frames = 4
			data.recovery_frames = 16
		1:
			data.attack_name = &"naginata_sweep_2"
			data.damage = 2
			data.poise_damage = 40.0
			data.knockback_force = 280.0
			data.hitstop_duration = 0.10
			data.noise_radius = 280.0
			data.noise_loudness = 2.4
			data.startup_frames = 10
			data.active_frames = 5
			data.recovery_frames = 22
		_:
			data.attack_name = &"naginata_thrust_1"
			data.damage = 1
			data.poise_damage = 35.0
			data.knockback_force = 220.0
			data.hitstop_duration = 0.08
			data.noise_radius = 240.0
			data.noise_loudness = 2.0
			data.startup_frames = 8
			data.active_frames = 4
			data.recovery_frames = 16
	return data


static func get_heavy_attack_data() -> AttackData:
	var data := AttackData.new()
	data.attack_name = &"naginata_heavy_impale"
	data.damage = 3
	data.poise_damage = 60.0
	data.knockback_force = 450.0
	data.hitstop_duration = 0.14
	data.noise_radius = 320.0
	data.noise_loudness = 2.8
	data.startup_frames = 16
	data.active_frames = 5
	data.recovery_frames = 26
	return data
