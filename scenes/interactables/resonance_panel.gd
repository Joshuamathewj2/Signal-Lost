class_name ResonancePanel
extends Area2D

## ResonancePanel
## Acoustic bulkhead with vibrating reeds. Must be excited by a matching acoustic frequency
## (Whisper wavefront or specific weapon strike). Emits 160 px resonant chime noise.

signal activated(panel: ResonancePanel)
signal failed(panel: ResonancePanel)
signal triggered(panel: ResonancePanel)

@export var required_tier: StringName = &"whisper" # &"whisper", &"normal", &"strike"
@export var panel_id: StringName = &"panel_alpha"
@export var lock_duration_on_fail: float = 3.0

var is_active: bool = false
var is_locked: bool = false
var lock_timer: float = 0.0
var reed_vibration: float = 0.0


func _ready() -> void:
	add_to_group(&"wave_reactive")
	add_to_group(&"resonance_panels")
	add_to_group(&"interactable")

	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(5, true) # interactable layer
	set_collision_mask_value(3, true) # player layer
	set_collision_mask_value(6, true) # hitbox layer

	# Collision shape (32x32)
	var cs: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs == null:
		cs = CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(32.0, 32.0)
		cs.shape = rect
		add_child(cs)


func on_wavefront(profile: PulseProfile, _origin: Vector2) -> void:
	if is_active or is_locked or profile == null:
		return

	if profile.id == required_tier:
		activate()
	else:
		lock_fail()


func on_hit(_hitbox: HitboxComponent) -> void:
	if is_active or is_locked:
		return

	if required_tier == &"strike" or required_tier == &"kunai" or required_tier == &"naginata":
		activate()


func activate() -> void:
	is_active = true
	reed_vibration = 1.0

	# Emits resonant chime noise on NoiseBus (r = 160 px, loudness 1.2)
	if NoiseBus != null:
		NoiseBus.emit_noise(NoiseEvent.make(global_position, 160.0, 1.2, NoiseEvent.NoiseType.IMPACT, self))

	if AudioManager != null:
		AudioManager.play_sfx(&"parry", global_position)

	activated.emit(self)
	triggered.emit(self)
	queue_redraw()


func lock_fail() -> void:
	is_locked = true
	lock_timer = lock_duration_on_fail
	failed.emit(self)
	queue_redraw()


func reset() -> void:
	is_active = false
	is_locked = false
	lock_timer = 0.0
	reed_vibration = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	if is_locked:
		lock_timer -= delta
		if lock_timer <= 0.0:
			is_locked = false
			queue_redraw()

	if reed_vibration > 0.0:
		reed_vibration = maxf(0.0, reed_vibration - delta * 2.0)
		queue_redraw()


func _draw() -> void:
	var border_col: Color = Color.WHITE
	if is_active:
		border_col = Color(0.2, 0.9, 1.0) # Cyan harmony
	elif is_locked:
		border_col = Color(1.0, 0.2, 0.2) # Red lockout

	# Bulkhead outer box (32x32 centered)
	var rect := Rect2(-16.0, -16.0, 32.0, 32.0)
	draw_rect(rect, Color(0.05, 0.05, 0.05, 0.9), true)
	draw_rect(rect, border_col, false, 2.0)

	# Vibrating acoustic reeds
	var reed_offset: float = sin(reed_vibration * 25.0) * (reed_vibration * 4.0)
	for i in [-8.0, 0.0, 8.0]:
		var top_pt := Vector2(i + reed_offset, -10.0)
		var bot_pt := Vector2(i, 10.0)
		draw_line(top_pt, bot_pt, border_col, 1.5)
