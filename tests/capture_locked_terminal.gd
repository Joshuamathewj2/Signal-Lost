extends Node2D

func _ready() -> void:
	call_deferred(&"_run")

func _run() -> void:
	var lr_scene: PackedScene = load("res://scenes/level/level_root.tscn")
	var lr: LevelRoot = lr_scene.instantiate() as LevelRoot
	lr.level_path = "res://levels/level_02.txt"
	add_child(lr)

	for i in range(25):
		await get_tree().process_frame

	var player: Player = lr.get_node_or_null("Player") as Player
	var terminal: ExitTerminal = lr.get_node_or_null("Interactables/ExitTerminal") as ExitTerminal
	if terminal == null and lr.interactables != null:
		terminal = lr.interactables.find_child("ExitTerminal", true, false) as ExitTerminal

	if player != null and terminal != null:
		# Place player right on terminal to trigger the locked gate
		player.global_position = terminal.global_position
		terminal._on_player_entered(player)

	for i in range(15):
		await get_tree().process_frame

	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		img.save_png("res://qa/shots/locked_terminal.png")
		print("[CAPTURE] Saved res://qa/shots/locked_terminal.png")
	get_tree().quit()
