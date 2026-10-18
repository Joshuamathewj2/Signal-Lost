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

	var text: String = "FPS: %d | Page: %s [F4]\n" % [fps, page_name]
	text += "F3: Toggle Debug Overlay\n"

	match page_idx:
		0:
			text += "--- GAMEPLAY & COMBAT ---\n"
			text += "Level: %d | Detections: %d | Particles: %d\n" % [GameState.level_index, GameState.stats.get("detections", 0), ParticlesFactory.get_alive_count()]
			var player_node: Node = get_tree().get_first_node_in_group(&"player")
			var debug_draw: DebugDraw = get_tree().get_first_node_in_group(&"debug_draw") as DebugDraw
			if debug_draw == null:
				debug_draw = get_node_or_null("../DebugDraw") as DebugDraw

			if player_node != null and player_node is CharacterBody2D:
				var body: CharacterBody2D = player_node as CharacterBody2D
				var motor: PlayerMotor = body.get_node_or_null("PlayerMotor") as PlayerMotor
				var combat: CombatController = body.get_node_or_null("CombatController") as CombatController
				var swap_mgr: WeaponSwapManager = body.get_node_or_null("WeaponSwapManager") as WeaponSwapManager

				var state_str: String = motor.get_state_name() if motor != null else "Unknown"
				var on_floor_str: String = "YES" if body.is_on_floor() else "NO"
				var apex_str: String = "%.1f" % motor.max_jump_height if motor != null else "0.0"

				var weapon_str: String = "Katana"
				if swap_mgr != null:
					weapon_str = str(WeaponSwapManager.get_weapon_name(swap_mgr.current_weapon))

				var combo_str: String = "0"
				var parry_str: String = "INACTIVE"
				if combat != null:
					combo_str = "%d / %d" % [combat.current_combo, combat._get_max_combo_steps()]
					if combat.current_state == CombatController.CombatState.PARRYING:
						var frames_left: int = maxi(1, int(round(combat.parry_timer * 60.0)))
						parry_str = "ACTIVE (%d frames)" % frames_left
					elif combat.current_state == CombatController.CombatState.GUARDING:
						parry_str = "GUARDING"

				text += "Player State: %s | OnFloor: %s | vx: %.1f | vy: %.1f | apex: %s\n" % [state_str, on_floor_str, body.velocity.x, body.velocity.y, apex_str]
				text += "Weapon: %s | Combo: %s | Parry Window: %s\n" % [weapon_str, combo_str, parry_str]

				var battery_node: Battery = body.get_node_or_null("Battery") as Battery
				var charger_node: PulseCharger = body.get_node_or_null("PulseCharger") as PulseCharger
				if battery_node != null:
					text += "Energy: %.1f / %.1f\n" % [battery_node.energy, battery_node.max_energy]
				if charger_node != null and charger_node.is_charging:
					var c: float = clampf(charger_node.charge_time / GameConfig.data.charge_full_time, 0.0, 1.0)
					var t: int = PulseCharger.tier_for_charge(c)
					text += "Pulse Charging: %.2f | Tier: %d\n" % [c, t]

				# Draw Player collision box & hit/hurtboxes
				if debug_draw != null:
					var p_pos: Vector2 = body.global_position
					# Player Body bounds (approx 16x24)
					debug_draw.rect(Rect2(p_pos.x - 8, p_pos.y - 20, 16, 24), Color(0.2, 0.9, 1.0, 0.8))

					# Attack Hitbox
					if combat != null and combat.hitbox != null and combat.hitbox.is_active:
						var hb_shape: CollisionShape2D = combat.hitbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
						if hb_shape != null and hb_shape.shape is RectangleShape2D:
							var r_sz: Vector2 = (hb_shape.shape as RectangleShape2D).size
							var hb_pos: Vector2 = combat.hitbox.global_position + hb_shape.position - (r_sz * 0.5)
							debug_draw.rect(Rect2(hb_pos, r_sz), Color(1.0, 0.1, 0.1, 0.9))

			var enemies: Array[Node] = get_tree().get_nodes_in_group(&"enemies")
			text += "Enemies: %d\n" % enemies.size()

			for e in enemies:
				if e is EnemyBase:
					var eb: EnemyBase = e as EnemyBase
					var st_name: String = eb.state_machine.current.name if (eb.state_machine != null and eb.state_machine.current != null) else "none"
					var aw_val: float = eb.awareness.value if eb.awareness != null else 0.0
					text += "  [%s] State: %s | Aware: %.2f | Facing: %d\n" % [eb.kind, st_name, aw_val, eb.facing]

					# Debug visual annotations
					if debug_draw != null:
						var e_pos: Vector2 = eb.global_position
						# Enemy bounds (approx 16x24)
						debug_draw.rect(Rect2(e_pos.x - 8, e_pos.y - 24, 16, 26), Color(1.0, 0.6, 0.2, 0.7))

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
