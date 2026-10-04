extends Node

var data: GameConfigData = preload("res://resources/config/default_config.tres")
var cfg: GameConfigData:
	get:
		return data

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
