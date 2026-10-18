extends Node2D

func _ready() -> void:
	call_deferred(&"_run")

func _run() -> void:
	var lr_scene: PackedScene = load("res://scenes/level/level_root.tscn")
	var lr: LevelRoot = lr_scene.instantiate() as LevelRoot
	lr.level_path = "res://levels/level_04.txt"
	add_child(lr)
	for i in range(30):
		await get_tree().process_frame

	var player: Player = lr.get_node_or_null("Player") as Player
	if player != null and lr.sonar_system != null:
		var prof: PulseProfile = preload("res://resources/pulses/pulse_normal.tres")
		lr.sonar_system.spawn(prof, player.global_position)

	for i in range(15):
		await get_tree().process_frame

	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		img.save_png("res://qa/shots/level4_spawn_before.png")
		print("[CAPTURE] Saved res://qa/shots/level4_spawn_before.png")
	get_tree().quit()
