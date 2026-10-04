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
		1:
			text += "--- GRAPH ---\n"
			text += "Platform Graph view\n"
		2:
			text += "--- RENDER ---\n"
			text += "Lights Off: %s\n" % str(DebugFlags.lights_off)

	info_label.text = text
