class_name TestPulseTiers
extends RefCounted

func run() -> Array[String]:
	var failures: Array[String] = []

	# Test tier boundaries
	var t0: int = PulseCharger.tier_for_charge(0.0)
	if t0 != 0:
		failures.append("c=0.0 expected tier 0, got %d" % t0)

	var t0_34: int = PulseCharger.tier_for_charge(0.34)
	if t0_34 != 0:
		failures.append("c=0.34 expected tier 0, got %d" % t0_34)

	var t0_35: int = PulseCharger.tier_for_charge(0.35)
	if t0_35 != 1:
		failures.append("c=0.35 expected tier 1, got %d" % t0_35)

	var t0_84: int = PulseCharger.tier_for_charge(0.84)
	if t0_84 != 1:
		failures.append("c=0.84 expected tier 1, got %d" % t0_84)

	var t0_85: int = PulseCharger.tier_for_charge(0.85)
	if t0_85 != 2:
		failures.append("c=0.85 expected tier 2, got %d" % t0_85)

	var t1: int = PulseCharger.tier_for_charge(1.0)
	if t1 != 2:
		failures.append("c=1.0 expected tier 2, got %d" % t1)

	# Test downgrade logic
	# Selected tier 2 (Scream, cost 55), but energy = 10 -> cannot afford scream (55) or normal (22), can afford whisper (6)
	var aff_10: int = PulseCharger.get_affordable_tier(2, 10.0)
	if aff_10 != 0:
		failures.append("Selected tier 2 with energy 10 expected affordable tier 0 (whisper), got %d" % aff_10)

	# Selected tier 2 with energy 30 -> cannot afford scream (55), can afford normal (22)
	var aff_30: int = PulseCharger.get_affordable_tier(2, 30.0)
	if aff_30 != 1:
		failures.append("Selected tier 2 with energy 30 expected affordable tier 1 (normal), got %d" % aff_30)

	# Selected tier 0 with energy 3 -> cannot afford whisper (6)
	var aff_3: int = PulseCharger.get_affordable_tier(0, 3.0)
	if aff_3 != -1:
		failures.append("Selected tier 0 with energy 3 expected affordable tier -1, got %d" % aff_3)

	return failures
