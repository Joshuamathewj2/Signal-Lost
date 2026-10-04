class_name HUD
extends CanvasLayer

@onready var battery_bar: BatteryBar = $Root/SafeArea/BottomLeft/BatteryBar

func _ready() -> void:
	layer = 20
	_find_and_bind_player()
	if SceneRouter != null and SceneRouter.has_signal("level_loaded"):
		SceneRouter.level_loaded.connect(_on_level_loaded)

func _on_level_loaded(_level_root: Node) -> void:
	_find_and_bind_player()

func _find_and_bind_player() -> void:
	var player: Node = get_tree().get_first_node_in_group(&"player")
	if player != null and battery_bar != null:
		var battery: Battery = player.get_node_or_null("Battery") as Battery
		var charger: PulseCharger = player.get_node_or_null("PulseCharger") as PulseCharger
		battery_bar.setup(battery, charger)
