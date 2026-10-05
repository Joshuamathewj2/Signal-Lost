class_name TestHearing
extends RefCounted

const HearingCompScript = preload("res://scenes/enemies/hearing_component.gd")

func run() -> Array[String]:
	var failures: Array[String] = []

	var p_listener: EnemyProfile = preload("res://resources/enemies/enemy_listener.tres")
	var p_sentry: EnemyProfile = preload("res://resources/enemies/enemy_sentry.tres")
	var p_hunter: EnemyProfile = preload("res://resources/enemies/enemy_hunter.tres")
	var p_brute: EnemyProfile = preload("res://resources/enemies/enemy_brute.tres")

	var wall_pen: float = 0.75

	# 1. Whisper at 40 px heard by Listener (strength > 0), at 50 px not
	# Whisper: radius 43, loudness 1.0, type PULSE (0)
	var s_w40: float = HearingCompScript.evaluate(40.0, 0, 43.0, 1.0, 0, p_listener, wall_pen)
	if s_w40 <= 0.0:
		failures.append("Expected whisper at 40 px heard by Listener, got %.3f" % s_w40)

	var s_w50: float = HearingCompScript.evaluate(50.0, 0, 43.0, 1.0, 0, p_listener, wall_pen)
	if s_w50 != -1.0:
		failures.append("Expected whisper at 50 px not heard by Listener, got %.3f" % s_w50)

	# 2. Normal through 1 wall at 120 px (120 * 1.75 = 210 > 200 -> NOT heard)
	# Normal: radius 200, loudness 2.0, type PULSE (0)
	var s_n120_1w: float = HearingCompScript.evaluate(120.0, 1, 200.0, 2.0, 0, p_listener, wall_pen)
	if s_n120_1w != -1.0:
		failures.append("Expected normal through 1 wall at 120 px not heard by Listener (210 > 200), got %.3f" % s_n120_1w)

	var s_n120_0w: float = HearingCompScript.evaluate(120.0, 0, 200.0, 2.0, 0, p_listener, wall_pen)
	if s_n120_0w <= 0.0:
		failures.append("Expected normal through 0 walls at 120 px heard by Listener, got %.3f" % s_n120_0w)

	# 3. Scream at 700 px heard by Sentry
	# Scream: radius 728, loudness 3.0, type PULSE (0)
	var s_s700: float = HearingCompScript.evaluate(700.0, 0, 728.0, 3.0, 0, p_sentry, wall_pen)
	if s_s700 <= 0.0:
		failures.append("Expected scream at 700 px heard by Sentry, got %.3f" % s_s700)

	# Whisper/Normal (loudness 1.0/2.0) should be ignored by Sentry (threshold 3.0)
	var s_w_sentry: float = HearingCompScript.evaluate(30.0, 0, 43.0, 1.0, 0, p_sentry, wall_pen)
	if s_w_sentry != -1.0:
		failures.append("Expected whisper ignored by Sentry (threshold 3.0), got %.3f" % s_w_sentry)

	# 4. Footstep ignored by Listener (threshold 1.0 vs loud 0.5) and heard by Hunter at 45 px (40 * 1.25 = 50)
	# Footstep: radius 40, loudness 0.5, type FOOTSTEP (1)
	var s_foot_list: float = HearingCompScript.evaluate(20.0, 0, 40.0, 0.5, 1, p_listener, wall_pen)
	if s_foot_list != -1.0:
		failures.append("Expected footstep ignored by Listener (threshold 1.0 > 0.5), got %.3f" % s_foot_list)

	var s_foot_hunt_45: float = HearingCompScript.evaluate(45.0, 0, 40.0, 0.5, 1, p_hunter, wall_pen)
	if s_foot_hunt_45 <= 0.0:
		failures.append("Expected footstep at 45 px heard by Hunter (R=50), got %.3f" % s_foot_hunt_45)

	var s_foot_hunt_55: float = HearingCompScript.evaluate(55.0, 0, 40.0, 0.5, 1, p_hunter, wall_pen)
	if s_foot_hunt_55 != -1.0:
		failures.append("Expected footstep at 55 px not heard by Hunter (R=50), got %.3f" % s_foot_hunt_55)

	return failures
