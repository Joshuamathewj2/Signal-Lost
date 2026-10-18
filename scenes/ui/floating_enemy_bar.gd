class_name FloatingEnemyBar
extends Node2D

## FloatingEnemyBar
## Small floating HP and Poise bar displayed above enemies.
## Hidden at full HP; reveals on first damage; tracks poise damage and death.

@export var bar_width: float = 28.0
@export var bar_height: float = 4.0
@export var poise_height: float = 1.5

var enemy: EnemyBase = null
var health_comp: HealthComponent = null
var poise_comp: PoiseComponent = null

var cur_hp: int = 1
var max_hp: int = 1
var cur_poise: float = 1.0
var max_poise: float = 1.0
var has_taken_damage: bool = false


func _ready() -> void:
	visible = false
	z_index = 10


func setup(target_enemy: EnemyBase) -> void:
	enemy = target_enemy
	if enemy == null:
		return

	health_comp = enemy.get_node_or_null("HealthComponent") as HealthComponent
	poise_comp = enemy.get_node_or_null("PoiseComponent") as PoiseComponent

	if health_comp != null:
		cur_hp = health_comp.current_health
		max_hp = health_comp.max_health
		health_comp.health_changed.connect(_on_health_changed)

	if poise_comp != null:
		cur_poise = poise_comp.current_poise
		max_poise = poise_comp.max_poise
		poise_comp.poise_changed.connect(_on_poise_changed)


func _on_health_changed(current: int, maximum: int) -> void:
	cur_hp = current
	max_hp = maximum
	if cur_hp < max_hp and not has_taken_damage:
		has_taken_damage = true
		visible = true

	if cur_hp <= 0:
		var t := create_tween()
		t.tween_property(self, "modulate:a", 0.0, 0.4)
		t.tween_callback(queue_free)
	queue_redraw()


func _on_poise_changed(current: float, maximum: float) -> void:
	cur_poise = current
	max_poise = maximum
	if cur_poise < max_poise and not has_taken_damage:
		has_taken_damage = true
		visible = true
	queue_redraw()


func _draw() -> void:
	if not visible or max_hp <= 0:
		return

	var half_w: float = bar_width * 0.5
	var bg_rect := Rect2(-half_w - 1.0, -bar_height, bar_width + 2.0, bar_height + poise_height + 2.0)
	# Draw dark background
	draw_rect(bg_rect, Color(0.05, 0.05, 0.07, 0.85), true)
	draw_rect(bg_rect, Color(0.3, 0.3, 0.35, 0.8), false, 1.0)

	# Draw HP segments
	var hp_ratio: float = clampf(float(cur_hp) / float(max_hp), 0.0, 1.0)
	var fill_w: float = bar_width * hp_ratio
	if fill_w > 0.0:
		var hp_rect := Rect2(-half_w, -bar_height + 1.0, fill_w, bar_height - 1.0)
		draw_rect(hp_rect, Color(0.88, 0.08, 0.08, 0.95), true)

	# Segment dividers for multi-HP enemies
	if max_hp > 1:
		for i in range(1, max_hp):
			var seg_x: float = -half_w + (bar_width / float(max_hp)) * float(i)
			draw_line(Vector2(seg_x, -bar_height + 1.0), Vector2(seg_x, 0.0), Color(0.1, 0.1, 0.1, 0.9), 1.0)

	# Draw Poise bar (cyan line underneath)
	if max_poise > 0.0:
		var poise_ratio: float = clampf(cur_poise / max_poise, 0.0, 1.0)
		var poise_w: float = bar_width * poise_ratio
		if poise_w > 0.0:
			var p_rect := Rect2(-half_w, 1.0, poise_w, poise_height)
			draw_rect(p_rect, Color(0.0, 0.85, 1.0, 0.9), true)
