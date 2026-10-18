class_name EnemyData
extends Resource

## EnemyData
## Data-driven resource defining enemy combat stats, poise thresholds,
## evasion probabilities, sprite frame bindings, and behavior tunables.

@export var enemy_name: StringName = &"Ronin"
@export var max_health: int = 3
@export var max_poise: float = 60.0
@export var evade_chance: float = 0.35
@export var retreat_hp_threshold: float = 0.25 # Retreat when HP <= 25%
@export var can_block: bool = true
@export var super_armor: bool = false
@export var sprite_frames: SpriteFrames = null
@export var scale_factor: float = 0.35

@export var walk_speed: float = 50.0
@export var run_speed: float = 120.0
@export var turn_speed: float = 60.0
@export var hearing_threshold: float = 1.0
@export var hearing_mult: float = 1.0
@export var accepted_types: Array[int] = []
@export var sight_range: float = 200.0
@export var sight_angle_deg: float = 70.0
@export var search_time: float = 4.0
@export var investigate_wait: float = 1.5
@export var awareness_gain: float = 0.6
@export var awareness_decay: float = 0.15
@export var can_jump: bool = true
@export var contact_kills: bool = true
@export var tint: Color = Color(0.88, 0.0, 0.0, 1.0)
@export var memory_size: int = 1
@export var fire_interval: float = 0.9
@export var projectile_speed: float = 420.0
