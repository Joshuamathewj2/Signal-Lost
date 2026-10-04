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
			text += "Level: %d | Detections: %d\n" % [GameState.level_index, GameState.stats.get("detections", 0)]
			var player_node: Node = get_tree().get_first_node_in_group(&"player")
			if player_node != null and player_node is CharacterBody2D:
				var body: CharacterBody2D = player_node as CharacterBody2D
				var motor: PlayerMotor = body.get_node_or_null("PlayerMotor") as PlayerMotor
				var state_str: String = "air"
				if body.is_on_floor():
					state_str = "sneak" if (motor != null and motor.is_sneaking) else ("run" if absf(body.velocity.x) > 5.0 else "idle")
				text += "Player: %s | vx: %.1f | vy: %.1f\n" % [state_str, body.velocity.x, body.velocity.y]

		1:
			text += "--- GRAPH ---\n"
			text += "Platform Graph view\n"
		2:
			text += "--- RENDER ---\n"
			text += "Lights Off: %s\n" % str(DebugFlags.lights_off)

	info_label.text = text
