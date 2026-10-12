class_name AttackData
extends Resource

## AttackData
## Typed configuration resource defining frame data, damage metrics, poise impact,
## kinetic knockback, noise emission, and visual trail styles for weapon and enemy attacks.

@export_group("Identity")
@export var attack_name: StringName = &"slash"

@export_group("Damage & Balance")
@export var damage: int = 1
@export var poise_damage: float = 15.0
@export var knockback_force: float = 150.0
@export var hitstop_duration: float = 0.06
@export var pierce_count: int = 1
@export var unblockable: bool = false

@export_group("Frame Data (60 FPS Baseline)")
@export var startup_frames: int = 6
@export var active_frames: int = 3
@export var recovery_frames: int = 12

@export_group("Spatial & Noise")
@export var reach: float = 32.0
@export var noise_radius: float = 180.0
@export var noise_loudness: float = 1.5

@export_group("Visuals & Juice")
@export var slash_arc_style: StringName = &"horizontal"
@export var camera_shake: float = 2.0


## Returns total frames (startup + active + recovery).
func total_frames() -> int:
	return startup_frames + active_frames + recovery_frames


## Returns total duration in seconds based on 60 FPS baseline.
func total_duration_sec() -> float:
	return float(total_frames()) / 60.0


## Returns startup duration in seconds.
func startup_duration_sec() -> float:
	return float(startup_frames) / 60.0


## Returns active hitbox duration in seconds.
func active_duration_sec() -> float:
	return float(active_frames) / 60.0


## Returns recovery duration in seconds.
func recovery_duration_sec() -> float:
	return float(recovery_frames) / 60.0
