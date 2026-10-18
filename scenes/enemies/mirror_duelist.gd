class_name MirrorDuelist
extends EnemyBase

## MirrorDuelist
## Mini-boss encounter in Level 4 "Glass Foundry" (8 HP).
## Shadows the player's martial techniques: matches stances, alternates between
## Katana thrusts and Kusarigama sweeps, and raises a 6-frame defensive parry guard.
## Counterplay: Heavy attacks (K) or acoustic pulses break guard; rear strikes bypass.

signal duelist_parried
signal stance_switched(stance: StringName)

enum Stance { KATANA, KUSARIGAMA }

var current_stance: Stance = Stance.KATANA
var is_parrying: bool = false
var parry_cooldown: float = 0.0
var attack_cooldown: float = 0.0
var stance_timer: float = 0.0

@onready var slash_hitbox: Area2D = $Hitbox

func _ready() -> void:
	kind = &"mirror_duelist"
	super._ready()
	if health_component != null:
		health_component.max_health = 8
		health_component.current_health = 8
	if poise_component != null:
		poise_component.max_poise = 80.0
		poise_component.current_poise = 80.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if parry_cooldown > 0.0:
		parry_cooldown -= delta
	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	stance_timer += delta
	if stance_timer >= 5.0:
		_switch_stance()

	# Check pulse stun
	if PulseRegistry != null and PulseRegistry.reveal_at(global_position) >= 0.8:
		if is_parrying:
			is_parrying = false
			_on_staggered(1.5)

	# Combat behavior when alert
	if awareness != null and awareness.is_alert:
		var player := get_tree().get_first_node_in_group(&"player") as Node2D
		if player != null and is_instance_valid(player):
			var dist := global_position.distance_to(player.global_position)
			face(1 if player.global_position.x > global_position.x else -1)

			# Tactical spacing
			if dist > 60.0:
				velocity.x = float(facing) * 90.0
			elif dist < 30.0:
				velocity.x = -float(facing) * 60.0
			else:
				velocity.x = 0.0

			move_and_slide()

			# Raise parry guard if player is close
			if dist <= 50.0 and parry_cooldown <= 0.0 and not is_parrying:
				_raise_parry()

			# Attack if parry is down and in range
			if attack_cooldown <= 0.0 and not is_parrying and dist <= 48.0:
				_execute_combo()

func _raise_parry() -> void:
	is_parrying = true
	parry_cooldown = 3.5
	var vis := get_node_or_null("Visual")
	if vis != null and vis.has_method("show_parry_tell"):
		vis.call("show_parry_tell")

	var timer := get_tree().create_timer(0.6) # 36 frames guard window
	timer.timeout.connect(func() -> void:
		is_parrying = false
	)

func _switch_stance() -> void:
	stance_timer = 0.0
	current_stance = Stance.KUSARIGAMA if current_stance == Stance.KATANA else Stance.KATANA
	stance_switched.emit(&"kusarigama" if current_stance == Stance.KUSARIGAMA else &"katana")
	var vis := get_node_or_null("Visual")
	if vis != null and vis.has_method("flash"):
		vis.call("flash")

func _execute_combo() -> void:
	attack_cooldown = 1.8
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player != null and is_instance_valid(player) and global_position.distance_to(player.global_position) <= 44.0:
		var hurtbox: Node = player.get_node_or_null("HurtboxComponent")
		if hurtbox != null and hurtbox.has_method("receive_hit"):
			hurtbox.call("receive_hit", slash_hitbox)
		elif player.has_method("die"):
			player.call("die", &"slashed")

func intercept_hit(hitbox: Area2D) -> bool:
	if not is_parrying:
		return false

	var facing_dir: float = float(facing)
	var is_frontal: bool = (hitbox.global_position.x - global_position.x) * facing_dir >= -6.0
	if not is_frontal:
		return false # Rear strike penetrates

	var is_heavy: bool = hitbox.has_meta(&"is_heavy") and bool(hitbox.get_meta(&"is_heavy"))
	var p_dmg: float = float(hitbox.get("poise_damage")) if hitbox.get("poise_damage") != null else 0.0

	if is_heavy or p_dmg >= 50.0:
		# Heavy breaks parry guard!
		is_parrying = false
		_on_staggered(1.8)
		return false

	# Parry deflected light strike!
	duelist_parried.emit()
	if NoiseBus != null:
		var ev := NoiseEvent.make(global_position, 220.0, 2.0, NoiseEvent.NoiseType.COMBAT, self)
		NoiseBus.emit_noise(ev)

	var vis := get_node_or_null("Visual")
	if vis != null and vis.has_method("flash"):
		vis.call("flash")

	# Riposte counter
	_execute_combo()
	return true
