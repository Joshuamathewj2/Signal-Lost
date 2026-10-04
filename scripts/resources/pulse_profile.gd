class_name PulseProfile
extends Resource

@export var id: StringName = &"normal"
@export var reveal_radius: float = 200.0
@export var noise_mult: float = 1.0
@export var loudness: float = 2.0
@export var hold_time: float = 1.2
@export var fade_time: float = 1.6
@export var energy_cost: float = 22.0
@export var cooldown: float = 0.6
@export var ring_thickness: float = 2.0
@export var trail_count: int = 2
@export var trail_gap: float = 14.0
@export var shake_px: float = 2.0
@export var zoom_punch: float = 0.0
@export var sfx_pitch: float = 1.0
@export var ca_strength: float = 0.0
@export var sfx_id: StringName = &"ping_normal"

func noise_radius() -> float:
	return reveal_radius * noise_mult

func expand_time(sound_speed: float = 700.0) -> float:
	return max(reveal_radius / sound_speed, 0.08)
