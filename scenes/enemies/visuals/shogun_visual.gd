class_name ShogunVisual
extends Node2D

## ShogunVisual
## Articulated multi-limbed Mechanical Daimyo (120 px tall on screen).
## Horned kabuto crest, layered sode pauldrons, acoustic chest core, twin naginatas.

@onready var body_poly: Polygon2D = get_node_or_null("Body") as Polygon2D
@onready var helm_poly: Polygon2D = get_node_or_null("Helm") as Polygon2D
@onready var crest_poly: Polygon2D = get_node_or_null("Crest") as Polygon2D
@onready var core_poly: Polygon2D = get_node_or_null("Core") as Polygon2D
@onready var weapon_l: Line2D = get_node_or_null("WeaponL") as Line2D
@onready var weapon_r: Line2D = get_node_or_null("WeaponR") as Line2D
@onready var tell_label: Label = get_node_or_null("TellLabel") as Label

var current_phase: int = 1
var anim_time: float = 0.0
var is_blackout: bool = false
var is_attacking: bool = false


func _ready() -> void:
	if tell_label != null:
		tell_label.visible = false
	update_colors()


func update_colors() -> void:
	var base_red := Color(0.88, 0.08, 0.08, 1.0)
	for p in [body_poly, helm_poly, crest_poly]:
		if p != null:
			p.color = base_red
	if core_poly != null:
		core_poly.color = Color(1.0, 0.35, 0.35, 1.0)
	if weapon_l != null:
		weapon_l.default_color = Color(0.95, 0.95, 0.95, 1.0)
	if weapon_r != null:
		weapon_r.default_color = Color(0.95, 0.95, 0.95, 1.0)


func set_phase(phase: int) -> void:
	current_phase = phase
	if phase == 3:
		# Overdrive Ronin: eyes and core burn bright white-red
		if core_poly != null:
			core_poly.color = Color(2.0, 0.2, 0.2, 1.0)
	flash()


func set_blackout(blackout: bool) -> void:
	is_blackout = blackout
	if blackout and not is_attacking:
		modulate.a = 0.0
	else:
		modulate.a = 1.0


func show_tell(text_val: String = "!") -> void:
	if tell_label != null:
		tell_label.text = text_val
		tell_label.visible = true
		var t := create_tween()
		t.tween_interval(0.4)
		t.tween_callback(func() -> void: tell_label.visible = false)


func flash() -> void:
	modulate = Color(2.5, 2.5, 2.5, 1.0)
	var t := create_tween()
	t.tween_property(self, "modulate", Color.WHITE if not is_blackout else Color(1, 1, 1, 0.0), 0.15)


func play_attack(_anim_name: StringName) -> void:
	is_attacking = true
	modulate.a = 1.0
	var t := create_tween()
	t.tween_property(self, "rotation", deg_to_rad(12.0), 0.1)
	t.tween_property(self, "rotation", 0.0, 0.2)
	t.tween_callback(func() -> void:
		is_attacking = false
		if is_blackout:
			modulate.a = 0.0
	)


func _process(delta: float) -> void:
	anim_time += delta
	var bob: float = sin(anim_time * 3.0) * 1.5
	if body_poly != null:
		body_poly.position.y = bob
	if core_poly != null:
		var pulse_scale: float = 0.9 + 0.2 * sin(anim_time * 6.0)
		core_poly.scale = Vector2(pulse_scale, pulse_scale)
