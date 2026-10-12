class_name BossHealthBar
extends Control

## BossHealthBar
## Sector 9 Climax Boss Vitality & Poise Meter:
## 480x16 px deep red health bar with phase markers at 66% and 33%.
## 480x4 px razor white poise gauge beneath with stagger alert.

@onready var title_label: Label = get_node_or_null("TitleLabel") as Label
@onready var hp_bar: Control = get_node_or_null("HpBar") as Control
@onready var hp_fill: ColorRect = get_node_or_null("HpBar/HpFill") as ColorRect
@onready var poise_bar: Control = get_node_or_null("PoiseBar") as Control
@onready var poise_fill: ColorRect = get_node_or_null("PoiseBar/PoiseFill") as ColorRect
@onready var status_label: Label = get_node_or_null("StatusLabel") as Label

var boss_target: Node2D = null
var max_hp: int = 18
var cur_hp: int = 18
var max_poise: float = 200.0
var cur_poise: float = 200.0


func _ready() -> void:
	visible = false
	_find_boss()
	var router = get_node_or_null("/root/SceneRouter") if is_inside_tree() else null
	if router != null and router.has_signal("level_loaded"):
		router.connect("level_loaded", Callable(self, "_on_level_loaded"))


func _on_level_loaded(_lvl_root: Node) -> void:
	_find_boss()


func _find_boss() -> void:
	if not is_inside_tree():
		return
	var b := get_tree().get_first_node_in_group(&"boss") as Node2D
	if b != null:
		bind_boss(b)
	else:
		visible = false


func bind_boss(boss: Node2D) -> void:
	boss_target = boss
	visible = true

	var h_comp = boss.get_node_or_null("HealthComponent")
	if h_comp != null:
		max_hp = int(h_comp.get("max_health"))
		cur_hp = int(h_comp.get("current_health"))
		if not h_comp.health_changed.is_connected(_on_boss_health_changed):
			h_comp.health_changed.connect(_on_boss_health_changed)

	var p_comp = boss.get_node_or_null("PoiseComponent")
	if p_comp != null:
		max_poise = float(p_comp.get("max_poise"))
		cur_poise = float(p_comp.get("current_poise"))
		if not p_comp.poise_changed.is_connected(_on_boss_poise_changed):
			p_comp.poise_changed.connect(_on_boss_poise_changed)
		if not p_comp.staggered.is_connected(_on_boss_staggered):
			p_comp.staggered.connect(_on_boss_staggered)
		if not p_comp.recovered.is_connected(_on_boss_poise_recovered):
			p_comp.recovered.connect(_on_boss_poise_recovered)

	if boss.has_signal("boss_defeated") and not boss.boss_defeated.is_connected(_on_boss_defeated):
		boss.boss_defeated.connect(_on_boss_defeated)

	_update_display()


func _on_boss_health_changed(hp: int, max_val: int) -> void:
	cur_hp = hp
	max_hp = max_val
	_update_display()


func _on_boss_poise_changed(poise: float, max_val: float) -> void:
	cur_poise = poise
	max_poise = max_val
	_update_display()


func _on_boss_staggered(_dur: float = 0.0) -> void:
	_on_boss_poise_broken()


func _on_boss_poise_broken() -> void:
	if status_label != null:
		status_label.text = "[STAGGERED — STRIKE NOW]"
		status_label.visible = true
	if poise_fill != null:
		poise_fill.color = Color(2.5, 2.5, 2.5, 1.0)


func _on_boss_poise_recovered() -> void:
	if status_label != null:
		status_label.visible = false
	if poise_fill != null:
		poise_fill.color = Color(1.0, 1.0, 1.0, 1.0)


func _on_boss_defeated() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 1.5)
	t.tween_callback(func() -> void: visible = false)


func _update_display() -> void:
	if hp_fill != null and max_hp > 0:
		var pct_hp: float = clampf(float(cur_hp) / float(max_hp), 0.0, 1.0)
		hp_fill.size.x = 480.0 * pct_hp

	if poise_fill != null and max_poise > 0.0:
		var pct_p: float = clampf(cur_poise / max_poise, 0.0, 1.0)
		poise_fill.size.x = 480.0 * pct_p
