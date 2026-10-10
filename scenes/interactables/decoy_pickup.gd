class_name DecoyPickup
extends Interactable

func _on_player_entered(_p: Player) -> void:
	if GameState == null:
		return
	if GameState.decoy_count >= 3:
		return

	GameState.decoy_count = mini(GameState.decoy_count + 1, 3)
	if AudioManager != null:
		AudioManager.play_sfx(&"key_pickup", global_position)
	queue_free()
