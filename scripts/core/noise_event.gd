class_name NoiseEvent
extends RefCounted

enum NoiseType {
	PULSE = 0,
	FOOTSTEP = 1,
	LAND = 2,
	IMPACT = 3,
	GLASS = 4,
	CLINK = 5,
	PLATE = 6,
	DECOY = 7,
	ENEMY = 8,
	COMBAT = 9
}

var position: Vector2 = Vector2.ZERO
var radius: float = 0.0
var loudness: float = 0.0
var source_type: NoiseType = NoiseType.PULSE
var timestamp: float = 0.0
var emitter: Node = null

# Aliases for robust backwards compatibility
var type: NoiseType:
	get: return source_type
	set(v): source_type = v

var source: Node:
	get: return emitter
	set(v): emitter = v

var origin: Vector2:
	get: return position
	set(v): position = v

static func make(pos: Vector2, rad: float, loud: float, n_type: NoiseType = NoiseType.PULSE, src: Node = null) -> NoiseEvent:
	var ev := NoiseEvent.new()
	ev.position = pos
	ev.radius = rad
	ev.loudness = loud
	ev.source_type = n_type
	ev.emitter = src
	ev.timestamp = float(Time.get_ticks_msec()) / 1000.0
	return ev
