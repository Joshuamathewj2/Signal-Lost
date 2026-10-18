class_name OniEnforcer
extends EnemyBase

## OniEnforcer
## Brutal powerhouse mini-boss guarding Sector 8 (12 HP).
## Attacks with overhead Kanabo club slams producing ground-traveling acoustic shockwaves.
## Enters Phase 2 Rage at <= 50% HP (6 HP), gaining flame horns, 1.5x speed, and rapid attacks.

signal rage_entered
signal ground_slammed

var slam_cooldown: float = 0.0
var is_slamming: bool = false
var slam_timer: float = 0.0

@onready var kanabo_hitbox: Area2D = $Hitbox

func _ready() -> void:
	kind = &"oni_enforcer"
	super._ready()
	if health_component != null:
		health_component.max_health = 12
		health_component.current_health = 12
	if poise_component != null:
		poise_component.max_poise = 120.0
		poise_component.current_poise = 120.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if slam_cooldown > 0.0:
		slam_cooldown -= delta

	if is_slamming:
		slam_timer -= delta
		if slam_timer <= 0.0:
			_execute_slam()
		return

	# Check for Phase 2 rage
	if not is_enraged and health_component != null and health_component.current_health <= 6:
		_enter_rage()

	# Combat behavior when alert
	if awareness != null and awareness.is_alert:
		var player := get_tree().get_first_node_in_group(&"player") as Node2D
		if player != null and is_instance_valid(player):
			var dist := global_position.distance_to(player.global_position)
			face(1 if player.global_position.x > global_position.x else -1)

			var speed_mult: float = 1.5 if is_enraged else 1.0
			if dist > 44.0:
				velocity.x = float(facing) * 60.0 * speed_mult
			else:
				velocity.x = 0.0

			move_and_slide()

			if slam_cooldown <= 0.0 and dist <= 64.0:
				_start_slam()

func _start_slam() -> void:
	is_slamming = true
	slam_timer = 0.4 if is_enraged else 0.6
	velocity = Vector2.ZERO

	var vis := get_node_or_null("Visual")
	if vis != null and vis.has_method("show_slam_tell"):
		vis.call("show_slam_tell")

func _execute_slam() -> void:
	is_slamming = false
	slam_cooldown = 1.6 if is_enraged else 2.8
	ground_slammed.emit()

	# Heavy ground impact noise & shockwave
	if NoiseBus != null:
		var shock_radius: float = 340.0 if is_enraged else 220.0
		var ev := NoiseEvent.make(global_position, shock_radius, 2.5, NoiseEvent.NoiseType.COMBAT, self)
		NoiseBus.emit_noise(ev)

	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player != null and is_instance_valid(player):
		var dist := global_position.distance_to(player.global_position)
		if dist <= 56.0:
			var hurtbox: Node = player.get_node_or_null("HurtboxComponent")
			if hurtbox != null and hurtbox.has_method("receive_hit"):
				hurtbox.call("receive_hit", kanabo_hitbox)
			elif player.has_method("die"):
				player.call("die", &"crushed")

func _enter_rage() -> void:
	is_enraged = true
	rage_entered.emit()

	var vis := get_node_or_null("Visual")
	if vis != null and vis.has_method("set_enraged"):
		vis.call("set_enraged", true)

	if NoiseBus != null:
		var ev := NoiseEvent.make(global_position, 480.0, 3.0, NoiseEvent.NoiseType.PULSE, self)
		NoiseBus.emit_noise(ev)
