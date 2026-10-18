class_name RollingBoulder
extends TrapBase

## RollingBoulder
## Heavy spherical stone boulder released by tripwire or pressure plate.
## Rolls along platforms at high speed, crushing all entities and smashing breakables.
## Produces a 240px acoustic footprint on the NoiseBus.

@export var roll_speed: float = 280.0
@export var roll_direction: float = 1.0 # 1 = right, -1 = left

var is_rolling: bool = false
var velocity_vector: Vector2 = Vector2.ZERO
var initial_pos: Vector2 = Vector2.ZERO

func _init() -> void:
	if data == null:
		data = TrapData.new(&"rolling_boulder", 3, 0.50, 6.0, 240.0, 2.5, true)
		data.display_name = "Rolling Boulder"
		data.poise_damage = 100.0
		data.camera_shake = 3.0

func _ready() -> void:
	super._ready()
	initial_pos = position

func trigger_trap() -> void:
	if is_disarmed or current_state != State.IDLE:
		return

	current_state = State.TELEGRAPH
	state_timer = maxf(0.50, data.telegraph_time)
	has_damaged_this_cycle.clear()
	triggered.emit()

	if danger_marker != null:
		danger_marker.visible = true

	# Rumble shake telegraph
	if sprite != null:
		var tw := create_tween()
		for i in range(5):
			tw.tween_property(sprite, "position:y", randf_range(-2.0, 2.0), 0.1)
		tw.tween_property(sprite, "position:y", 0.0, 0.1)

	if NoiseBus != null:
		var rumble := NoiseEvent.make(global_position, 120.0, 1.2, NoiseEvent.NoiseType.IMPACT, self)
		NoiseBus.emit_noise(rumble)

func _enter_active_state() -> void:
	current_state = State.ACTIVE
	state_timer = 4.0 # Maximum roll time
	is_rolling = true
	velocity_vector = Vector2(roll_direction * roll_speed, 0.0)

	if danger_marker != null:
		danger_marker.visible = false

	if damage_area != null:
		damage_area.monitoring = true
		damage_area.monitorable = true

	_play_anim(&"roll")

	if NoiseBus != null:
		var loud_rumble := NoiseEvent.make(global_position, data.noise_radius, data.noise_loudness, NoiseEvent.NoiseType.IMPACT, self)
		NoiseBus.emit_noise(loud_rumble)

func _physics_process(delta: float) -> void:
	if not is_rolling:
		return

	position += velocity_vector * delta

	# Continuous rolling noise
	if Engine.get_physics_frames() % 30 == 0 and NoiseBus != null:
		var step_noise := NoiseEvent.make(global_position, 180.0, 1.5, NoiseEvent.NoiseType.LAND, self)
		NoiseBus.emit_noise(step_noise)

	_check_active_overlaps()

func _deliver_damage_to(target: Node2D) -> void:
	super._deliver_damage_to(target)

	# Breakable shatter check
	if target.has_method("shatter"):
		target.call("shatter")
	elif target.get("mode") == "GLASS" or target is GlassFloor:
		if target.has_method("shatter"):
			target.call("shatter")

func _enter_reset_state() -> void:
	is_rolling = false
	current_state = State.RESET
	state_timer = data.cooldown

	if damage_area != null:
		damage_area.monitoring = false
		damage_area.monitorable = false

	# Respawn boulder at origin
	var reset_tw := create_tween()
	reset_tw.tween_property(self, "modulate:a", 0.0, 0.5)
	reset_tw.tween_callback(func() -> void:
		position = initial_pos
		_play_anim(&"idle")
	)
	reset_tw.tween_property(self, "modulate:a", 1.0, 0.5)
