class_name ExitTerminal
extends Interactable

@onready var screen_fill: Polygon2D = get_node_or_null("Visual/ScreenFill") as Polygon2D
@onready var beacon_dot: Polygon2D = get_node_or_null("Visual/BeaconDot") as Polygon2D
@onready var restored_label: Label = get_node_or_null("Visual/RestoredLabel") as Label

var _activated: bool = false

func _ready() -> void:
	super._ready()
	if restored_label != null:
		restored_label.visible = false
	if screen_fill != null:
		screen_fill.visible = false

func _process(_delta: float) -> void:
	if not _activated and beacon_dot != null:
		beacon_dot.visible = (int(Time.get_ticks_msec() / 300) % 2) == 0

func _on_player_entered(p: Player) -> void:
	if _activated:
		return
	_activated = true

	if p.motor != null:
		p.motor.input_enabled = false
	p.velocity = Vector2.ZERO

	if beacon_dot != null:
		beacon_dot.visible = false
	if screen_fill != null:
		screen_fill.visible = true
	if restored_label != null:
		restored_label.visible = true

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
	tween.tween_interval(0.6)
	tween.tween_callback(func() -> void:
		SceneRouter.next_level()
	)
