class_name TestAwarenessReticles
extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []

	# 1. AwarenessBar
	var bar_scene: PackedScene = load("res://scenes/ui/awareness_bar.tscn")
	if bar_scene == null:
		failures.append("awareness_bar.tscn failed to load")
		return failures

	var bar: AwarenessBar = bar_scene.instantiate() as AwarenessBar
	if bar == null:
		failures.append("AwarenessBar failed to instantiate")
		return failures
	if bar.modulate.a != 0.0:
		failures.append("AwarenessBar should start transparent")
	bar.free()

	# 2. WorldReticle
	var ret_scene: PackedScene = load("res://scenes/ui/world_reticle.tscn")
	if ret_scene == null:
		failures.append("world_reticle.tscn failed to load")
		return failures

	var ret: WorldReticle = ret_scene.instantiate() as WorldReticle
	if ret == null:
		failures.append("WorldReticle failed to instantiate")
		return failures

	# Test Projectile mode
	ret.reticle_type = WorldReticle.Type.PROJECTILE
	if ret.reticle_type != WorldReticle.Type.PROJECTILE:
		failures.append("Reticle should be PROJECTILE")

	# Test Noise Origin mode
	ret.setup_noise(Vector2(100, 200), null)
	if ret.reticle_type != WorldReticle.Type.NOISE_ORIGIN:
		failures.append("setup_noise failed to set NOISE_ORIGIN type")
	if ret.global_position != Vector2(100, 200):
		failures.append("setup_noise failed to set position")
	if not ret.visible:
		failures.append("setup_noise should make reticle visible")

	ret.free()

	# 3. Projectile reticle
	var proj_scene: PackedScene = load("res://scenes/enemies/projectile.tscn")
	if proj_scene == null:
		failures.append("projectile.tscn failed to load")
		return failures

	var proj: Projectile = proj_scene.instantiate() as Projectile
	if proj == null:
		failures.append("Projectile failed to instantiate")
		return failures
	proj.notification(Node.NOTIFICATION_READY)
	if proj.reticle == null:
		failures.append("Projectile should have child WorldReticle")
	elif proj.reticle.reticle_type != WorldReticle.Type.PROJECTILE:
		failures.append("Projectile reticle should have type PROJECTILE")

	proj.free()

	return failures
