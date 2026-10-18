class_name HUD
extends CanvasLayer

@onready var root: Control = $Root
@onready var safe_area: MarginContainer = $Root/SafeArea
@onready var top_left: Control = $Root/SafeArea/TopLeft
@onready var bottom_left: VBoxContainer = $Root/SafeArea/BottomLeft
@onready var battery_bar: Control = $Root/SafeArea/BottomLeft/BatteryBar
@onready var pip_row: Control = $Root/SafeArea/BottomLeft/Pips
@onready var primary_slot: Control = $Root/SafeArea/BottomLeft/AbilityRow/PrimarySlot
@onready var secondary_slot: Control = $Root/SafeArea/BottomLeft/AbilityRow/SecondarySlot
@onready var level_label: Control = $Root/SafeArea/BottomCentre
@onready var controls_hint: Label = get_node_or_null("Root/SafeArea/BottomCentre/ControlsHint") as Label
@onready var weapon_badge: Label = get_node_or_null("Root/SafeArea/BottomLeft/TacticalStatus/WeaponBadge") as Label
@onready var health_label: Label = get_node_or_null("Root/SafeArea/BottomLeft/TacticalStatus/HealthLabel") as Label

var _has_moved: bool = false
var _player_node: CharacterBody2D = null
var hostiles_label: Label = null
var compass_tick: Polygon2D = null
var segmented_hp_bar: Control = null
var current_hp: int = 3
var max_hp_val: int = 3
var hp_flash_intensity: float = 0.0

func _ready() -> void:
	layer = 20
	_setup_hostiles_ui()
	_setup_segmented_hp_bar()
	_update_safe_margins()
	get_viewport().size_changed.connect(_update_safe_margins)
	_find_and_bind_player()
	
	var router: Node = get_node_or_null("/root/SceneRouter") if is_inside_tree() else null
	if router != null and router.has_signal("level_loaded"):
		router.connect("level_loaded", Callable(self, "_on_level_loaded"))

	if EnemyRegistry != null:
		EnemyRegistry.count_changed.connect(_on_hostiles_count_changed)
		_on_hostiles_count_changed(EnemyRegistry.remaining_enemies, EnemyRegistry.total_enemies)

func _setup_hostiles_ui() -> void:
	if safe_area == null:
		return
	# Hostiles Counter Top-Center
	hostiles_label = Label.new()
	hostiles_label.name = "HostilesCounter"
	hostiles_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hostiles_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hostiles_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	hostiles_label.add_theme_font_size_override("font_size", 16)
	hostiles_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.9))
	hostiles_label.pivot_offset = Vector2(100.0, 10.0)
	safe_area.add_child(hostiles_label)

	# Compass Tick indicator
	compass_tick = Polygon2D.new()
	compass_tick.name = "CompassTick"
	compass_tick.color = Color(1.0, 0.2, 0.2, 0.85)
	compass_tick.polygon = PackedVector2Array([
		Vector2(0, -8), Vector2(8, 6), Vector2(0, 3), Vector2(-8, 6)
	])
	compass_tick.visible = false
	add_child(compass_tick)


func _setup_segmented_hp_bar() -> void:
	var tactical: Control = get_node_or_null("Root/SafeArea/BottomLeft/TacticalStatus") as Control
	if tactical == null:
		return
	segmented_hp_bar = Control.new()
	segmented_hp_bar.name = "SegmentedHPBar"
	segmented_hp_bar.custom_minimum_size = Vector2(60, 16)
	segmented_hp_bar.draw.connect(_on_draw_segmented_hp_bar)
	tactical.add_child(segmented_hp_bar)


func _on_draw_segmented_hp_bar() -> void:
	if segmented_hp_bar == null:
		return
	var seg_w: float = 16.0
	var seg_h: float = 10.0
	var spacing: float = 3.0
	var start_y: float = 4.0

	var fill_color := Color(0.95, 0.2, 0.25, 1.0)
	if hp_flash_intensity > 0.01:
		fill_color = fill_color.lerp(Color(1.0, 1.0, 1.0, 1.0), hp_flash_intensity)

	for i in range(max_hp_val):
		var x: float = float(i) * (seg_w + spacing)
		var rect := Rect2(x, start_y, seg_w, seg_h)
		if i < current_hp:
			segmented_hp_bar.draw_rect(rect, fill_color, true)
			segmented_hp_bar.draw_rect(rect, Color(1.0, 0.45, 0.5, 0.9), false, 1.0)
		else:
			segmented_hp_bar.draw_rect(rect, Color(0.12, 0.12, 0.16, 0.7), true)
			segmented_hp_bar.draw_rect(rect, Color(0.35, 0.35, 0.42, 0.6), false, 1.0)


func _on_hostiles_count_changed(remaining: int, total: int) -> void:
	if hostiles_label == null:
		return
	if total == 0:
		hostiles_label.text = ""
		return
	if remaining == 0:
		hostiles_label.text = "HOSTILES CLEARED"
		hostiles_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.8, 1.0))
	else:
		hostiles_label.text = "HOSTILES %d/%d" % [remaining, total]
		hostiles_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 0.9))

	var tw := create_tween()
	tw.tween_property(hostiles_label, "scale", Vector2(1.2, 1.2), 0.08)
	tw.tween_property(hostiles_label, "scale", Vector2.ONE, 0.12)

func _process(delta: float) -> void:
	if hp_flash_intensity > 0.0:
		hp_flash_intensity = maxf(0.0, hp_flash_intensity - delta * 4.0)
		if segmented_hp_bar != null:
			segmented_hp_bar.queue_redraw()

	_update_compass_tick()
	if controls_hint != null and controls_hint.visible and not _has_moved:
		if _player_node != null and (_player_node.velocity.length() > 10.0 or Input.get_axis("move_left", "move_right") != 0.0):
			_has_moved = true
			var tween := create_tween()
			tween.tween_property(controls_hint, "modulate:a", 0.0, 0.5)
			tween.tween_callback(func() -> void: controls_hint.visible = false)

	if GameState != null:
		if not GameState.decoy_count_changed.is_connected(_on_decoy_count_changed):
			GameState.decoy_count_changed.connect(_on_decoy_count_changed)
		_on_decoy_count_changed(GameState.decoy_count)

func _update_compass_tick() -> void:
	if compass_tick == null:
		return
	if EnemyRegistry == null or not EnemyRegistry.is_compass_active() or _player_node == null:
		compass_tick.visible = false
		return

	var nearest: Node2D = EnemyRegistry.get_nearest_living_enemy(_player_node.global_position)
	if nearest == null:
		compass_tick.visible = false
		return

	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam == null:
		compass_tick.visible = false
		return

	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var screen_center: Vector2 = vp_size * 0.5
	var enemy_scr: Vector2 = nearest.get_global_transform_with_canvas().origin

	var dir: Vector2 = (enemy_scr - screen_center).normalized()
	compass_tick.rotation = dir.angle() + PI * 0.5
	var edge_margin: float = 36.0
	var tick_x: float = clampf(enemy_scr.x, edge_margin, vp_size.x - edge_margin)
	var tick_y: float = clampf(enemy_scr.y, edge_margin, vp_size.y - edge_margin)
	compass_tick.position = Vector2(tick_x, tick_y)
	compass_tick.visible = true

func _on_decoy_count_changed(n: int) -> void:
	if pip_row != null:
		pip_row.set_pips(n)
	if primary_slot != null:
		primary_slot.set_active(n > 0)

func _update_safe_margins() -> void:
	if safe_area == null:
		return
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var margin: int = int(round(minf(vp_size.x, vp_size.y) * 0.04))
	margin = maxi(margin, 20)
	safe_area.add_theme_constant_override("margin_left", margin)
	safe_area.add_theme_constant_override("margin_top", margin)
	safe_area.add_theme_constant_override("margin_right", margin)
	safe_area.add_theme_constant_override("margin_bottom", margin)

func _on_level_loaded(level_root: Node) -> void:
	_find_and_bind_player(level_root)
	if level_label != null:
		level_label._recompute_progress()
	if controls_hint != null:
		var is_lvl1: bool = (GameState != null and GameState.level_index == 1)
		controls_hint.visible = is_lvl1
		controls_hint.modulate.a = 1.0 if is_lvl1 else 0.0
		_has_moved = false


func show_tutorial_prompt(text_val: String) -> void:
	if controls_hint != null:
		controls_hint.text = text_val
		controls_hint.visible = true
		controls_hint.modulate.a = 1.0
		var tween := create_tween()
		tween.tween_interval(3.5)
		tween.tween_property(controls_hint, "modulate:a", 0.0, 0.6)
		tween.tween_callback(func() -> void: controls_hint.visible = false)

func _find_and_bind_player(level_root: Node = null) -> void:
	var player: Node = null
	if level_root != null:
		player = level_root.find_child("Player", true, false)
	if player == null and is_inside_tree():
		player = get_tree().get_first_node_in_group(&"player")
	if player == null and is_inside_tree() and get_tree().root != null:
		player = get_tree().root.find_child("Player", true, false)
	if player is CharacterBody2D:
		_player_node = player as CharacterBody2D
	if player != null and battery_bar != null:
		var battery = player.get_node_or_null("Battery")
		var charger = player.get_node_or_null("PulseCharger")
		battery_bar.setup(battery, charger)

	if player != null:
		var health_comp = player.get_node_or_null("HealthComponent")
		if health_comp != null and health_comp.has_signal("health_changed") and not health_comp.health_changed.is_connected(_on_health_changed):
			health_comp.health_changed.connect(_on_health_changed)
			_on_health_changed(int(health_comp.get("current_health")), int(health_comp.get("max_health")))

		var swap_mgr = player.get_node_or_null("WeaponSwapManager")
		if swap_mgr != null and swap_mgr.has_signal("weapon_swapped") and not swap_mgr.weapon_swapped.is_connected(_on_weapon_swapped):
			swap_mgr.weapon_swapped.connect(_on_weapon_swapped)
			var w_name: StringName = swap_mgr.call("get_weapon_name", swap_mgr.get("current_weapon"))
			_on_weapon_swapped(swap_mgr.get("current_weapon"), w_name)


func _on_health_changed(cur: int, max_hp: int) -> void:
	if cur < current_hp:
		hp_flash_intensity = 1.0
	current_hp = cur
	max_hp_val = max_hp

	if segmented_hp_bar != null:
		segmented_hp_bar.custom_minimum_size.x = float(max_hp) * 19.0
		segmented_hp_bar.queue_redraw()

	if health_label != null:
		var blocks: String = ""
		for i in range(max_hp):
			blocks += "[■]" if i < cur else "[□]"
		health_label.text = "HP: " + blocks


func _on_weapon_swapped(_type: int, w_name: StringName) -> void:
	if weapon_badge != null:
		weapon_badge.text = "[Q] " + str(w_name).to_upper()
