class_name CombatConfigData
extends Resource

## CombatConfigData
## Typed configuration resource defining master combat balance tunables,
## poise meters, defensive windows, hit-stop durations, and AI concurrency limits
## per docs/GAME_CONFIG_REFERENCE.md.

@export_group("Vitality & Poise")
@export var health_segments_base: int = 3
@export var health_segments_max: int = 5
@export var hero_poise_max: float = 100.0
@export var hero_poise_regen: float = 25.0
@export var guard_break_stagger: float = 0.60

@export_group("Defense & Evasion")
@export var dash_duration: float = 0.25
@export var dash_i_frames: int = 12
@export var dash_cooldown: float = 0.50
@export var parry_window_frames: int = 6
@export var parry_i_frames: int = 16

@export_group("Combos & Hit-Stop")
@export var combo_buffer_window: float = 0.35
@export var hitstop_light: float = 0.06
@export var hitstop_heavy: float = 0.10
@export var hitstop_parry: float = 0.12

@export_group("AI Concurrency")
@export var attack_token_limit: int = 2
