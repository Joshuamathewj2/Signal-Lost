class_name TestDecoy
extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []
	var tree: SceneTree = Engine.get_main_loop() as SceneTree

	# --- 1. Test GameState decoy_count limits & signals ---
	var notified_count := [-1]
	var conn: Callable = func(c: int) -> void: notified_count[0] = c
	GameState.decoy_count_changed.connect(conn)

	GameState.decoy_count = 2
	if GameState.decoy_count != 2:
		failures.append("Expected GameState.decoy_count to be 2")
	if notified_count[0] != 2:
		failures.append("Expected decoy_count_changed to emit 2, got %d" % notified_count[0])

	GameState.decoy_count_changed.disconnect(conn)

	# --- 2. Test DecoyPickup interaction ---
	var pickup_scene: PackedScene = load("res://scenes/interactables/decoy_pickup.tscn")
	if pickup_scene == null:
		failures.append("Failed to load decoy_pickup.tscn")
		return failures

	var pickup: DecoyPickup = pickup_scene.instantiate() as DecoyPickup
	if tree != null and tree.root != null:
		tree.root.add_child(pickup)
	else:
		pickup.notification(Node.NOTIFICATION_READY)

	GameState.decoy_count = 1
	pickup._on_player_entered(null)
	if GameState.decoy_count != 2:
		failures.append("DecoyPickup should increment decoy_count to 2, got %d" % GameState.decoy_count)

	# Test max clamp at 3
	var pickup2: DecoyPickup = pickup_scene.instantiate() as DecoyPickup
	if tree != null and tree.root != null:
		tree.root.add_child(pickup2)
	else:
		pickup2.notification(Node.NOTIFICATION_READY)
	GameState.decoy_count = 3
	pickup2._on_player_entered(null)
	if GameState.decoy_count > 3:
		failures.append("Decoy count should not exceed 3")
	pickup2.queue_free()

	# --- 3. Test Player throw_decoy ---
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	if player_scene == null:
		failures.append("Failed to load player.tscn")
		return failures

	var player: Player = player_scene.instantiate() as Player
	var dummy_parent := Node2D.new()
	if tree != null and tree.root != null:
		tree.root.add_child(dummy_parent)
		dummy_parent.add_child(player)
	else:
		player.notification(Node.NOTIFICATION_READY)

	GameState.decoy_count = 2
	player.throw_decoy()
	if GameState.decoy_count != 1:
		failures.append("Expected throw_decoy to decrement count from 2 to 1, got %d" % GameState.decoy_count)

	var found_beacon: DecoyBeacon = null
	for child in dummy_parent.get_children():
		if child is DecoyBeacon:
			found_beacon = child as DecoyBeacon
			break

	if found_beacon == null:
		failures.append("Expected DecoyBeacon to be spawned into player's parent")
	else:
		if found_beacon.velocity.y >= 0.0:
			failures.append("DecoyBeacon should have upward initial velocity (arc)")
		if found_beacon.velocity.x == 0.0:
			failures.append("DecoyBeacon should have horizontal velocity in facing direction")

	# Clean up player & dummy parent
	dummy_parent.queue_free()

	# --- 4. Test DecoyBeacon landing & noise emission ---
	var beacon_scene: PackedScene = load("res://scenes/interactables/decoy_beacon.tscn")
	if beacon_scene == null:
		failures.append("Failed to load decoy_beacon.tscn")
		return failures

	var beacon: DecoyBeacon = beacon_scene.instantiate() as DecoyBeacon
	if tree != null and tree.root != null:
		tree.root.add_child(beacon)
	else:
		beacon.notification(Node.NOTIFICATION_READY)

	var noise_received := [false]
	var noise_type := [-1]
	var noise_conn: Callable = func(ev: NoiseEvent) -> void:
		noise_received[0] = true
		noise_type[0] = ev.type

	NoiseBus.noise_emitted.connect(noise_conn)

	# Simulate landing
	beacon.landed = true
	beacon._timer = 0.01
	beacon._physics_process(0.02) # Should trigger decoy

	if not noise_received[0]:
		failures.append("DecoyBeacon should emit noise on trigger")
	if noise_type[0] != NoiseEvent.NoiseType.DECOY:
		failures.append("Expected noise type to be DECOY, got %d" % noise_type[0])

	NoiseBus.noise_emitted.disconnect(noise_conn)
	beacon.queue_free()

	return failures
