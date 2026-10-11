extends Node

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/ui/hud.tscn")
const PAUSE_MENU_SCENE: PackedScene = preload("res://scenes/ui/pause_menu.tscn")
const LEVEL_COMPLETE_SCENE: PackedScene = preload("res://scenes/ui/level_complete.tscn")

@onready var level_host: Node2D = $LevelHost
@onready var post_fx: CanvasLayer = $PostFx
@onready var hud: CanvasLayer = $HUD
@onready var menus: CanvasLayer = $Menus
@onready var debug_overlay: CanvasLayer = $DebugOverlay
@onready var boot: Node = $Boot

var pause_menu: Node = null

func _ready() -> void:
	DebugFlags.log(&"main", "Main scene initialized")
	_ensure_hud()
	_ensure_pause_menu()
	if GameState != null and GameState.has_signal("level_completed"):
		GameState.level_completed.connect(_on_level_completed)
	show_main_menu()

func _on_level_completed(stats: Dictionary) -> void:
	var lvl_idx: int = int(stats.get("level_index", 1))
	var save_res: Dictionary = {}
	if SaveData != null and SaveData.has_method("save_level_result"):
		save_res = SaveData.save_level_result(lvl_idx, stats)

	if menus != null:
		var complete_inst: Node = LEVEL_COMPLETE_SCENE.instantiate()
		menus.add_child(complete_inst)
		if complete_inst.has_method("setup"):
			complete_inst.call("setup", stats, save_res)

func _ensure_hud() -> void:
	var existing_hud: Node = get_tree().get_first_node_in_group(&"hud")
	if existing_hud == null and hud != null and hud.get_child_count() == 0:
		var hud_inst: CanvasLayer = HUD_SCENE.instantiate() as CanvasLayer
		hud_inst.add_to_group(&"hud")
		add_child(hud_inst)
		hud.queue_free()
		hud = hud_inst

func _ensure_pause_menu() -> void:
	if menus != null and (pause_menu == null or not is_instance_valid(pause_menu)):
		pause_menu = PAUSE_MENU_SCENE.instantiate()
		pause_menu.name = "PauseMenu"
		menus.add_child(pause_menu)

func show_main_menu() -> void:
	if menus != null:
		for child in menus.get_children():
			if child != pause_menu:
				child.queue_free()
		var menu_inst: Node = MAIN_MENU_SCENE.instantiate()
		menu_inst.add_to_group(&"main_menu")
		menus.add_child(menu_inst)
