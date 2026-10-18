class_name WallBlade
extends TrapBase

## WallBlade
## Wall-recessed horizontal thrusting blade.
## Operates periodically or on proximity tripwire.
## Telegraphed by a 0.5s red laser line and metallic scraping cue.

@export var facing_dir: int = 1 # 1 = right, -1 = left

func _init() -> void:
	if data == null:
		data = TrapData.new(&"wall_blade", 2, 0.50, 2.2, 90.0, 0.9, true)
		data.display_name = "Wall Blade"
		data.trigger_type = &"timer"
		data.poise_damage = 40.0

func _ready() -> void:
	super._ready()
	scale.x = float(facing_dir)

func trigger_trap() -> void:
	if is_disarmed or current_state != State.IDLE:
		return

	current_state = State.TELEGRAPH
	state_timer = maxf(0.50, data.telegraph_time)
	has_damaged_this_cycle.clear()
	triggered.emit()

	if danger_marker != null:
		danger_marker.visible = true

	_play_anim(&"extend")

	if NoiseBus != null:
		var cue := NoiseEvent.make(global_position, 50.0, 0.5, NoiseEvent.NoiseType.CLINK, self)
		NoiseBus.emit_noise(cue)

func _enter_active_state() -> void:
	current_state = State.ACTIVE
	state_timer = data.active_time

	if danger_marker != null:
		danger_marker.visible = false

	if damage_area != null:
		damage_area.monitoring = true
		damage_area.monitorable = true

	_play_anim(&"attack")

	if NoiseBus != null:
		var slash_ev := NoiseEvent.make(global_position + Vector2(facing_dir * 24.0, 0.0), data.noise_radius, data.noise_loudness, NoiseEvent.NoiseType.IMPACT, self)
		NoiseBus.emit_noise(slash_ev)

	_check_active_overlaps()

func _enter_reset_state() -> void:
	current_state = State.RESET
	state_timer = data.cooldown

	if damage_area != null:
		damage_area.monitoring = false
		damage_area.monitorable = false

	_play_anim(&"retract")
