class_name AwarenessBar
extends Node2D

var enemy: EnemyBase = null
var current_val: float = 0.0
var is_revealed: bool = false
var fade_tween: Tween = null

func _ready() -> void:
	modulate.a = 0.0

func setup(p_enemy: EnemyBase) -> void:
	enemy = p_enemy
	if enemy != null and enemy.awareness != null:
		enemy.awareness.awareness_changed.connect(_on_awareness_changed)
		current_val = enemy.awareness.value

func _on_awareness_changed(new_val: float, _old_val: float) -> void:
	current_val = new_val
	queue_redraw()

func _process(_delta: float) -> void:
	if enemy == null or not is_instance_valid(enemy):
		queue_free()
		return

	# 14 px above enemy head (top of 24px capsule is at -12, so -26)
	global_position = enemy.global_position + Vector2(0.0, -26.0)

	var reveal: float = 0.0
	if PulseRegistry != null:
		reveal = PulseRegistry.reveal_at(enemy.global_position)

	var should_reveal: bool = reveal > 0.25 and current_val > 0.01
	if should_reveal != is_revealed:
		is_revealed = should_reveal
		if fade_tween != null and fade_tween.is_valid():
			fade_tween.kill()
		fade_tween = create_tween()
		var target_a: float = 1.0 if is_revealed else 0.0
		fade_tween.tween_property(self, "modulate:a", target_a, 0.15)

func _draw() -> void:
	if modulate.a <= 0.01:
		return

	# 24x3 px track #5A0000
	var track_rect := Rect2(-12.0, -1.5, 24.0, 3.0)
	draw_rect(track_rect, Color("#5A0000"), true)

	# Red fill width = 24 * awareness
	var fill_w: float = 24.0 * clampf(current_val, 0.0, 1.0)
	if fill_w > 0.0:
		var fill_rect := Rect2(-12.0, -1.5, fill_w, 3.0)
		draw_rect(fill_rect, Palette.color(&"danger"), true)
