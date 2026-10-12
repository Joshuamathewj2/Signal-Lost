class_name TestHealthSystem
extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []

	var hc: HealthComponent = HealthComponent.new()
	hc.max_health = 3
	hc._ready()

	if hc.current_health != 3:
		failures.append("Expected current_health 3, got %d" % hc.current_health)

	var signal_received: Array[bool] = [false]
	var signal_dmg: Array[int] = [0]
	hc.damaged.connect(func(amt: int, _kb: Vector2) -> void:
		signal_received[0] = true
		signal_dmg[0] = amt
	)

	var damaged: bool = hc.take_damage(1)
	if not damaged:
		failures.append("Expected take_damage(1) to succeed")
	if hc.current_health != 2:
		failures.append("Expected current_health 2, got %d" % hc.current_health)
	if not signal_received[0] or signal_dmg[0] != 1:
		failures.append("damaged signal not emitted properly")

	# Test i-frame protection
	var blocked: bool = hc.take_damage(1)
	if blocked:
		failures.append("Expected second hit during invulnerability to be blocked")
	if hc.current_health != 2:
		failures.append("Health decremented during invulnerability")

	# Test healing
	hc.heal(1)
	if hc.current_health != 3:
		failures.append("Expected heal to restore health to 3, got %d" % hc.current_health)

	# Test death
	var died_signal: Array[bool] = [false]
	hc.died.connect(func(_cause: StringName) -> void:
		died_signal[0] = true
	)
	hc.is_invulnerable = false # Clear i-frames for test
	hc.take_damage(3)
	if hc.current_health != 0:
		failures.append("Expected current_health 0 on lethal damage, got %d" % hc.current_health)
	if not died_signal[0]:
		failures.append("died signal not emitted on lethal damage")
	if hc.is_alive():
		failures.append("is_alive returned true after lethal damage")

	return failures
