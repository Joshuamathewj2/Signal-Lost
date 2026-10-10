extends Node

signal quality_changed(new_quality: int)

var data: GameConfigData = preload("res://resources/config/default_config.tres")
var cfg: GameConfigData:
	get:
		return data

var sonar_quality: int = 1 # 0: LOW, 1: HIGH

var pulses: Dictionary = {
	&"whisper": preload("res://resources/pulses/pulse_whisper.tres"),
	&"normal": preload("res://resources/pulses/pulse_normal.tres"),
	&"scream": preload("res://resources/pulses/pulse_scream.tres"),
	&"decoy": preload("res://resources/pulses/pulse_decoy.tres"),
}

var enemies: Dictionary = {
	&"listener": preload("res://resources/enemies/enemy_listener.tres"),
	&"sentry": preload("res://resources/enemies/enemy_sentry.tres"),
	&"hunter": preload("res://resources/enemies/enemy_hunter.tres"),
	&"brute": preload("res://resources/enemies/enemy_brute.tres"),
}

func _ready() -> void:
	if SaveData != null:
		var perf_on: bool = bool(SaveData.get_setting("performance_mode", false))
		set_sonar_quality(0 if perf_on else 1)

func pulse_for_tier(tier: int) -> PulseProfile:
	match tier:
		0:
			return pulses[&"whisper"]
		1:
			return pulses[&"normal"]
		2:
			return pulses[&"scream"]
		_:
			return pulses[&"normal"]

func set_sonar_quality(q: int) -> void:
	sonar_quality = q
	if data != null:
		data.sonar_quality = (q as GameConfigData.Quality)
		data.max_bubbles = 4 if q == 0 else 6
	quality_changed.emit(q)
