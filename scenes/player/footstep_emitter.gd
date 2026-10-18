class_name FootstepEmitter
extends Node

@export var player: CharacterBody2D
@export var motor: PlayerMotor

var step_timer: float = 0.0

func _ready() -> void:
	if motor != null:
		motor.landed.connect(_on_motor_landed)
		motor.jumped.connect(_on_motor_jumped)

func _process(delta: float) -> void:
	if player == null or motor == null:
		return

	var cfg: GameConfigData = GameConfig.data

	if motor.is_on_floor and not motor.is_sneaking and absf(player.velocity.x) > cfg.footstep_min_speed:
		step_timer -= delta
		if step_timer <= 0.0:
			step_timer = cfg.footstep_interval
			_emit_step()
	else:
		step_timer = 0.0

func _emit_step() -> void:
	var cfg: GameConfigData = GameConfig.data
	var origin: Vector2 = player.global_position
	var speed_x: float = absf(player.velocity.x)
	var radius: float = cfg.footstep_radius
	var loudness: float = cfg.footstep_loudness
	if speed_x > 110.0:
		radius = 80.0
		loudness = 1.0
	var ev: NoiseEvent = NoiseEvent.make(
		origin,
		radius,
		loudness,
		NoiseEvent.NoiseType.FOOTSTEP,
		player
	)
	ev.tag = &"run" if speed_x > 110.0 else &"walk"
	NoiseBus.emit_noise(ev)

func _on_motor_landed(impact_speed: float) -> void:
	var cfg: GameConfigData = GameConfig.data
	if impact_speed > cfg.land_speed_threshold:
		var origin: Vector2 = player.global_position
		var ev: NoiseEvent = NoiseEvent.make(
			origin,
			cfg.land_radius,
			cfg.land_loudness,
			NoiseEvent.NoiseType.LAND,
			player
		)
		ev.tag = &"land"
		NoiseBus.emit_noise(ev)


## Jump take-off scuff (data/noise.json actions.jump, default 0.3).
func _on_motor_jumped() -> void:
	if player != null and NoiseBus != null:
		NoiseBus.emit_action(player, player.global_position, &"jump", NoiseEvent.NoiseType.FOOTSTEP)
