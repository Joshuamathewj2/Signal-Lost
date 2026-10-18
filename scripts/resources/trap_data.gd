class_name TrapData
extends Resource

## TrapData
## Typed configuration resource defining parameters for mechanical and environmental hazards.
## Enforces telegraphing, damage, dual-target affinity (hero + enemy), noise bus output, and optional disarmability.

@export_group("Identity")
@export var trap_id: StringName = &"generic_trap"
@export var display_name: String = "Hazard"

@export_group("Damage & Combat")
@export var damage: int = 2
@export var poise_damage: float = 40.0
@export var knockback_force: float = 200.0
@export var affects_enemies: bool = true
@export var hitstop_duration: float = 0.08
@export var lethal_to_unarmored: bool = false

@export_group("Timing & States")
@export var trigger_type: StringName = &"proximity" # &"proximity", &"pressure", &"timer", &"continuous", &"tripwire"
@export var telegraph_time: float = 0.50 # Visual + sound cue at least 0.5s before active hitbox
@export var active_time: float = 0.40 # How long the damaging hitbox lingers
@export var cooldown: float = 2.0 # Time before trap resets to idle/hidden
@export var initial_delay: float = 0.0 # Staggered startup for rhythmic trap combinations

@export_group("Acoustics & Stealth")
@export var noise_radius: float = 80.0
@export var noise_loudness: float = 1.0
@export var can_be_disarmed: bool = false
@export var disarm_frequency: int = 0 # 0: none/switch, 1: Whisper (pulse 1), 2: Normal (pulse 2), 3: Scream (pulse 3)

@export_group("FX & Screen Impact")
@export var camera_shake: float = 2.0
@export var danger_accent_color: Color = Color(1.0, 0.15, 0.15, 0.85)

func _init(
	p_id: StringName = &"generic_trap",
	p_damage: int = 2,
	p_telegraph: float = 0.50,
	p_cooldown: float = 2.0,
	p_noise_r: float = 80.0,
	p_noise_loud: float = 1.0,
	p_affects_enemies: bool = true
) -> void:
	trap_id = p_id
	damage = p_damage
	telegraph_time = maxf(0.50, p_telegraph) # Rule: at least 0.5s telegraph
	cooldown = p_cooldown
	noise_radius = p_noise_r
	noise_loudness = p_noise_loud
	affects_enemies = p_affects_enemies
