class_name Vent
extends Node2D

@export_enum("INTAKE", "OUTLET", "MUTE") var mode: String = "INTAKE"
@export var cell: Vector2i = Vector2i.ZERO

@onready var visual: Node2D = $Visual
@onready var mute_area: Area2D = $MuteArea
@onready var glyph_intake: Node2D = $Visual/GlyphIntake
@onready var glyph_outlet: Node2D = $Visual/GlyphOutlet
@onready var glyph_mute: Node2D = $Visual/GlyphMute

var outlet: Vent = null

func _ready() -> void:
	match mode:
		"INTAKE":
			add_to_group(&"vent_intakes")
		"OUTLET":
			add_to_group(&"vent_outlets")
		"MUTE":
			add_to_group(&"vent_mutes")

	if glyph_intake != null:
		glyph_intake.visible = (mode == "INTAKE")
	if glyph_outlet != null:
		glyph_outlet.visible = (mode == "OUTLET")
	if glyph_mute != null:
		glyph_mute.visible = (mode == "MUTE")

	if mute_area != null:
		mute_area.monitoring = (mode == "MUTE")
		if mode == "MUTE":
			mute_area.body_entered.connect(_on_mute_body_entered)
			mute_area.body_exited.connect(_on_mute_body_exited)

func _on_mute_body_entered(body: Node2D) -> void:
	if body is Player:
		var p: Player = body as Player
		if p.pulse_charger != null:
			p.pulse_charger.noise_scale = 0.3

func _on_mute_body_exited(body: Node2D) -> void:
	if body is Player:
		var p: Player = body as Player
		if p.pulse_charger != null:
			p.pulse_charger.noise_scale = 1.0
