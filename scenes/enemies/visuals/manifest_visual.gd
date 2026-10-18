class_name ManifestVisual
extends Node2D

## ManifestVisual
## Enemy "Visual" node backed by a ManifestSprite (data/manifests/<unit>.json).
## Implements the visual API EnemyBase and the states already call
## (set_facing, play_anim, flash, show_tell, set_alert) and maps generic anim
## names (idle, run, hurt, die, stun, evade, ...) onto the unit's animations.
## While no one-shot is playing it picks idle / run / jump / fall from motion.
## A Fighter dash telegraph plays the wind-up with a self-lit red warning tint.

const FONT: Font = preload("res://assets/fonts/Rajdhani-SemiBold.ttf")

## Generic name -> candidate manifest animations (first that exists wins).
## Per-enemy "anim_map" in data/enemies/<kind>.json overrides entries.
const DEFAULT_MAP: Dictionary = {
	"idle": ["idle", "crouch_idle", "idle_concealed"],
	"walk": ["walk", "reposition", "run"],
	"run": ["run", "run_smooth", "walk", "dash"],
	"jump": ["jump", "dash"],
	"fall": ["jump", "dash"],
	"hurt": ["hit", "hit_flash"],
	"die": ["defeat", "dissolve"],
	"stun": ["stagger", "hit"],
	"evade": ["roll", "dash", "reposition"],
	"attack": ["slash", "thrust", "slam", "release"],
	"telegraph": ["ready", "windup", "spear_ready", "draw", "aim"],
	"dash": ["dash", "run"],
	"block": ["idle"],
}
const LOOPING_LOCOMOTION: PackedStringArray = ["idle", "walk", "run", "jump", "fall"]

@export var unit: String = ""
@export var anim_map: Dictionary = {}

var sprite: ManifestSprite = null
var tell_label: Label = null
var _body: CharacterBody2D = null
var _fighter: Fighter = null
var _oneshot: bool = false
var _locked: bool = false   ## death pose: stays until freed
var _tell_tween: Tween = null


func _ready() -> void:
	_body = get_parent() as CharacterBody2D
	if _body != null:
		var data: Dictionary = _body.get("enemy_data") if _body.get("enemy_data") != null else {}
		if unit.is_empty():
			unit = String(data.get("manifest", ""))
		var m: Dictionary = data.get("anim_map", {})
		for k in m:
			anim_map[k] = m[k]
		_fighter = _body.get_node_or_null("Fighter") as Fighter

	sprite = ManifestSprite.new()
	sprite.name = "ManifestSprite"
	add_child(sprite)
	sprite.unit = unit
	sprite.animation_finished.connect(_on_anim_finished)

	tell_label = Label.new()
	tell_label.visible = false
	tell_label.text = "!"
	tell_label.position = Vector2(-10.0, -64.0)
	tell_label.size = Vector2(20.0, 20.0)
	tell_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tell_label.add_theme_font_override(&"font", FONT)
	tell_label.add_theme_font_size_override(&"font_size", 14)
	tell_label.pivot_offset = Vector2(10.0, 10.0)
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	tell_label.material = mat
	add_child(tell_label)

	if _fighter != null:
		_fighter.dash_telegraphed.connect(func(duration: float) -> void:
			play_anim(&"telegraph")
			sprite.force_tint("warning", duration)
		)
		_fighter.dash_started.connect(func() -> void: play_anim(&"dash"))
	play_anim(&"idle")


func resolve(generic: StringName) -> StringName:
	var key: String = String(generic)
	var candidates: Array = []
	if anim_map.has(key):
		var v: Variant = anim_map[key]
		candidates = v if v is Array else [v]
	candidates.append_array(DEFAULT_MAP.get(key, []))
	candidates.append(key)
	for c in candidates:
		if sprite.has_anim(StringName(str(c))):
			return StringName(str(c))
	return &""


func play_anim(anim_name: StringName) -> void:
	if sprite == null or _locked:
		return
	var resolved: StringName = resolve(anim_name)
	if resolved == &"":
		return
	_oneshot = not LOOPING_LOCOMOTION.has(String(anim_name))
	_locked = anim_name == &"die"
	sprite.play_anim(resolved, _oneshot)


func set_facing(dir: int) -> void:
	if sprite != null:
		sprite.set_facing(dir)


func flash() -> void:
	if sprite != null:
		sprite.flash(0.08)


func set_alert(val: float) -> void:
	modulate = Color(0.85 + 0.3 * val, 0.85 - 0.2 * val, 0.85 - 0.2 * val, 1.0)


func show_tell(glyph: Variant = "!") -> void:
	var text: String = "!" if glyph is StringName and glyph == &"exclamation" else str(glyph)
	tell_label.text = text
	tell_label.modulate = Color(1.0, 0.1, 0.1, 1.0)
	tell_label.scale = Vector2.ZERO
	tell_label.visible = true
	if _tell_tween != null and _tell_tween.is_valid():
		_tell_tween.kill()
	_tell_tween = create_tween()
	_tell_tween.tween_property(tell_label, "scale", Vector2(1.5, 1.5), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tell_tween.tween_property(tell_label, "scale", Vector2.ONE, 0.08)
	_tell_tween.tween_interval(0.4)
	_tell_tween.tween_property(tell_label, "modulate:a", 0.0, 0.15)
	_tell_tween.tween_callback(func() -> void: tell_label.visible = false)
	flash()


func _on_anim_finished() -> void:
	if not _locked:
		_oneshot = false


func _process(_delta: float) -> void:
	if _oneshot or _locked or _body == null or sprite == null:
		return
	var loco: StringName = &"idle"
	if not _body.is_on_floor():
		loco = &"jump" if _body.velocity.y < 0.0 else &"fall"
	elif absf(_body.velocity.x) > 10.0:
		var run_speed: float = _fighter.stats.run_speed if _fighter != null else 120.0
		loco = &"run" if absf(_body.velocity.x) > run_speed * 0.6 else &"walk"
	var resolved: StringName = resolve(loco)
	if resolved != &"" and sprite.animation != resolved:
		sprite.play_anim(resolved)
