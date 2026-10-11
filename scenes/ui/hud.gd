class_name HUD
extends CanvasLayer

@onready var root: Control = $Root
@onready var safe_area: MarginContainer = $Root/SafeArea
@onready var top_left: FragmentCounter = $Root/SafeArea/TopLeft
@onready var bottom_left: VBoxContainer = $Root/SafeArea/BottomLeft
@onready var battery_bar: BatteryBar = $Root/SafeArea/BottomLeft/BatteryBar
@onready var pip_row: PipRow = $Root/SafeArea/BottomLeft/Pips
@onready var primary_slot: AbilitySlot = $Root/SafeArea/BottomLeft/AbilityRow/PrimarySlot
@onready var secondary_slot: AbilitySlot = $Root/SafeArea/BottomLeft/AbilityRow/SecondarySlot
@onready var level_label: LevelLabel = $Root/SafeArea/BottomCentre
@onready var controls_hint: Label = get_node_or_null("Root/SafeArea/BottomCentre/ControlsHint") as Label

var _has_moved: bool = false
var _player_node: CharacterBody2D = null

func _ready() -> void:
	layer = 20
	_update_safe_margins()
	get_viewport().size_changed.connect(_update_safe_margins)
	_find_and_bind_player()
	
	var router: Node = get_node_or_null("/root/SceneRouter") if is_inside_tree() else null
	if router != null and router.has_signal("level_loaded"):
		router.connect("level_loaded", Callable(self, "_on_level_loaded"))

func _process(_delta: float) -> void:
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
