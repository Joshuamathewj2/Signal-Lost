class_name ShieldBearer
extends EnemyBase

## ShieldBearer
## Heavy samurai vanguard with front-facing reinforced pavise tower shield.
## Frontal hits are blocked unless guard-broken with heavy strike (K) or parried.
## Susceptible to rear strikes and stealth takedowns.

signal shield_blocked
signal guard_broken

var shield_active: bool = true
var is_bashing: bool = false
var bash_timer: float = 0.0

@onready var shield_sprite: Node2D = get_node_or_null("Visual/Shield") as Node2D

func _ready() -> void:
	kind = &"shield_bearer"
	super._ready()
	if health_component != null:
		health_component.max_health = 3
		health_component.current_health = 3
	if poise_component != null:
		poise_component.max_poise = 80.0
		poise_component.current_poise = 80.0

func intercept_hit(incoming_hitbox: Area2D) -> bool:
	if not shield_active:
		return false

	var facing_dir: float = float(facing)
	var is_frontal: bool = (incoming_hitbox.global_position.x - global_position.x) * facing_dir >= -8.0

	# Rear attacks completely bypass shield
	if not is_frontal:
		return false

	# Heavy poise-breaking strike breaks guard!
	var is_heavy: bool = incoming_hitbox.has_meta(&"is_heavy") and bool(incoming_hitbox.get_meta(&"is_heavy"))
	var p_dmg: float = float(incoming_hitbox.get("poise_damage")) if incoming_hitbox.get("poise_damage") != null else 0.0

	if is_heavy or p_dmg >= 50.0:
		break_guard()
		return false # Damage penetrates

	# Block frontal attack!
	shield_blocked.emit()
	if NoiseBus != null:
		var ev := NoiseEvent.make(global_position, 120.0, 1.2, NoiseEvent.NoiseType.CLINK, self)
		NoiseBus.emit_noise(ev)

	var vis: Node = get_node_or_null("Visual")
	if vis != null and vis.has_method("flash"):
		vis.call("flash")

	return true # Attack intercepted (0 damage)

func break_guard() -> void:
	shield_active = false
	guard_broken.emit()
	if poise_component != null:
		poise_component.damage_poise(80.0, 1.8)
	if state_machine != null and state_machine.states.has(&"Stagger"):
		state_machine.change_state(&"Stagger", {"duration": 1.8})

	# Shield re-engages after recovery
	var timer := get_tree().create_timer(2.5)
	timer.timeout.connect(func() -> void:
		shield_active = true
	)
