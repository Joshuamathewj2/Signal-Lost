class_name MathUtil
extends RefCounted

static func ease_out_cubic(x: float) -> float:
	var c: float = clampf(x, 0.0, 1.0)
	return 1.0 - pow(1.0 - c, 3.0)

static func wave_radius(R: float, t: float, T_exp: float) -> float:
	var u: float = clampf(t / maxf(T_exp, 0.0001), 0.0, 1.0)
	return R * ease_out_cubic(u)

static func bubble_brightness(t: float, T_exp: float, hold: float, fade: float, ghost: float = 0.12, ghost_time: float = 2.0) -> float:
	if t < T_exp + hold:
		return 1.0
	elif t < T_exp + hold + fade:
		var u: float = (t - T_exp - hold) / maxf(fade, 0.0001)
		return ghost + (1.0 - ghost) * pow(1.0 - u, 2.0)
	elif t < T_exp + hold + fade + ghost_time:
		var v: float = (t - T_exp - hold - fade) / maxf(ghost_time, 0.0001)
		var s: float = smoothstep(0.7, 1.0, v)
		return ghost * (1.0 - s)
	else:
		return -1.0

static func ring_alpha(t: float, T_exp: float, ring_fade: float = 0.35) -> float:
	if t < T_exp:
		return 1.0
	else:
		return maxf(0.0, 1.0 - (t - T_exp) / maxf(ring_fade, 0.0001))
