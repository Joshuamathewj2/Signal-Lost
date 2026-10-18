class_name TrapBase
extends Node2D

## TrapBase
## Foundational controller for mechanical traps and environmental hazards.
## Enforces state machine cycling, >= 0.5s telegraphs with red danger cues,
## dual-target hitboxes (player + enemies), NoiseBus emission, and acoustic disarming.

signal triggered
signal struck(target: Node2D)
signal disarmed

enum State {
	IDLE = 0,
	TELEGRAPH = 1,
	ACTIVE = 2,
	RESET = 3,
	DISARMED = 4
}

@export var data: TrapData
@export var trigger_on_start: bool = false

var current_state: int = State.IDLE
var state_timer: float = 0.0
var is_disarmed: bool = false
var has_damaged_this_cycle: Dictionary = {} # target: bool

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
@onready var trigger_area: Area2D = get_node_or_null("TriggerArea") as Area2D
@onready var damage_area: Area2D = get_node_or_null("DamageArea") as Area2D
@onready var danger_marker: CanvasItem = get_node_or_null("DangerMarker") as CanvasItem

func _ready() -> void:
	if data == null:
		data = TrapData.new(&"trap", 2, 0.50, 2.0, 80.0, 1.0, true)

	add_to_group(&"traps")
	if TrapRegistry != null:
		TrapRegistry.register_trap(self)

	if danger_marker != null:
		danger_marker.visible = false

	if damage_area != null:
		damage_area.monitoring = false
		damage_area.monitorable = false
		if not damage_area.body_entered.is_connected(_on_damage_body_entered):
			damage_area.body_entered.connect(_on_damage_body_entered)
		if not damage_area.area_entered.is_connected(_on_damage_area_entered):
			damage_area.area_entered.connect(_on_damage_area_entered)

	if trigger_area != null:
		if not trigger_area.body_entered.is_connected(_on_trigger_body_entered):
			trigger_area.body_entered.connect(_on_trigger_body_entered)

	# Listen for pulse-based acoustic disarm
	if PulseRegistry != null and PulseRegistry.has_signal("pulse_emitted"):
		PulseRegistry.pulse_emitted.connect(_on_pulse_emitted)

	_play_anim(&"idle")

	if trigger_on_start or data.trigger_type == &"timer" or data.trigger_type == &"continuous":
		if data.initial_delay > 0.0:
			state_timer = data.initial_delay
			current_state = State.RESET
		else:
			trigger_trap()

func _exit_tree() -> void:
	if TrapRegistry != null:
		TrapRegistry.unregister_trap(self)

func _process(delta: float) -> void:
	if is_disarmed or current_state == State.DISARMED:
		return

	if state_timer > 0.0:
		state_timer -= delta
		if state_timer <= 0.0:
			_advance_state()

	# If active and damage_area has monitoring, verify overlap continuously
	if current_state == State.ACTIVE and damage_area != null and damage_area.monitoring:
		_check_active_overlaps()

func trigger_trap() -> void:
	if is_disarmed or current_state != State.IDLE:
		return

	current_state = State.TELEGRAPH
	state_timer = maxf(0.50, data.telegraph_time) # Guaranteed >= 0.5s telegraph
	has_damaged_this_cycle.clear()
	triggered.emit()

	# Visual & acoustic telegraph
	if danger_marker != null:
		danger_marker.visible = true
		danger_marker.modulate = data.danger_accent_color
		# Subtle danger marker pulse
		var tw := create_tween()
		tw.set_loops(int(state_timer * 4.0))
		tw.tween_property(danger_marker, "modulate:a", 1.0, 0.12)
		tw.tween_property(danger_marker, "modulate:a", 0.35, 0.12)

	_play_anim(&"trigger")
	if not _has_anim(&"trigger"):
		_play_anim(&"aim")
	if not _has_anim(&"trigger") and not _has_anim(&"aim"):
		_play_anim(&"charge")
	if not _has_anim(&"trigger") and not _has_anim(&"aim") and not _has_anim(&"charge"):
		_play_anim(&"crack")

	# Telegraph audio cue (metallic click / tension rumble)
	if NoiseBus != null:
		var cue := NoiseEvent.make(global_position, 60.0, 0.6, NoiseEvent.NoiseType.CLINK, self)
		NoiseBus.emit_noise(cue)

func _advance_state() -> void:
	match current_state:
		State.TELEGRAPH:
			_enter_active_state()
		State.ACTIVE:
			_enter_reset_state()
		State.RESET:
			_enter_idle_state()
		_:
			pass

func _enter_active_state() -> void:
	current_state = State.ACTIVE
	state_timer = data.active_time

	if danger_marker != null:
		danger_marker.visible = false

	if damage_area != null:
		damage_area.monitoring = true
		damage_area.monitorable = true

	# Play primary strike animation
	_play_anim(&"full")
	if not _has_anim(&"full"):
		_play_anim(&"attack")
	if not _has_anim(&"full") and not _has_anim(&"attack"):
		_play_anim(&"launch")
	if not _has_anim(&"full") and not _has_anim(&"attack") and not _has_anim(&"launch"):
		_play_anim(&"drop")
	if not _has_anim(&"full") and not _has_anim(&"attack") and not _has_anim(&"launch") and not _has_anim(&"drop"):
		_play_anim(&"flame")

	# NoiseBus emission for trap strike
	if NoiseBus != null:
		var loud_ev := NoiseEvent.make(global_position, data.noise_radius, data.noise_loudness, NoiseEvent.NoiseType.IMPACT, self)
		NoiseBus.emit_noise(loud_ev)

	_check_active_overlaps()

func _enter_reset_state() -> void:
	current_state = State.RESET
	state_timer = data.cooldown

	if damage_area != null:
		damage_area.monitoring = false
		damage_area.monitorable = false

	_play_anim(&"reset")
	if not _has_anim(&"reset"):
		_play_anim(&"retract")
	if not _has_anim(&"reset") and not _has_anim(&"retract"):
		_play_anim(&"off")

func _enter_idle_state() -> void:
	current_state = State.IDLE
	_play_anim(&"idle")
	if not _has_anim(&"idle"):
		_play_anim(&"hidden")

	# Periodic traps restart automatically
	if data.trigger_type == &"timer" or data.trigger_type == &"continuous":
		trigger_trap()

func disarm() -> void:
	if is_disarmed:
		return
	is_disarmed = true
	current_state = State.DISARMED
	state_timer = 0.0

	if danger_marker != null:
		danger_marker.visible = false
	if damage_area != null:
		damage_area.monitoring = false
		damage_area.monitorable = false

	# Visual feedback: muted blue-grey disabled tint
	modulate = Color(0.6, 0.7, 0.85, 0.5)
	disarmed.emit()
	if TrapRegistry != null:
		TrapRegistry.trap_disarmed.emit(self, data.trap_id)

func _on_trigger_body_entered(body: Node2D) -> void:
	if is_disarmed or current_state != State.IDLE:
		return
	if body.is_in_group(&"player") or (data.affects_enemies and body.is_in_group(&"enemies")):
		trigger_trap()

func _on_damage_body_entered(body: Node2D) -> void:
	_deliver_damage_to(body)

func _on_damage_area_entered(area: Area2D) -> void:
	var parent: Node = area.get_parent()
	if parent is Node2D:
		_deliver_damage_to(parent as Node2D)

func _check_active_overlaps() -> void:
	if damage_area == null or not damage_area.monitoring:
		return
	for body in damage_area.get_overlapping_bodies():
		if body is Node2D:
			_deliver_damage_to(body)
	for area in damage_area.get_overlapping_areas():
		var parent: Node = area.get_parent()
		if parent is Node2D:
			_deliver_damage_to(parent as Node2D)

func _deliver_damage_to(target: Node2D) -> void:
	if is_disarmed or current_state != State.ACTIVE:
		return
	if target == self:
		return
	if has_damaged_this_cycle.has(target):
		return

	# Calculate knockback vector pointing away from trap center
	var kb_dir: Vector2 = (target.global_position - global_position).normalized()
	if kb_dir.length_squared() < 0.01:
		kb_dir = Vector2.UP
	var kb: Vector2 = kb_dir * data.knockback_force

	var hit_applied: bool = false
	var dmg: int = data.damage
	if GameState != null and GameState.has_method("get_trap_damage_modifier"):
		dmg += GameState.get_trap_damage_modifier()

	# 1. Player check
	if target.is_in_group(&"player") or target.name == "Player":
		if target.has_method("take_damage"):
			target.call("take_damage", dmg, kb)
			hit_applied = true
		elif target.get("health") != null and target.health.has_method("take_damage"):
			target.health.call("take_damage", dmg, kb)
			hit_applied = true

	# 2. Enemy check
	elif data.affects_enemies and (target.is_in_group(&"enemies") or target.has_node("HealthComponent") or target.has_method("take_hit")):
		var hc: Node = target.get_node_or_null("HealthComponent")
		if hc != null and hc.has_method("take_damage"):
			# Directly damage enemy HealthComponent with &"trap" cause -> hooks EnemyRegistry!
			hc.call("take_damage", dmg, kb, &"trap")
			hit_applied = true
		elif target.has_method("take_damage"):
			target.call("take_damage", dmg)
			hit_applied = true

		# Also apply flinch / poise break if enemy supports it
		if target.has_method("_on_hit_flinch"):
			target.call("_on_hit_flinch", data.poise_damage, kb)

	if hit_applied:
		has_damaged_this_cycle[target] = true
		struck.emit(target)
		# Hitstop & Camera Shake
		if HitStop != null and data.hitstop_duration > 0.0 and is_inside_tree() and get_tree() != null:
			HitStop.freeze(get_tree(), data.hitstop_duration)

func _on_pulse_emitted(tier: int, pos: Vector2, _r: float) -> void:
	if not data.can_be_disarmed or is_disarmed:
		return
	if data.disarm_frequency > 0 and data.disarm_frequency == tier:
		if global_position.distance_to(pos) <= 180.0:
			disarm()

func _play_anim(anim_name: StringName) -> void:
	if sprite != null and sprite.sprite_frames != null:
		if sprite.sprite_frames.has_animation(anim_name):
			sprite.play(anim_name)

func _has_anim(anim_name: StringName) -> bool:
	if sprite != null and sprite.sprite_frames != null:
		return sprite.sprite_frames.has_animation(anim_name)
	return false
