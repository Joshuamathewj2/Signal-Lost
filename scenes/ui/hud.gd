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

func _ready() -> void:
	layer = 20
	_update_safe_margins()
	get_viewport().size_changed.connect(_update_safe_margins)
	_find_and_bind_player()
	
	var router: Node = get_node_or_null("/root/SceneRouter") if is_inside_tree() else null
	if router != null and router.has_signal("level_loaded"):
		router.connect("level_loaded", Callable(self, "_on_level_loaded"))

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

func _on_level_loaded(_level_root: Node) -> void:
	_find_and_bind_player()
	if level_label != null:
		level_label._recompute_progress()

func _find_and_bind_player() -> void:
	var player: Node = get_tree().get_first_node_in_group(&"player")
	if player != null and battery_bar != null:
		var battery: Battery = player.get_node_or_null("Battery") as Battery
		var charger: PulseCharger = player.get_node_or_null("PulseCharger") as PulseCharger
		battery_bar.setup(battery, charger)
