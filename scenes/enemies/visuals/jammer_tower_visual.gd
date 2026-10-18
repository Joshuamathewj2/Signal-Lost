class_name JammerTowerVisual
extends Node2D

## JammerTowerVisual
## Procedural rendering for the stationary Jammer Tower:
## Heavy reinforced steel pylon, glowing electromagnetic emitter coils,
## and a pulsing 240px acoustic jamming wave aura.

@onready var pylon: Polygon2D = $Pylon
@onready var emitter_coil: Polygon2D = $EmitterCoil
@onready var aura_ring: Node2D = $AuraRing

var pulse_time: float = 0.0
var flash_tween: Tween = null
var jam_radius: float = 240.0

func _process(delta: float) -> void:
	pulse_time += delta
	queue_redraw()

func _draw() -> void:
	# Draw pulsing electromagnetic interference waves
	var wave_phase: float = fmod(pulse_time * 0.8, 1.0)
	var r: float = wave_phase * jam_radius
	var alpha: float = (1.0 - wave_phase) * 0.45
	draw_arc(Vector2(0, -32), r, 0.0, TAU, 32, Color(1.0, 0.2, 0.3, alpha), 1.5, true)

	var wave_phase2: float = fmod(pulse_time * 0.8 + 0.5, 1.0)
	var r2: float = wave_phase2 * jam_radius
	var alpha2: float = (1.0 - wave_phase2) * 0.45
	draw_arc(Vector2(0, -32), r2, 0.0, TAU, 32, Color(1.0, 0.1, 0.2, alpha2), 1.0, true)

	# Emitter cathode spark
	var spark_col := Color(1.0, 0.85, 0.2) if (int(pulse_time * 12.0) % 2 == 0) else Color(1.0, 0.2, 0.2)
	draw_circle(Vector2(0, -48), 3.0, spark_col)

func flash() -> void:
	if pylon == null:
		return
	if flash_tween != null and flash_tween.is_valid():
		flash_tween.kill()
	var orig_col := pylon.color
	pylon.color = Color.WHITE
	flash_tween = create_tween()
	flash_tween.tween_property(pylon, "color", orig_col, 0.12)
