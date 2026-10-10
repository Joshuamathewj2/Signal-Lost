extends Node

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/ui/hud.tscn")

@onready var level_host: Node2D = $LevelHost
@onready var post_fx: CanvasLayer = $PostFx
@onready var hud: CanvasLayer = $HUD
@onready var menus: CanvasLayer = $Menus
@onready var debug_overlay: CanvasLayer = $DebugOverlay
@onready var boot: Node = $Boot

func _ready() -> void:
	DebugFlags.log(&"main", "Main scene initialized")
	_ensure_hud()
	show_main_menu()

func _ensure_hud() -> void:
	var existing_hud: Node = get_tree().get_first_node_in_group(&"hud")
	if existing_hud == null and hud != null and hud.get_child_count() == 0:
		var hud_inst: CanvasLayer = HUD_SCENE.instantiate() as CanvasLayer
		add_child(hud_inst)
		hud.queue_free()
		hud = hud_inst

func show_main_menu() -> void:
	if menus != null:
		for child in menus.get_children():
			child.queue_free()
		var menu_inst: Node = MAIN_MENU_SCENE.instantiate()
		menus.add_child(menu_inst)
