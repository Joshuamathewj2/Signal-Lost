class_name Guillotine
extends TrapBase

## Guillotine
## Heavy vertical descending razor blade.
## Operates on timed interval or proximity trigger.
## Rapid 0.12s drop dealing 3 DMG (lethal to basic foes), slow mechanical reset.

@export var drop_distance: float = 64.0

var initial_sprite_y: float = 0.0

func _init() -> void:
	if data == null:
		data = TrapData.new(&"guillotine", 3, 0.50, 2.5, 160.0, 1.6, true)
		data.display_name = "Guillotine"
		data.trigger_type = &"timer"
		data.poise_damage = 90.0
		data.camera_shake = 3.0

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

	if danger_marker != null:
		danger_marker.visible = true
		danger_marker.position.y = drop_distance

	# Blade rattle cue
	if sprite != null:
		var tw := create_tween()
		for i in range(4):
			tw.tween_property(sprite, "position:x", randf_range(-1.5, 1.5), 0.1)
		tw.tween_property(sprite, "position:x", 0.0, 0.1)

	if NoiseBus != null:
		var rattle := NoiseEvent.make(global_position, 60.0, 0.6, NoiseEvent.NoiseType.CLINK, self)
		NoiseBus.emit_noise(rattle)

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

	# Razor drop tween
	if sprite != null:
		var drop_tw := create_tween()
		drop_tw.tween_property(sprite, "position:y", drop_distance, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		drop_tw.tween_callback(func() -> void:
			_play_anim(&"full")
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

	# Slow winch back up
	if sprite != null:
		var winch_tw := create_tween()
		winch_tw.tween_property(sprite, "position:y", initial_sprite_y, 1.4).set_trans(Tween.TRANS_LINEAR)
		winch_tw.tween_callback(func() -> void:
			if damage_area != null:
				damage_area.position.y = 0.0
		)
