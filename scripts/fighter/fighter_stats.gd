class_name FighterStats
extends RefCounted

## FighterStats
## Locomotion tuning for one Fighter. Built from JSON:
##   "locomotion": { run_speed, gravity, jump_velocity, ... }   (same keys as data/player.json)
##   "jump":       { can_jump, jump_height (px, overrides jump_velocity), cooldown, max_gap }
##   "dash":       { speed, time, cooldown, telegraph }
##   "weight_class": light | medium | heavy | boss

var run_speed: float = 180.0
var sneak_speed: float = 70.0
var ground_accel: float = 1400.0
var ground_friction: float = 1800.0
var air_accel: float = 900.0
var gravity: float = 1800.0
var fall_gravity_mult: float = 1.35
var jump_velocity: float = -560.0
var jump_cut_mult: float = 0.45
var max_fall_speed: float = 900.0
var coyote_time: float = 0.10
var jump_buffer: float = 0.10
var drop_through_time: float = 0.20

var can_jump: bool = true
var jump_cooldown: float = 0.0
var max_gap: float = 96.0

var dash_speed: float = 400.0
var dash_time: float = 0.25
var dash_cooldown: float = 0.5
var dash_telegraph: float = 0.0

var weight_class: StringName = &"medium"

const LOCOMOTION_KEYS: PackedStringArray = [
	"run_speed", "sneak_speed", "ground_accel", "ground_friction", "air_accel", "gravity",
	"fall_gravity_mult", "jump_velocity", "jump_cut_mult", "max_fall_speed", "coyote_time",
	"jump_buffer", "drop_through_time",
]


## Applies a JSON block (see header) and returns self for chaining:
##   FighterStats.new().apply_dict(d, path)
func apply_dict(d: Dictionary, context: String = "fighter") -> FighterStats:
	var s: FighterStats = self
	var loco: Dictionary = d.get("locomotion", {})
	for key in loco:
		if LOCOMOTION_KEYS.has(key):
			s.set(key, float(loco[key]))
		else:
			push_warning("[FighterStats] %s: unknown locomotion key '%s'" % [context, key])
	var jump: Dictionary = d.get("jump", {})
	s.can_jump = bool(jump.get("can_jump", s.can_jump))
	s.jump_cooldown = float(jump.get("cooldown", s.jump_cooldown))
	s.max_gap = float(jump.get("max_gap", s.max_gap))
	if jump.has("jump_height"):
		s.jump_velocity = -sqrt(2.0 * s.gravity * float(jump["jump_height"]))
	var dash: Dictionary = d.get("dash", {})
	s.dash_speed = float(dash.get("speed", s.dash_speed))
	s.dash_time = float(dash.get("time", s.dash_time))
	s.dash_cooldown = float(dash.get("cooldown", s.dash_cooldown))
	s.dash_telegraph = float(dash.get("telegraph", s.dash_telegraph))
	s.weight_class = StringName(str(d.get("weight_class", s.weight_class)))
	return s


func apply_game_config(cfg: GameConfigData) -> FighterStats:
	for key in LOCOMOTION_KEYS:
		set(key, cfg.get(key))
	return self


## Highest point of a full (held) jump, px above take-off.
func jump_apex() -> float:
	return jump_velocity * jump_velocity / (2.0 * gravity)


## Seconds airborne for a full jump that lands at take-off height.
func jump_airtime() -> float:
	var t_up: float = -jump_velocity / gravity
	var t_down: float = sqrt(2.0 * jump_apex() / (gravity * fall_gravity_mult))
	return t_up + t_down


## Horizontal reach of a full running jump, px.
func jump_distance() -> float:
	return run_speed * jump_airtime()
