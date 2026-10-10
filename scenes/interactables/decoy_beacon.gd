class_name DecoyBeacon
extends AnimatableBody2D

const WORLD_RETICLE_SCENE: PackedScene = preload("res://scenes/ui/world_reticle.tscn")
const PULSE_DECOY_RES: PulseProfile = preload("res://resources/pulses/pulse_decoy.tres")

var velocity: Vector2 = Vector2.ZERO
var gravity: float = 980.0
var landed: bool = false
var _timer: float = 0.0
var _triggered: bool = false
var _reticle: WorldReticle = null

func _ready() -> void:
	# Collide with world layer 1
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(1, true)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	add_child(shape)

	_reticle = WORLD_RETICLE_SCENE.instantiate() as WorldReticle
	_reticle.reticle_type = WorldReticle.Type.DECOY
	add_child(_reticle)

func _physics_process(delta: float) -> void:
	if not landed:
		velocity.y += gravity * delta
		var col := move_and_collide(velocity * delta)
		if col != null:
			landed = true
			velocity = Vector2.ZERO
			_timer = 0.5
	else:
		if not _triggered:
			_timer -= delta
			if _timer <= 0.0:
				_trigger_decoy()

func _trigger_decoy() -> void:
	_triggered = true
	var pulse: PulseProfile = PULSE_DECOY_RES
	if pulse == null:
		pulse = PulseProfile.new()
		pulse.reveal_radius = 200.0
		pulse.loudness = 2.0
		pulse.noise_mult = 1.0

	# 1. Spawn SonarSystem pulse
	var ss: SonarSystem = get_tree().get_first_node_in_group(&"sonar_system") as SonarSystem
	if ss == null:
		var root: Node = get_tree().current_scene
		if root != null:
			ss = root.find_child("SonarSystem", true, false) as SonarSystem

	if ss != null:
		ss.spawn(pulse, global_position)

	# 2. Emit DECOY NoiseEvent
	var ev := NoiseEvent.make(global_position, pulse.noise_radius(), 2.0, NoiseEvent.NoiseType.DECOY, self)
	NoiseBus.emit_noise_event(ev)

	# 3. Fade and queue_free
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func _draw() -> void:
	# 4x6 px small beacon with danger red tip
	var body_col := Palette.color(&"actor_subtle")
	var tip_col := Palette.color(&"danger")
	draw_rect(Rect2(-2, -5, 4, 8), body_col, true)
	draw_circle(Vector2(0, -6), 2.5, tip_col)
