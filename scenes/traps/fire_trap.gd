class_name FireTrap
extends TrapBase

## FireTrap
## Periodic gas nozzle emitting intense flame jet.
## Preceded by a 0.6s charge phase with gas hiss, spark embers, and red thermal reticle.
## Roaring flame jet deals 2 DMG to anything inside for 1.2s.

@export var jet_direction: Vector2 = Vector2.UP

func _init() -> void:
	if data == null:
		data = TrapData.new(&"fire_trap", 2, 0.60, 2.0, 140.0, 1.4, true)
		data.display_name = "Fire Trap"
		data.trigger_type = &"timer"
		data.active_time = 1.20
		data.poise_damage = 35.0
		data.can_be_disarmed = true
		data.disarm_frequency = 3 # Scream pulse disables gas feed

func _ready() -> void:
	super._ready()
	rotation = jet_direction.angle() + deg_to_rad(90.0)

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
		var hiss := NoiseEvent.make(global_position, 60.0, 0.5, NoiseEvent.NoiseType.PULSE, self)
		NoiseBus.emit_noise(hiss)

func _enter_active_state() -> void:
	current_state = State.ACTIVE
	state_timer = data.active_time

	if danger_marker != null:
		danger_marker.visible = false

	if damage_area != null:
		damage_area.monitoring = true
		damage_area.monitorable = true

	_play_anim(&"flame")

	if NoiseBus != null:
		var roar := NoiseEvent.make(global_position, data.noise_radius, data.noise_loudness, NoiseEvent.NoiseType.IMPACT, self)
		NoiseBus.emit_noise(roar)

	_check_active_overlaps()

func _enter_reset_state() -> void:
	current_state = State.RESET
	state_timer = data.cooldown

	if damage_area != null:
		damage_area.monitoring = false
		damage_area.monitorable = false

	_play_anim(&"off")
