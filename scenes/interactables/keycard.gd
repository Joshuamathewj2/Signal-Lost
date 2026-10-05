class_name Keycard
extends Interactable

func _on_player_entered(_p: Player) -> void:
	GameState.has_keycard = true
	emit_noise(0.0, 0.0, NoiseEvent.NoiseType.CLINK)
	queue_free()
