extends Node

var bubbles: Array = []
var _warned_reveal: bool = false

func reveal_at(_pos: Vector2) -> float:
	if not _warned_reveal:
		_warned_reveal = true
		push_warning("STUB: PulseRegistry.reveal_at (task P0-T6)")
		DebugFlags.log(&"stub", "PulseRegistry.reveal_at called")
	return 0.0

func set_bubbles(active_list: Array) -> void:
	bubbles = active_list

func player_revealed(_player_pos: Vector2) -> bool:
	return reveal_at(_player_pos) > GameConfig.cfg.reveal_visible_threshold
