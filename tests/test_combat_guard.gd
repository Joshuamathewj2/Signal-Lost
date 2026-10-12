class_name TestCombatGuard
extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []

	var pc: PoiseComponent = PoiseComponent.new()
	pc.max_poise = 100.0
	pc._ready()

	if pc.current_poise != 100.0:
		failures.append("Expected current_poise 100.0, got %f" % pc.current_poise)

	# Apply partial poise damage
	var broken: bool = pc.damage_poise(40.0)
	if broken:
		failures.append("Poise broke prematurely at 60.0 poise remaining")
	if absf(pc.current_poise - 60.0) > 0.01:
		failures.append("Expected current_poise 60.0, got %f" % pc.current_poise)

	# Connect stagger and guard break signals
	var signals_called: Array[bool] = [false, false]
	pc.staggered.connect(func(_dur: float) -> void:
		signals_called[0] = true
	)
	pc.guard_broken.connect(func() -> void:
		signals_called[1] = true
	)

	# Deplete poise to 0
	broken = pc.damage_poise(70.0)
	if not broken:
		failures.append("damage_poise did not report guard break on depletion")
	if not pc.is_staggered:
		failures.append("is_staggered is false after depletion")
	if not signals_called[0] or not signals_called[1]:
		failures.append("staggered or guard_broken signal not emitted")

	# Test poise reset
	pc.reset_poise()
	if absf(pc.current_poise - 100.0) > 0.01:
		failures.append("Expected reset_poise to restore 100.0, got %f" % pc.current_poise)

	return failures
