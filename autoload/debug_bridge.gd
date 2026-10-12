extends Node

var recent_noise_events: Array[Dictionary] = []
var is_level_complete: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if NoiseBus != null:
		NoiseBus.noise_emitted.connect(_on_noise_emitted)
	if GameState != null and GameState.has_signal("level_completed"):
		GameState.level_completed.connect(func(_stats: Dictionary) -> void: is_level_complete = true)
	if SceneRouter != null and SceneRouter.has_signal("level_loaded"):
		SceneRouter.level_loaded.connect(func(_root: Node) -> void: is_level_complete = false)

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
				SceneRouter.current_level_index = idx
				GameState.level_index = idx
				var path := "res://levels/level_%02d.txt" % idx
				SceneRouter._spawn_level_instant(path)
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
						var origin: Vector2 = (p as Node2D).global_position
						charger.pulse_released.emit(prof, origin)
						var noise_r: float = prof.noise_radius() * float(charger.get("noise_scale") if "noise_scale" in charger else 1.0)
						var ev: NoiseEvent = NoiseEvent.make(origin, noise_r, prof.loudness, NoiseEvent.NoiseType.PULSE, p)
						NoiseBus.emit_noise(ev)
		"set_god_mode":
			var p = get_tree().get_first_node_in_group(&"player")
			if p == null and get_tree().root != null:
				p = get_tree().root.find_child("Player", true, false)
			if p != null:
				p.set_meta("god_mode", bool(cmd_args.get("enabled", true)))
		"pause_game":
			var pause_node = get_tree().root.get_node_or_null("Main/Menus/PauseMenu")
			if pause_node != null and pause_node.has_method("pause"):
				pause_node.call("pause")
		"resume_game":
			var pause_node = get_tree().root.get_node_or_null("Main/Menus/PauseMenu")
			if pause_node != null and pause_node.has_method("resume"):
				pause_node.call("resume")
		"show_level_complete":
			var menus_node = get_tree().root.get_node_or_null("Main/Menus")
			if menus_node != null:
				var complete_scene: PackedScene = preload("res://scenes/ui/level_complete.tscn")
				var cmp = complete_scene.instantiate()
				menus_node.add_child(cmp)
				if cmp.has_method("setup"):
					cmp.call("setup", {
						"level_index": int(cmd_args.get("level", 1)),
						"time": float(cmd_args.get("time", 24.5)),
						"pulses": {"whisper": 2, "normal": 4, "scream": 1},
						"loudest": 2,
						"detections": 0,
						"fragments": [Vector2i(1, 1)],
						"medal": &"ghost"
					}, {})
		"show_settings":
			var menus_node = get_tree().root.get_node_or_null("Main/Menus")
			if menus_node != null:
				var settings_scene: PackedScene = preload("res://scenes/ui/settings_menu.tscn")
				var s = settings_scene.instantiate()
				menus_node.add_child(s)
		"player_attack":
			var p = get_tree().get_first_node_in_group(&"player")
			if p != null:
				var cc = p.get_node_or_null("CombatController")
				if cc != null and cc.has_method("handle_attack_input"):
					cc.handle_attack_input()
		"player_dash":
			var p = get_tree().get_first_node_in_group(&"player")
			if p != null:
				var cc = p.get_node_or_null("CombatController")
				if cc != null and cc.has_method("handle_dash_input"):
					cc.handle_dash_input()
		"player_parry":
			var p = get_tree().get_first_node_in_group(&"player")
			if p != null:
				var cc = p.get_node_or_null("CombatController")
				if cc != null and cc.has_method("start_parry"):
					cc.start_parry()
		"damage_player":
			var p = get_tree().get_first_node_in_group(&"player")
			if p != null:
				var hc = p.get_node_or_null("HealthComponent")
				if hc != null and hc.has_method("take_damage"):
					hc.take_damage(int(cmd_args.get("damage", 1)))
		"cycle_weapon":
			var p = get_tree().get_first_node_in_group(&"player")
			if p != null:
				var wm = p.get_node_or_null("WeaponSwapManager")
				if wm != null and wm.has_method("cycle_weapon"):
					wm.cycle_weapon()
		"throw_shuriken":
			var p = get_tree().get_first_node_in_group(&"player")
			if p != null:
				var cc = p.get_node_or_null("CombatController")
				if cc != null and cc.has_method("throw_shuriken"):
					cc.throw_shuriken()
		"complete_level":
			if GameState != null and GameState.has_method("complete_level"):
				GameState.complete_level()


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
		"is_level_active": GameState.is_level_active if GameState != null else false,
		"is_transitioning": SceneRouter.is_transitioning if SceneRouter != null else false,
		"fragments_collected": (GameState.stats.get("fragments", []) as Array).size() if GameState != null else 0,
		"battery": 100.0,
		"player": null,
		"pulses": [],
		"noise_events": recent_noise_events.duplicate(),
		"enemies": [],
		"level_complete": is_level_complete,
		"medal": str(GameState.stats.get("medal", "")) if GameState != null else "",
		"stats": GameState.stats.duplicate() if GameState != null else {},
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

		var health_comp: Node = p.get_node_or_null("HealthComponent")
		var poise_comp: Node = p.get_node_or_null("PoiseComponent")
		var combat_ctrl: Node = p.get_node_or_null("CombatController")

		var current_hp: int = 3
		var max_hp: int = 3
		if health_comp != null:
			current_hp = int(health_comp.get("current_health"))
			max_hp = int(health_comp.get("max_health"))

		var current_poise: float = 100.0
		if poise_comp != null:
			current_poise = float(poise_comp.get("current_poise"))

		var combat_state: String = "idle"
		var combo_idx: int = 0
		if combat_ctrl != null:
			var st = combat_ctrl.get("current_state")
			match st:
				0: combat_state = "idle"
				1: combat_state = "attacking"
				2: combat_state = "parrying"
				3: combat_state = "guarding"
				4: combat_state = "dashing"
			combo_idx = int(combat_ctrl.get("current_combo"))

		var weapon_name: String = "Katana"
		var weapon_mgr: Node = p.get_node_or_null("WeaponSwapManager")
		if weapon_mgr != null and "current_weapon" in weapon_mgr:
			match int(weapon_mgr.get("current_weapon")):
				0: weapon_name = "Katana"
				1: weapon_name = "Naginata"
				2: weapon_name = "Kunai"

		snap["player"] = {
			"pos": [p2d.global_position.x, p2d.global_position.y],
			"vel": [vel.x, vel.y],
			"on_floor": on_floor,
			"is_alive": alive,
			"facing": facing,
			"is_sneaking": sneaking,
			"health": current_hp,
			"max_health": max_hp,
			"poise": current_poise,
			"combat_state": combat_state,
			"combo": combo_idx,
			"weapon": weapon_name
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
			var aw_comp = node.get_node_or_null("Awareness")
			if aw_comp != null and "value" in aw_comp:
				aw = float(aw_comp.get("value"))
			var st: String = ""
			var sm = node.get_node_or_null("StateMachine")
			if sm != null and "current" in sm and sm.get("current") != null:
				st = str(sm.get("current").name)
			var hp: int = 1
			var hc = node.get_node_or_null("HealthComponent")
			if hc != null:
				hp = int(hc.get("current_health"))
			var ps: float = 100.0
			var pc = node.get_node_or_null("PoiseComponent")
			if pc != null:
				ps = float(pc.get("current_poise"))
			var facing: int = 1
			if "facing" in node:
				facing = int(node.get("facing"))
			en_arr.append({
				"name": n2d.name,
				"kind": str(node.get("kind")) if "kind" in node else "",
				"pos": [n2d.global_position.x, n2d.global_position.y],
				"awareness": aw,
				"state": st,
				"facing": facing,
				"health": hp,
				"poise": ps
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
