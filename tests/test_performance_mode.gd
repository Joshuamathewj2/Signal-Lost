class_name TestPerformanceMode
extends RefCounted

const SonarScript = preload("res://scenes/sonar/sonar_system.gd")

func run() -> Array[String]:
	var failures: Array[String] = []

	var original_quality: int = GameConfig.sonar_quality

	# 1. Test HIGH mode
	GameConfig.set_sonar_quality(1)
	if GameConfig.sonar_quality != 1:
		failures.append("Expected sonar_quality == 1")
	if GameConfig.data.max_bubbles != 6:
		failures.append("Expected max_bubbles == 6 in HIGH mode")

	# 2. Test LOW mode
	GameConfig.set_sonar_quality(0)
	if GameConfig.sonar_quality != 0:
		failures.append("Expected sonar_quality == 0")
	if GameConfig.data.max_bubbles != 4:
		failures.append("Expected max_bubbles == 4 in LOW mode")

	# 3. SonarSystem bubble limit under LOW mode
	var sonar = SonarScript.new()
	sonar._ready()
	var profile: PulseProfile = GameConfig.pulse_for_tier(0) # whisper
	# Spawn 5 bubbles
	var b1 = sonar.spawn(profile, Vector2(10, 10))
	var b2 = sonar.spawn(profile, Vector2(20, 20))
	var b3 = sonar.spawn(profile, Vector2(30, 30))
	var b4 = sonar.spawn(profile, Vector2(40, 40))
	var b5 = sonar.spawn(profile, Vector2(50, 50)) # should recycle oldest among first 4

	var active_count: int = 0
	for b in sonar.pool:
		if b.active:
			active_count += 1

	if active_count > 4:
		failures.append("Expected active bubbles <= 4 in LOW quality mode, got %d" % active_count)

	if b1 != null and b1.light != null:
		if b1.light.shadow_enabled:
			failures.append("Expected light shadow_enabled == false in LOW quality mode")
		if b1.light.shadow_filter != PointLight2D.SHADOW_FILTER_NONE:
			failures.append("Expected light shadow_filter == NONE in LOW quality mode")

	sonar.queue_free()

	# Restore quality
	GameConfig.set_sonar_quality(original_quality)

	return failures
