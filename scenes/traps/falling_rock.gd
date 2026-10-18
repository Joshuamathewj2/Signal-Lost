class_name FallingRock
extends TrapBase

## FallingRock
## Suspended unstable ceiling rock/boulder block.
## Cracks and shakes for 0.6s with ceiling debris before plunging vertically.
## Deals lethal crushing damage (3 DMG) to both player and enemies on floor impact.

@export var drop_distance: float = 96.0

var initial_y: float = 0.0

func _init() -> void:
	if data == null:
		data = TrapData.new(&"falling_rock", 3, 0.60, 3.5, 220.0, 2.2, true)
		data.display_name = "Falling Rock"
		data.poise_damage = 90.0
		data.camera_shake = 4.0

func _ready() -> void:
	super._ready()
	initial_y = position.y

func trigger_trap() -> void:
	if is_disarmed or current_state != State.IDLE:
		return

	current_state = State.TELEGRAPH
	state_timer = maxf(0.50, data.telegraph_time)
	has_damaged_this_cycle.clear()
	triggered.emit()

	if danger_marker != null:
		danger_marker.visible = true
		danger_marker.position.y = drop_distance

	_play_anim(&"crack")

	# Ceiling crack tremors & debris
	if sprite != null:
		var tw := create_tween()
		for i in range(6):
			tw.tween_property(sprite, "position:x", randf_range(-2.5, 2.5), 0.08)
		tw.tween_property(sprite, "position:x", 0.0, 0.08)

	ParticlesFactory.spawn_landing_dust(get_parent(), global_position)

	if NoiseBus != null:
		var cue := NoiseEvent.make(global_position, 80.0, 0.8, NoiseEvent.NoiseType.IMPACT, self)
		NoiseBus.emit_noise(cue)

func _enter_active_state() -> void:
	current_state = State.ACTIVE
	state_timer = data.active_time

	if danger_marker != null:
		danger_marker.visible = false

	_play_anim(&"fall")

	# Physics drop
	var drop_tw := create_tween()
	drop_tw.tween_property(self, "position:y", initial_y + drop_distance, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	drop_tw.tween_callback(func() -> void:
		_on_rock_impact()
	)

func _on_rock_impact() -> void:
	_play_anim(&"impact")

	if damage_area != null:
		damage_area.monitoring = true
		damage_area.monitorable = true
		_check_active_overlaps()

	ParticlesFactory.spawn_landing_dust(get_parent(), global_position)

	if NoiseBus != null:
		var impact_ev := NoiseEvent.make(global_position, data.noise_radius, data.noise_loudness, NoiseEvent.NoiseType.IMPACT, self)
		NoiseBus.emit_noise(impact_ev)

func _enter_reset_state() -> void:
	current_state = State.RESET
	state_timer = data.cooldown

	if damage_area != null:
		damage_area.monitoring = false
		damage_area.monitorable = false

	_play_anim(&"reset")

	# Return rock to ceiling
	var reset_tw := create_tween()
	reset_tw.tween_property(self, "modulate:a", 0.0, 0.4)
	reset_tw.tween_callback(func() -> void:
		position.y = initial_y
		_play_anim(&"idle")
	)
	reset_tw.tween_property(self, "modulate:a", 1.0, 0.4)
