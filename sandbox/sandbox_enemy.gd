class_name SandboxEnemy
extends Node2D

const PULSE_WHISPER: PulseProfile = preload("res://resources/pulses/pulse_whisper.tres")
const PULSE_NORMAL: PulseProfile = preload("res://resources/pulses/pulse_normal.tres")
const PULSE_SCREAM: PulseProfile = preload("res://resources/pulses/pulse_scream.tres")

@onready var camera_rig: CameraRig = $CameraRig
@onready var sonar_system: SonarSystem = $SonarSystem
@onready var canvas_modulate: CanvasModulate = $CanvasModulate
@onready var background_root: Node2D = $BackgroundRoot
@onready var solids: Node2D = $Solids
@onready var one_ways: Node2D = $OneWays
@onready var sonar_air: ColorRect = $SonarAir
@onready var player: Player = $Player
@onready var listener: EnemyBase = $Listener

func _ready() -> void:
	if camera_rig != null:
		camera_rig.set_limits(Rect2i(0, 0, 1280, 720))

	if background_root != null:
		BackgroundBuilder.build(background_root, Rect2(0, 0, 1280, 720), 42)

	if sonar_system != null and sonar_air != null:
		sonar_system.air_material = sonar_air.material as ShaderMaterial

	_generate_edges()

func _generate_edges() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1337

	if solids != null:
		for child in solids.get_children():
			if child is Polygon2D:
				var poly: Polygon2D = child as Polygon2D
				var pts: PackedVector2Array = poly.polygon
				var n: int = pts.size()
				for i in range(n):
					var p0: Vector2 = poly.global_position + pts[i]
					var p1: Vector2 = poly.global_position + pts[(i + 1) % n]
					var is_top: bool = absf(p0.y - p1.y) < 1.0 and (p1.x > p0.x)
					var edge_node: Node2D = EdgeLineFactory.make_edge(p0, p1, is_top, rng)
					add_child(edge_node)

	if one_ways != null:
		for child in one_ways.get_children():
			if child is CollisionShape2D:
				var col: CollisionShape2D = child as CollisionShape2D
				if col.shape is RectangleShape2D:
					var rect_shape: RectangleShape2D = col.shape as RectangleShape2D
					var half_sz: Vector2 = rect_shape.size * 0.5
					var p_left: Vector2 = col.global_position + Vector2(-half_sz.x, -half_sz.y)
					var p_right: Vector2 = col.global_position + Vector2(half_sz.x, -half_sz.y)
					var edge_node: Node2D = EdgeLineFactory.make_edge(p_left, p_right, true, rng)
					add_child(edge_node)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.is_pressed() and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			if listener != null and listener.mover != null:
				var speed: float = listener.profile.walk_speed if listener.profile != null else 50.0
				listener.mover.move_to(get_global_mouse_position(), speed)
		return

	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.is_pressed() or key_event.is_echo():
		return

	match key_event.keycode:
		KEY_1:
			_spawn_pulse(PULSE_WHISPER)
		KEY_2:
			_spawn_pulse(PULSE_NORMAL)
		KEY_3:
			_spawn_pulse(PULSE_SCREAM)
		KEY_C:
			if canvas_modulate != null:
				canvas_modulate.visible = not canvas_modulate.visible
		KEY_L:
			_spawn_random_bubbles()
		KEY_Q:
			_toggle_sonar_quality()
		KEY_A:
			if listener != null and listener.awareness != null:
				var cur: float = listener.awareness.value
				listener.awareness.set_value(0.0 if cur > 0.5 else 1.0)

func _spawn_pulse(profile: PulseProfile) -> void:
	if sonar_system != null and player != null and profile != null:
		sonar_system.spawn(profile, player.global_position)

func _spawn_random_bubbles() -> void:
	if sonar_system == null:
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var profiles: Array[PulseProfile] = [PULSE_WHISPER, PULSE_NORMAL, PULSE_SCREAM]
	for i in range(6):
		var pos: Vector2 = Vector2(rng.randf_range(120.0, 1160.0), rng.randf_range(120.0, 600.0))
		var prof: PulseProfile = profiles[rng.randi() % profiles.size()]
		sonar_system.spawn(prof, pos)

func _toggle_sonar_quality() -> void:
	if GameConfig == null or GameConfig.data == null:
		return
	if GameConfig.data.sonar_quality == GameConfigData.Quality.HIGH:
		GameConfig.data.sonar_quality = GameConfigData.Quality.LOW
	else:
		GameConfig.data.sonar_quality = GameConfigData.Quality.HIGH

	if sonar_system != null:
		for b in sonar_system.pool:
			if b != null and b.light != null:
				b.light.shadow_enabled = (GameConfig.data.sonar_quality != GameConfigData.Quality.LOW)
