class_name LevelRoot
extends Node2D

@export_file("*.txt") var level_path: String = "res://levels/level_test.txt"

@onready var canvas_modulate: CanvasModulate = $CanvasModulate
@onready var background_root: Node2D = $BackgroundRoot
@onready var sonar_air: ColorRect = $SonarAir
@onready var sonar_system: SonarSystem = $SonarSystem
@onready var camera_rig: CameraRig = $CameraRig
@onready var interactables: Node2D = $Interactables
@onready var enemies: Node2D = $Enemies
@onready var sense_layer: CanvasLayer = $SenseLayer

var current_level_data: LevelData = null
var platform_graph: PlatformGraph = null

func _ready() -> void:
	if not level_path.is_empty():
		load_level(level_path)

func load_level(path: String) -> void:
	level_path = path
	var data: LevelData = LevelParser.parse_file(path)
	if data == null:
		push_error("LevelRoot: failed to parse " + path)
		return

	current_level_data = data

	if OS.is_debug_build():
		var val_rep: Dictionary = LevelValidator.validate(data)
		var errs: Array = val_rep.get("errors", [])
		if not errs.is_empty():
			push_error("LevelRoot: validation errors in %s: %s" % [path, str(errs)])

	var map_px := Rect2(0, 0, data.width * 32, data.height * 32)

	# 1. Background
	if background_root != null:
		BackgroundBuilder.build(background_root, map_px, data.seed)

	# 2. Solids, OneWays, Edges
	LevelBuilder.build(data, self)

	# 3. PlatformGraph
	platform_graph = PlatformGraph.new()
	platform_graph.build(data)

	# 4. Entity Spawner
	var spawned: Dictionary = EntitySpawner.spawn_entities(data, self, platform_graph)

	# 5. SonarAir sizing & setup
	if sonar_air != null and sonar_system != null:
		sonar_air.position = Vector2(-32, -32)
		sonar_air.size = Vector2(map_px.size.x + 64, map_px.size.y + 64)
		sonar_system.air_material = sonar_air.material as ShaderMaterial

	# 6. Camera Rig limits & target
	var player_inst: Node2D = spawned.get("player") as Node2D
	if player_inst != null:
		if sonar_system != null and sonar_system.has_method("connect_player"):
			sonar_system.call("connect_player", player_inst)
		if "map_bottom" in player_inst:
			player_inst.map_bottom = map_px.size.y
		if camera_rig != null:
			camera_rig.target = player_inst
			camera_rig.set_limits(Rect2i(0, 0, int(map_px.size.x), int(map_px.size.y)))
			var dust_scene: PackedScene = load("res://scenes/props/dust_particles.tscn")
			if dust_scene != null:
				camera_rig.add_child(dust_scene.instantiate())

	# 7. Initialize level state & Notify SceneRouter
	if GameState != null:
		GameState.decoy_count = data.decoys

	if SceneRouter != null and SceneRouter.has_signal("level_loaded"):
		SceneRouter.level_loaded.emit(self)
