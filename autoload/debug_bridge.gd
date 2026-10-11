extends Node

var recent_noise_events: Array[Dictionary] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if NoiseBus != null:
		NoiseBus.noise_emitted.connect(_on_noise_emitted)

	if OS.has_feature("web"):
		_init_web_bridge()

func _on_noise_emitted(event: NoiseEvent) -> void:
	if event == null:
		return
	recent_noise_events.append({
		"pos": [event.position.x, event.position.y],
		"radius": event.radius,
		"loudness": event.loudness,
		"type": int(event.source_type),
		"time": float(Time.get_ticks_msec()) / 1000.0
	})
	while recent_noise_events.size() > 20:
		recent_noise_events.pop_front()

func _init_web_bridge() -> void:
	JavaScriptBridge.eval("""
		window.__SL = window.__SL || { ready: true };
		window.__SL_cmd_queue = window.__SL_cmd_queue || [];
		window.__SL_cmd = function(name, args) {
			window.__SL_cmd_queue = window.__SL_cmd_queue || [];
			window.__SL_cmd_queue.push({ name: name, args: args || {} });
			return true;
		};
	""")

func _handle_command(cmd_name: String, cmd_args: Dictionary) -> void:
	print("[DebugBridge] Handling command: ", cmd_name, " with args: ", cmd_args)
	match cmd_name:
		"load_level":
			var idx: int = int(cmd_args.get("level", 1))
			if SceneRouter != null:
				SceneRouter.is_transitioning = false
				SceneRouter.load_level(idx)
		"restart":
			if SceneRouter != null:
				SceneRouter.restart_level()
		"teleport_player":
			var p = get_tree().get_first_node_in_group(&"player")
			if p == null and get_tree().root != null:
				p = get_tree().root.find_child("Player", true, false)
			if p != null and p is Node2D:
				(p as Node2D).global_position = Vector2(float(cmd_args.get("x", 0)), float(cmd_args.get("y", 0)))
		"spawn_pulse":
			var tier: String = str(cmd_args.get("tier", "normal"))
			var p = get_tree().get_first_node_in_group(&"player")
			if p == null and get_tree().root != null:
				p = get_tree().root.find_child("Player", true, false)
			if p != null:
				var charger = p.get_node_or_null("PulseCharger")
				if charger != null:
					var prof = GameConfig.pulses.get(StringName(tier))
					if prof != null:
						charger.pulse_released.emit(prof, (p as Node2D).global_position)
		"set_god_mode":
			var p = get_tree().get_first_node_in_group(&"player")
			if p == null and get_tree().root != null:
				p = get_tree().root.find_child("Player", true, false)
			if p != null:
				p.set_meta("god_mode", bool(cmd_args.get("enabled", true)))

func _process(delta: float) -> void:
	if not OS.has_feature("web"):
		return

	# 1. Process commands from queue
	var raw_cmds = JavaScriptBridge.eval("""
		(function() {
			window.__SL_cmd_queue = window.__SL_cmd_queue || [];
			if (window.__SL_cmd_queue.length === 0) return '';
			var q = window.__SL_cmd_queue;
			window.__SL_cmd_queue = [];
			return JSON.stringify(q);
		})()
	""")
	if raw_cmds is String and not (raw_cmds as String).is_empty():
		var parsed = JSON.parse_string(raw_cmds as String)
		if parsed is Array:
			for item in parsed:
				if item is Dictionary:
					_handle_command(str(item.get("name", "")), item.get("args", {}))

	# 2. Clean up noise events older than 3 seconds
	var now: float = float(Time.get_ticks_msec()) / 1000.0
	var i: int = recent_noise_events.size() - 1
	while i >= 0:
		if now - float(recent_noise_events[i].get("time", now)) > 3.0:
			recent_noise_events.remove_at(i)
		i -= 1

	# 3. Push snapshot to window.__SL
	var snapshot: Dictionary = get_snapshot()
	var json_str: String = JSON.stringify(snapshot)
	JavaScriptBridge.eval("window.__SL = " + json_str + ";")

func get_snapshot() -> Dictionary:
	var tree: SceneTree = get_tree()
	var snap: Dictionary = {
		"ready": true,
		"fps": Engine.get_frames_per_second(),
		"level": GameState.level_index if GameState != null else 1,
		"battery": 100.0,
		"player": null,
		"pulses": [],
		"noise_events": recent_noise_events.duplicate(),
		"enemies": [],
		"tree": _dump_tree(tree.root, 0) if tree != null and tree.root != null else []
	}

	if tree == null:
		return snap

	var p: Node = tree.get_first_node_in_group(&"player")
	if p == null:
		p = tree.get_first_node_in_group("player")
	if p == null and tree.root != null:
		p = tree.root.find_child("Player", true, false)
	if p != null and p is Node2D:
		var p2d: Node2D = p as Node2D
		var motor: Node = p.get_node_or_null("PlayerMotor")
		var bat: Node = p.get_node_or_null("Battery")
		if bat != null and "current_charge" in bat:
			snap["battery"] = bat.get("current_charge")

		var on_floor: bool = false
		if p.has_method("is_on_floor"):
			on_floor = bool(p.call("is_on_floor"))

		var vel: Vector2 = Vector2.ZERO
		if "velocity" in p:
			vel = p.get("velocity")

		var alive: bool = true
		if "is_alive" in p:
			alive = bool(p.get("is_alive"))

		var facing: int = 1
		if motor != null and "facing" in motor:
			facing = int(motor.get("facing"))

		var sneaking: bool = false
		if motor != null and "is_sneaking" in motor:
			sneaking = bool(motor.get("is_sneaking"))

		snap["player"] = {
			"pos": [p2d.global_position.x, p2d.global_position.y],
			"vel": [vel.x, vel.y],
			"on_floor": on_floor,
			"is_alive": alive,
			"facing": facing,
			"is_sneaking": sneaking
		}

	# Pulses
	if PulseRegistry != null:
		var pulses_arr: Array = []
		for b in PulseRegistry.bubbles:
			if b != null and b.active:
				pulses_arr.append({
					"origin": [b.origin.x, b.origin.y],
					"radius": b.radius,
					"age": b.age,
					"brightness": b.brightness
				})
		snap["pulses"] = pulses_arr

	# Enemies
	var enemies_nodes: Array[Node] = tree.get_nodes_in_group(&"enemies")
	var en_arr: Array = []
	for node in enemies_nodes:
		if node is Node2D:
			var n2d: Node2D = node as Node2D
			var aw: float = 0.0
			if "awareness" in node:
				aw = float(node.get("awareness"))
			var st: String = ""
			if "current_state_name" in node:
				st = str(node.get("current_state_name"))
			en_arr.append({
				"name": n2d.name,
				"pos": [n2d.global_position.x, n2d.global_position.y],
				"awareness": aw,
				"state": st
			})
	snap["enemies"] = en_arr

	return snap

func _dump_tree(node: Node, depth: int) -> Array:
	if depth > 3 or node == null:
		return []
	var res: Array = [node.name]
	for child in node.get_children():
		res.append_array(_dump_tree(child, depth + 1))
	return res
