extends Node

@onready var level_host: Node2D = $LevelHost
@onready var post_fx: CanvasLayer = $PostFx
@onready var hud: CanvasLayer = $HUD
@onready var menus: CanvasLayer = $Menus
@onready var debug_overlay: CanvasLayer = $DebugOverlay
@onready var boot: Node = $Boot

func _ready() -> void:
	DebugFlags.log(&"main", "Main scene initialized")
	SceneRouter.load_level(1)
