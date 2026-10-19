class_name ExitTerminal
extends Interactable

@onready var screen_fill: Polygon2D = get_node_or_null("Visual/ScreenFill") as Polygon2D
@onready var beacon_dot: Polygon2D = get_node_or_null("Visual/BeaconDot") as Polygon2D
@onready var restored_label: Label = get_node_or_null("Visual/RestoredLabel") as Label

var _activated: bool = false
var is_locked: bool = true

func _ready() -> void:
	super._ready()
	if restored_label != null:
		restored_label.visible = false
	if screen_fill != null:
		screen_fill.visible = false

	if EnemyRegistry != null:
		is_locked = (EnemyRegistry.remaining_enemies > 0)
		EnemyRegistry.all_enemies_cleared.connect(_on_all_enemies_cleared)
		EnemyRegistry.count_changed.connect(_on_count_changed)
	else:
		is_locked = false

	_update_beacon_visual()

func _on_count_changed(remaining: int, _total: int) -> void:
	is_locked = (remaining > 0)
	_update_beacon_visual()

func _update_beacon_visual() -> void:
	if beacon_dot != null:
		if is_locked:
			beacon_dot.color = Color(1.0, 0.15, 0.15, 1.0) # Red locked
		else:
			beacon_dot.color = Color(0.2, 1.0, 0.8, 1.0) # Cyan/white unlocked

func _process(_delta: float) -> void:
	if not _activated and beacon_dot != null:
		var blink_speed: int = 250 if is_locked else 500
		beacon_dot.visible = (int(Time.get_ticks_msec() / blink_speed) % 2) == 0

func _on_all_enemies_cleared() -> void:
	is_locked = false
	_update_beacon_visual()

	# Dramatic "SIGNAL RESTORED" moment
	ParticlesFactory.spawn_terminal_restore(get_parent(), global_position + Vector2(0.0, -16.0))
	if NoiseBus != null:
		var ev := NoiseEvent.make(global_position, 320.0, 2.5, NoiseEvent.NoiseType.PULSE, self)
		NoiseBus.emit_noise(ev)

	# Slow motion beat
	Engine.time_scale = 0.35
	# Tree-owned tween: if the level is freed mid slow-mo, time still returns to 1.0.
	var slow_tween := get_tree().create_tween()
	slow_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	slow_tween.tween_interval(0.15)
	slow_tween.tween_property(Engine, "time_scale", 1.0, 0.3).set_ease(Tween.EASE_OUT)

	var hud: Node = get_tree().get_first_node_in_group(&"hud")
	if hud != null and hud.has_method("show_tutorial_prompt"):
		hud.show_tutorial_prompt("SIGNAL RESTORED - TERMINAL UNLOCKED")

func _on_player_entered(p: Node2D) -> void:
	if _activated:
		return

	# Clear Gate check: must clear all hostiles
	if EnemyRegistry != null and EnemyRegistry.remaining_enemies > 0:
		var rem: int = EnemyRegistry.remaining_enemies
		var hud: Node = get_tree().get_first_node_in_group(&"hud")
		if hud != null and hud.has_method("show_tutorial_prompt"):
			hud.show_tutorial_prompt("SIGNAL LOCKED - %d HOSTILE%s REMAIN" % [rem, "S" if rem != 1 else ""])
		
		# Denied feedback: flash red and emit clink noise
		if beacon_dot != null:
			var tw := create_tween()
			tw.tween_property(beacon_dot, "scale", Vector2(1.8, 1.8), 0.1)
			tw.tween_property(beacon_dot, "scale", Vector2.ONE, 0.15)
		if NoiseBus != null:
			var ev := NoiseEvent.make(global_position, 96.0, 0.8, NoiseEvent.NoiseType.CLINK, self)
			NoiseBus.emit_noise(ev)
		return

	_activated = true

	var motor: Node = p.get_node_or_null("PlayerMotor")
	if motor != null and "input_enabled" in motor:
		motor.input_enabled = false
	if "velocity" in p:
		p.velocity = Vector2.ZERO

	if beacon_dot != null:
		beacon_dot.visible = false
	if screen_fill != null:
		screen_fill.visible = true
	if restored_label != null:
		restored_label.visible = true

	ParticlesFactory.spawn_terminal_restore(get_parent(), global_position + Vector2(0.0, -16.0))

	var tween := create_tween()
	if screen_fill != null:
		screen_fill.modulate = Color(1, 1, 1, 0)
		tween.tween_property(screen_fill, "modulate:a", 1.0, 0.4)
	if restored_label != null:
		restored_label.modulate = Color(1, 1, 1, 0)
		tween.parallel().tween_property(restored_label, "modulate:a", 1.0, 0.4)

	tween.tween_interval(0.4)
	tween.tween_callback(func() -> void:
		GameState.complete_level()
	)
