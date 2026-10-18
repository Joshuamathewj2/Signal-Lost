class_name SwingingBlade
extends TrapBase

## SwingingBlade
## Continuous pendulum blade suspended from the ceiling.
## Swings across a parabolic arc, damaging anything caught in the arc.
## Telegraphed by subtle red trajectory arc.

@export var swing_speed: float = 2.4
@export var max_angle_deg: float = 52.0
@export var arm_length: float = 64.0

var swing_time: float = 0.0
var prev_sign: float = 0.0

@onready var pivot: Node2D = get_node_or_null("Pivot") as Node2D

func _init() -> void:
	if data == null:
		data = TrapData.new(&"swinging_blade", 2, 0.50, 0.0, 100.0, 1.0, true)
		data.display_name = "Swinging Blade"
		data.trigger_type = &"continuous"
		data.poise_damage = 45.0

func _ready() -> void:
	super._ready()
	current_state = State.ACTIVE
	if damage_area != null:
		damage_area.monitoring = true
		damage_area.monitorable = true
	if danger_marker != null:
		danger_marker.visible = true

func _process(delta: float) -> void:
	if is_disarmed:
		return

	swing_time += delta * swing_speed
	var current_angle_rad: float = sin(swing_time) * deg_to_rad(max_angle_deg)

	if pivot != null:
		pivot.rotation = current_angle_rad

	# Animation selection based on swing angle and direction
	var current_sign: float = signf(cos(swing_time)) # direction of swing
	if absf(current_angle_rad) < deg_to_rad(15.0):
		_play_anim(&"swing_center")
		if current_sign != prev_sign and NoiseBus != null:
			# Swung through apex center
			var whoosh := NoiseEvent.make(global_position + Vector2(0, arm_length), data.noise_radius, data.noise_loudness, NoiseEvent.NoiseType.COMBAT, self)
			NoiseBus.emit_noise(whoosh)
			has_damaged_this_cycle.clear()
	elif current_angle_rad < 0.0:
		_play_anim(&"swing_left" if current_sign < 0.0 else &"back_left")
	else:
		_play_anim(&"swing_right")

	prev_sign = current_sign

	if damage_area != null and damage_area.monitoring:
		_check_active_overlaps()
