class_name EliteModifier
extends Node2D

## EliteModifier
## Applies dynamic elite enhancements to any hostile:
## - ARMORED: +100% poise, cyan unshaded outline
## - ENRAGED: +40% speed, rapid attack rate after taking damage, orange outline
## - HUNTER: +100% hearing range, amber outline

enum ModifierType {
	NONE,
	ARMORED,
	ENRAGED,
	HUNTER
}

@export var modifier: ModifierType = ModifierType.NONE

var _hostile: CharacterBody2D = null
var _outline_color: Color = Color.TRANSPARENT

func _ready() -> void:
	_hostile = get_parent() as CharacterBody2D
	if _hostile != null:
		_apply_modifier()

func apply_modifier(mod_type: ModifierType) -> void:
	modifier = mod_type
	_apply_modifier()

func _apply_modifier() -> void:
	if _hostile == null:
		return

	match modifier:
		ModifierType.ARMORED:
			_outline_color = Color(0.2, 0.8, 1.0, 0.9)
			var poise: Node = _hostile.get_node_or_null("PoiseComponent")
			if poise != null and "max_poise" in poise:
				poise.set("max_poise", float(poise.get("max_poise")) * 2.0)
				poise.set("current_poise", float(poise.get("max_poise")))

		ModifierType.ENRAGED:
			_outline_color = Color(1.0, 0.45, 0.1, 0.9)
			var health: Node = _hostile.get_node_or_null("HealthComponent")
			if health != null and health.has_signal("damaged"):
				health.connect("damaged", func(_amount: int, _cause: StringName) -> void:
					var mover: Node = _hostile.get_node_or_null("PlatformMover")
					if mover != null and "run_speed" in mover:
						mover.set("run_speed", float(mover.get("run_speed")) * 1.4)
				)

		ModifierType.HUNTER:
			_outline_color = Color(1.0, 0.85, 0.2, 0.9)
			var hearing: Node = _hostile.get_node_or_null("HearingComponent")
			if hearing != null and "profile" in hearing and hearing.profile != null:
				hearing.profile.hearing_mult = 2.0
				hearing.profile.hearing_threshold = 0.4

	queue_redraw()

func _draw() -> void:
	if modifier == ModifierType.NONE or _outline_color.a <= 0.0:
		return
	# Draw unshaded elite aura ring around base
	draw_arc(Vector2(0, -14), 22.0, 0.0, TAU, 24, _outline_color, 1.8, true)
	if modifier == ModifierType.ENRAGED:
		draw_arc(Vector2(0, -14), 26.0, 0.0, TAU, 16, Color(1, 0.2, 0.1, 0.5), 1.0, true)
