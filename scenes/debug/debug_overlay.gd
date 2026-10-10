extends CanvasLayer

@onready var info_label: Label = $Control/InfoLabel

const PAGE_NAMES: Array[String] = ["0: Gameplay", "1: Graph", "2: Render"]

func _ready() -> void:
	layer = 100
	visible = DebugFlags.overlay_visible

func _process(_delta: float) -> void:
	visible = DebugFlags.overlay_visible
	if not visible:
		return

	var fps: int = int(Engine.get_frames_per_second())
	var page_idx: int = DebugFlags.page
	var page_name: String = PAGE_NAMES[page_idx] if page_idx < PAGE_NAMES.size() else str(page_idx)

	var text: String = "FPS: %d | Page: %s [F2]\n" % [fps, page_name]
	text += "F1: Toggle Debug Overlay\n"

	match page_idx:
		0:
			text += "--- GAMEPLAY ---\n"
			text += "Level: %d | Detections: %d | Particles: %d\n" % [GameState.level_index, GameState.stats.get("detections", 0), ParticlesFactory.get_alive_count()]
			var player_node: Node = get_tree().get_first_node_in_group(&"player")
			if player_node != null and player_node is CharacterBody2D:
				var body: CharacterBody2D = player_node as CharacterBody2D
				var motor: PlayerMotor = body.get_node_or_null("PlayerMotor") as PlayerMotor
				var state_str: String = "air"
				if body.is_on_floor():
					state_str = "sneak" if (motor != null and motor.is_sneaking) else ("run" if absf(body.velocity.x) > 5.0 else "idle")
				var apex_str: String = "%.1f" % motor.max_jump_height if motor != null else "0.0"
				text += "Player: %s | vx: %.1f | vy: %.1f | apex: %s\n" % [state_str, body.velocity.x, body.velocity.y, apex_str]
				var battery_node: Battery = body.get_node_or_null("Battery") as Battery
				var charger_node: PulseCharger = body.get_node_or_null("PulseCharger") as PulseCharger
				if battery_node != null:
					text += "Energy: %.1f / %.1f\n" % [battery_node.energy, battery_node.max_energy]
				if charger_node != null and charger_node.is_charging:
					var c: float = clampf(charger_node.charge_time / GameConfig.data.charge_full_time, 0.0, 1.0)
					var t: int = PulseCharger.tier_for_charge(c)
					text += "Pulse Charging: %.2f | Tier: %d\n" % [c, t]

			var enemies: Array[Node] = get_tree().get_nodes_in_group(&"enemies")
			text += "Enemies: %d\n" % enemies.size()
			var debug_draw: DebugDraw = get_tree().get_first_node_in_group(&"debug_draw") as DebugDraw
			if debug_draw == null:
				debug_draw = get_node_or_null("../DebugDraw") as DebugDraw

			for e in enemies:
				if e is EnemyBase:
					var eb: EnemyBase = e as EnemyBase
					var st_name: String = eb.state_machine.current.name if (eb.state_machine != null and eb.state_machine.current != null) else "none"
					var aw_val: float = eb.awareness.value if eb.awareness != null else 0.0
					text += "  [%s] State: %s | Aware: %.2f | Facing: %d\n" % [eb.kind, st_name, aw_val, eb.facing]

					# Debug visual annotations
					if debug_draw != null:
						var e_pos: Vector2 = eb.global_position
						# State label
						debug_draw.text(e_pos + Vector2(-20, -32), "%s (%.0f%%)" % [st_name, aw_val * 100.0])

						# Vision cone
						if eb.profile != null and eb.profile.sight_range > 0.0:
							var f_dir: Vector2 = Vector2.RIGHT if eb.facing >= 0 else Vector2.LEFT
							var half_ang: float = deg_to_rad(eb.profile.sight_angle_deg * 0.5)
							var r1: Vector2 = f_dir.rotated(-half_ang) * eb.profile.sight_range
							var r2: Vector2 = f_dir.rotated(half_ang) * eb.profile.sight_range
							debug_draw.line(e_pos, e_pos + r1, Color(1, 0.2, 0.2, 0.4))
							debug_draw.line(e_pos, e_pos + r2, Color(1, 0.2, 0.2, 0.4))

						# Mover target
						if eb.mover != null and eb.mover.is_moving:
							debug_draw.line(e_pos, eb.mover.target_pos, Color(0.2, 1, 0.2, 0.5))

						# Memory positions
						if eb.memory != null:
							for mem in eb.memory.get_all():
								var m_pos: Vector2 = mem.get("pos", Vector2.ZERO)
								debug_draw.circle(m_pos, 4.0, Color(1, 0.8, 0.2, 0.7))

		1:
			text += "--- GRAPH ---\n"
			text += "Platform Graph view\n"
		2:
			text += "--- RENDER ---\n"
			text += "Lights Off: %s\n" % str(DebugFlags.lights_off)
			text += "Active Bubbles: %d / 6\n" % PulseRegistry.bubbles.size()
			for i in range(PulseRegistry.bubbles.size()):
				var b = PulseRegistry.bubbles[i]
				if b != null:
					text += "  [%d] age: %.2fs | r: %.1f | energy: %.2f\n" % [i, b.age, b.radius, b.brightness]

	info_label.text = text
