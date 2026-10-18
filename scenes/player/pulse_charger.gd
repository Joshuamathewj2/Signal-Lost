class_name PulseCharger
extends Node

signal charge_started
signal charge_changed(tier: int, charge_norm: float, affordable_tier: int)
signal pulse_released(profile: PulseProfile, origin: Vector2)
signal pulse_failed

@export var player: CharacterBody2D
@export var battery: Battery

var noise_scale: float = 1.0
var is_charging: bool = false
var charge_time: float = 0.0
var cooldowns: Dictionary = { 0: 0.0, 1: 0.0, 2: 0.0 }

var quick_scream_enabled: bool = false
var last_press_time: float = -10.0

func _ready() -> void:
	if SaveData != null:
		quick_scream_enabled = bool(SaveData.get_setting("quick_scream", false))
		SaveData.settings_changed.connect(_on_settings_changed)

func _on_settings_changed() -> void:
	if SaveData != null:
		quick_scream_enabled = bool(SaveData.get_setting("quick_scream", false))

static func tier_for_charge(c: float, normal_at: float = 0.35, scream_at: float = 0.85) -> int:
	if c < normal_at:
		return 0
	elif c < scream_at:
		return 1
	else:
		return 2

static func get_affordable_tier(selected_tier: int, current_energy: float) -> int:
	for t in range(selected_tier, -1, -1):
		var prof: PulseProfile = GameConfig.pulse_for_tier(t)
		if prof != null and current_energy >= prof.energy_cost:
			return t
	return -1

func _process(delta: float) -> void:
	for t in cooldowns.keys():
		if cooldowns[t] > 0.0:
			cooldowns[t] -= delta

	var cfg: GameConfigData = GameConfig.data

	if Input.is_action_just_pressed(&"pulse"):
		var now: float = float(Time.get_ticks_msec()) / 1000.0
		if quick_scream_enabled and (now - last_press_time) < 0.25:
			is_charging = false
			charge_time = cfg.charge_full_time
			_release_pulse()
			last_press_time = -10.0
			return
		last_press_time = now

		if not is_charging:
			is_charging = true
			charge_time = 0.0
			charge_started.emit()

	if is_charging:
		if Input.is_action_pressed(&"pulse"):
			charge_time += delta
			var c: float = clampf(charge_time / cfg.charge_full_time, 0.0, 1.0)
			var tier: int = tier_for_charge(c, cfg.tier_normal_at, cfg.tier_scream_at)
			var cur_e: float = battery.energy if battery != null else 100.0
			var affordable: int = get_affordable_tier(tier, cur_e)
			charge_changed.emit(tier, c, affordable)

		if Input.is_action_just_released(&"pulse"):
			_release_pulse()

func _release_pulse() -> void:
	is_charging = false
	var cfg: GameConfigData = GameConfig.data
	var c: float = clampf(charge_time / cfg.charge_full_time, 0.0, 1.0)
	var tier: int = tier_for_charge(c, cfg.tier_normal_at, cfg.tier_scream_at)
	var cur_e: float = battery.energy if battery != null else 100.0
	var affordable: int = get_affordable_tier(tier, cur_e)

	if affordable == -1:
		pulse_failed.emit()
		return

	# Jammer interference
	if player != null and is_inside_tree():
		var jammers := get_tree().get_nodes_in_group(&"jammers")
		for j in jammers:
			if is_instance_valid(j) and j is Node2D:
				var rad: float = float(j.get("jam_radius")) if j.get("jam_radius") != null else 240.0
				if (j as Node2D).global_position.distance_to(player.global_position) <= rad:
					pulse_failed.emit()
					return

	var chosen_profile: PulseProfile = GameConfig.pulse_for_tier(affordable)
	if chosen_profile == null:
		pulse_failed.emit()
		return

	if cooldowns.get(affordable, 0.0) > 0.0:
		pulse_failed.emit()
		return

	if battery != null and not battery.try_spend(chosen_profile.energy_cost):
		pulse_failed.emit()
		return

	cooldowns[affordable] = chosen_profile.cooldown

	var origin: Vector2 = player.global_position if player != null else (Vector2.ZERO)
	pulse_released.emit(chosen_profile, origin)

	var noise_r: float = chosen_profile.noise_radius() * noise_scale
	var ev: NoiseEvent = NoiseEvent.make(origin, noise_r, chosen_profile.loudness, NoiseEvent.NoiseType.PULSE, player)
	NoiseBus.emit_noise(ev)
