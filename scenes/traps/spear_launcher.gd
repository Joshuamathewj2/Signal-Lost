class_name SpearLauncher
extends TrapBase

## SpearLauncher
## High-velocity floor or wall mounted pneumatic spear launcher.
## Telegraphed by a 0.5s mechanical charge lock and red danger alignment line.

@export var launch_direction: Vector2 = Vector2.UP

func _init() -> void:
	if data == null:
		data = TrapData.new(&"spear_launcher", 2, 0.50, 2.0, 120.0, 1.2, true)
		data.display_name = "Spear Launcher"
		data.poise_damage = 50.0

func _ready() -> void:
	super._ready()
	rotation = launch_direction.angle() + deg_to_rad(90.0)

func trigger_trap() -> void:
	if is_disarmed or current_state != State.IDLE:
		return

	current_state = State.TELEGRAPH
	state_timer = maxf(0.50, data.telegraph_time)
	has_damaged_this_cycle.clear()
	triggered.emit()

	if danger_marker != null:
		danger_marker.visible = true

	_play_anim(&"charge")

	if NoiseBus != null:
		var cue := NoiseEvent.make(global_position, 60.0, 0.6, NoiseEvent.NoiseType.CLINK, self)
		NoiseBus.emit_noise(cue)

func _enter_active_state() -> void:
	current_state = State.ACTIVE
	state_timer = data.active_time

	if danger_marker != null:
		danger_marker.visible = false

	if damage_area != null:
		damage_area.monitoring = true
		damage_area.monitorable = true

	_play_anim(&"launch")

	if NoiseBus != null:
		var launch_ev := NoiseEvent.make(global_position, data.noise_radius, data.noise_loudness, NoiseEvent.NoiseType.IMPACT, self)
		NoiseBus.emit_noise(launch_ev)

	_check_active_overlaps()

func _enter_reset_state() -> void:
	current_state = State.RESET
	state_timer = data.cooldown

	if damage_area != null:
		damage_area.monitoring = false
		damage_area.monitorable = false

	_play_anim(&"retract")
