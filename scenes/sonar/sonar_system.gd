class_name SonarSystem
extends Node2D

signal bubble_spawned(bubble: PulseBubble)

@export var air_material: ShaderMaterial

var bubble_packed: PackedScene = preload("res://scenes/sonar/pulse_bubble.tscn")
var pool: Array[PulseBubble] = []
var hit_nodes_per_bubble: Dictionary = {}

func _ready() -> void:
	var max_b: int = GameConfig.data.max_bubbles if (GameConfig != null and GameConfig.data != null) else 6
	for i in range(max_b):
		var b: PulseBubble = bubble_packed.instantiate() as PulseBubble
		add_child(b)
		pool.append(b)
		hit_nodes_per_bubble[b] = {}

	_connect_player()
	if SceneRouter != null and SceneRouter.has_signal("level_loaded"):
		SceneRouter.level_loaded.connect(_on_level_loaded)

	if PulseRegistry != null and PulseRegistry.has_method("set_space_provider"):
		PulseRegistry.call("set_space_provider", self)

func _on_level_loaded(_level_root: Node) -> void:
	_connect_player()

func _connect_player() -> void:
	var p: Node = get_tree().get_first_node_in_group(&"player")
	if p != null:
		var charger: PulseCharger = p.get_node_or_null("PulseCharger") as PulseCharger
		if charger != null and not charger.pulse_released.is_connected(spawn):
			charger.pulse_released.connect(spawn)

func spawn(profile: PulseProfile, origin: Vector2) -> PulseBubble:
	var chosen: PulseBubble = null

	# 1. Look for inactive bubble
	for b in pool:
		if not b.active:
			chosen = b
			break

	# 2. If all active, recycle oldest (highest age)
	if chosen == null:
		var oldest_age: float = -1.0
		for b in pool:
			if b.age > oldest_age:
				oldest_age = b.age
				chosen = b

	if chosen != null:
		hit_nodes_per_bubble[chosen] = {}
		chosen.start(profile, origin)
		bubble_spawned.emit(chosen)

	return chosen

func _process(_delta: float) -> void:
	var active_bubbles: Array[PulseBubble] = []
	var reactive_nodes: Array[Node] = get_tree().get_nodes_in_group(&"wave_reactive")

	for b in pool:
		if b.active:
			active_bubbles.append(b)
			# Check wavefront trigger if still expanding
			if b.profile != null and b.age <= b.profile.expand_time():
				var hit_map: Dictionary = hit_nodes_per_bubble.get(b, {})
				for node in reactive_nodes:
					if node is Node2D:
						var n2d: Node2D = node as Node2D
						var nid: int = n2d.get_instance_id()
						if not hit_map.has(nid):
							var d: float = b.origin.distance_to(n2d.global_position)
							if d <= b.radius:
								hit_map[nid] = true
								if n2d.has_method("on_wavefront"):
									n2d.call("on_wavefront", b.profile, b.origin)
				hit_nodes_per_bubble[b] = hit_map

	if PulseRegistry != null:
		PulseRegistry.set_bubbles(active_bubbles)

	# Update air material shader parameters
	if air_material != null:
		var p_data: PackedVector4Array = PackedVector4Array()
		var p_style: PackedVector4Array = PackedVector4Array()

		for i in range(6):
			if i < active_bubbles.size():
				var b: PulseBubble = active_bubbles[i]
				p_data.append(Vector4(b.origin.x, b.origin.y, b.radius, b.ring_alpha))
				var p_thick: float = b.profile.ring_thickness if b.profile != null else 2.0
				var p_gap: float = b.profile.trail_gap if b.profile != null else 14.0
				var p_count: float = float(b.profile.trail_count) if b.profile != null else 2.0
				p_style.append(Vector4(p_thick, p_gap, p_count, b.brightness))
			else:
				p_data.append(Vector4(0.0, 0.0, 0.0, 0.0))
				p_style.append(Vector4(0.0, 0.0, 0.0, 0.0))

		air_material.set_shader_parameter(&"pulse_count", active_bubbles.size())
		air_material.set_shader_parameter(&"pulse_data", p_data)
		air_material.set_shader_parameter(&"pulse_style", p_style)
