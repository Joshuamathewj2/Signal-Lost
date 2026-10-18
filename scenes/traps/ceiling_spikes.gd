class_name CeilingSpikes
extends TrapBase

## CeilingSpikes
## Ceiling-mounted crushing spike plate.
## Triggered when player or enemy enters vertical detection corridor below.
## Telegraphed by ceiling tremor, dust particles, and floor danger reticle for 0.6s before drop.

@export var drop_distance: float = 80.0

var initial_sprite_y: float = 0.0

func _init() -> void:
	if data == null:
		data = TrapData.new(&"ceiling_spikes", 3, 0.60, 3.0, 180.0, 1.8, true)
		data.display_name = "Ceiling Spikes"
		data.poise_damage = 80.0
		data.camera_shake = 3.5

func _ready() -> void:
	super._ready()
	if sprite != null:
		initial_sprite_y = sprite.position.y

func trigger_trap() -> void:
	if is_disarmed or current_state != State.IDLE:
		return

	current_state = State.TELEGRAPH
	state_timer = maxf(0.50, data.telegraph_time)
	has_damaged_this_cycle.clear()
	triggered.emit()

	# Ceiling shake telegraph
	if sprite != null:
		var tw := create_tween()
		for i in range(5):
			tw.tween_property(sprite, "position:x", randf_range(-2.0, 2.0), 0.1)
		tw.tween_property(sprite, "position:x", 0.0, 0.1)

	# Red ground danger marker
	if danger_marker != null:
		danger_marker.visible = true
		danger_marker.position.y = drop_distance

	# Dust particles from ceiling
	ParticlesFactory.spawn_landing_dust(get_parent(), global_position)

	_play_anim(&"idle")

func _enter_active_state() -> void:
	current_state = State.ACTIVE
	state_timer = data.active_time

	if danger_marker != null:
		danger_marker.visible = false

	if damage_area != null:
		damage_area.monitoring = true
		damage_area.monitorable = true
		damage_area.position.y = drop_distance

	_play_anim(&"drop")

	# Slam down tween
	if sprite != null:
		var drop_tw := create_tween()
		drop_tw.tween_property(sprite, "position:y", drop_distance, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		drop_tw.tween_callback(func() -> void:
			_play_anim(&"full")
			ParticlesFactory.spawn_landing_dust(get_parent(), global_position + Vector2(0, drop_distance))
		)

	if NoiseBus != null:
		var slam_ev := NoiseEvent.make(global_position + Vector2(0, drop_distance), data.noise_radius, data.noise_loudness, NoiseEvent.NoiseType.IMPACT, self)
		NoiseBus.emit_noise(slam_ev)

	_check_active_overlaps()

func _enter_reset_state() -> void:
	current_state = State.RESET
	state_timer = data.cooldown

	if damage_area != null:
		damage_area.monitoring = false
		damage_area.monitorable = false

	_play_anim(&"reset")

	# Winch slowly back up
	if sprite != null:
		var winch_tw := create_tween()
		winch_tw.tween_property(sprite, "position:y", initial_sprite_y, 1.2).set_trans(Tween.TRANS_LINEAR)
		winch_tw.tween_callback(func() -> void:
			if damage_area != null:
				damage_area.position.y = 0.0
		)
