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
	ENEMY = 8
}

var position: Vector2 = Vector2.ZERO
var radius: float = 0.0
var loudness: float = 0.0
var type: NoiseType = NoiseType.PULSE
var source: Node = null

static func make(pos: Vector2, rad: float, loud: float, n_type: NoiseType = NoiseType.PULSE, src: Node = null) -> NoiseEvent:
	var ev := NoiseEvent.new()
	ev.position = pos
	ev.radius = rad
	ev.loudness = loud
	ev.type = n_type
	ev.source = src
	return ev
