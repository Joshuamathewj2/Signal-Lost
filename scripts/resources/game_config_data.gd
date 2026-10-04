class_name GameConfigData
extends Resource

enum Quality {
	HIGH,
	LOW
}

@export_group("Player")
@export var run_speed: float = 180.0
@export var sneak_speed: float = 70.0
@export var ground_accel: float = 1400.0
@export var ground_friction: float = 1800.0
@export var air_accel: float = 900.0
@export var gravity: float = 1800.0
@export var fall_gravity_mult: float = 1.35
@export var jump_velocity: float = -560.0
@export var jump_cut_mult: float = 0.45
@export var max_fall_speed: float = 900.0
@export var coyote_time: float = 0.10
@export var jump_buffer: float = 0.12
@export var drop_through_time: float = 0.20

@export_group("Noise")
@export var footstep_radius: float = 40.0
@export var footstep_loudness: float = 0.5
@export var footstep_interval: float = 0.30
@export var footstep_min_speed: float = 40.0
@export var land_radius: float = 96.0
@export var land_loudness: float = 1.0
@export var land_speed_threshold: float = 520.0

@export_group("Pulse")
@export var charge_full_time: float = 1.0
@export var tier_normal_at: float = 0.35
@export var tier_scream_at: float = 0.85
@export var charge_move_mult: float = 0.6
@export var max_bubbles: int = 6
@export var sound_speed: float = 700.0
@export var ghost_energy: float = 0.12
@export var ghost_time: float = 2.0
@export var ring_fade_time: float = 0.35

@export_group("Battery")
@export var battery_max: float = 100.0
@export var regen_still: float = 8.0
@export var regen_moving: float = 3.0
@export var regen_delay: float = 0.8

@export_group("Hearing")
@export var wall_penalty: float = 0.75
@export var max_wall_raycasts: int = 3
@export var reveal_visible_threshold: float = 0.25
@export var memory_expiry: float = 20.0
@export var vision_tick: float = 0.1
@export var repath_interval: float = 0.25

@export_group("Camera")
@export var camera_zoom: float = 2.0
@export var camera_smoothing: float = 6.0
@export var camera_lookahead: float = 40.0
@export var shake_max_offset: float = 10.0
@export var shake_decay: float = 1.5
@export var scream_zoom_punch: float = 0.06

@export_group("Render")
@export var rim_softness: float = 0.25
@export var player_glow_radius: float = 40.0
@export var player_glow_energy: float = 0.6
@export var sonar_quality: Quality = Quality.HIGH

@export_group("Post")
@export var vignette_strength: float = 0.45
@export var vignette_radius: float = 0.75
@export var grain_amount: float = 0.06
@export var bloom_amount: float = 0.25
@export var ca_scream: float = 0.012
@export var ca_detect: float = 0.008
@export var flash_detect: float = 0.35

@export_group("Anim")
@export var land_squash: float = 0.12
@export var jump_squash: float = 0.08
@export var death_time: float = 0.6
@export var hitstop: float = 0.08
