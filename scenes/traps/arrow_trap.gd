class_name ArrowTrap
extends TrapBase

## ArrowTrap
## Wall-mounted mechanical arrow launcher.
## Telegraphed by aiming laser line for 0.5s before shooting.
## Projectile can be deflected by the player's parry back into hostiles.

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/traps/arrow_trap_projectile.tscn")

@export var firing_direction: Vector2 = Vector2.RIGHT

func _init() -> void:
	if data == null:
		data = TrapData.new(&"arrow_trap", 1, 0.50, 2.5, 80.0, 0.8, true)
		data.display_name = "Arrow Trap"
		data.trigger_type = &"proximity"
		data.can_be_disarmed = true
		data.disarm_frequency = 2 # Normal pulse disarm

func _ready() -> void:
	super._ready()
	if firing_direction.x < 0:
		scale.x = -1.0

func trigger_trap() -> void:
	if is_disarmed or current_state != State.IDLE:
		return

	current_state = State.TELEGRAPH
	state_timer = maxf(0.50, data.telegraph_time)
	has_damaged_this_cycle.clear()
	triggered.emit()

	if danger_marker != null:
		danger_marker.visible = true

	_play_anim(&"aim")

	if NoiseBus != null:
		var cue := NoiseEvent.make(global_position, 50.0, 0.4, NoiseEvent.NoiseType.CLINK, self)
		NoiseBus.emit_noise(cue)

func _enter_active_state() -> void:
	current_state = State.ACTIVE
	state_timer = data.active_time

	if danger_marker != null:
		danger_marker.visible = false

	_play_anim(&"shoot")

	# Spawn projectile
	var proj: ArrowTrapProjectile = PROJECTILE_SCENE.instantiate() as ArrowTrapProjectile
	proj.global_position = global_position + firing_direction * 16.0
	proj.direction = firing_direction.normalized()
	proj.damage = data.damage
	proj.source_trap = self
	if get_parent() != null:
		get_parent().add_child(proj)
	else:
		add_child(proj)

	if NoiseBus != null:
		var shot_ev := NoiseEvent.make(global_position, data.noise_radius, data.noise_loudness, NoiseEvent.NoiseType.COMBAT, self)
		NoiseBus.emit_noise(shot_ev)

func _enter_reset_state() -> void:
	current_state = State.RESET
	state_timer = data.cooldown
	_play_anim(&"retract")
