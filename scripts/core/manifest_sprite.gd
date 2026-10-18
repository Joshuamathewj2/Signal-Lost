class_name ManifestSprite
extends AnimatedSprite2D

## ManifestSprite
## Plays a unit from data/manifests/<unit>.json:
## - frames are pivot-anchored (feet / centre sits on this node's origin)
## - manifest "scale" and "foot_offset" applied (display_scale_override wins if > 0)
## - per-animation blend ("add" -> additive material)
## - per-frame "events" re-emitted as frame_event
## - "procedural" treatments for frames the art does not have:
##   breathe, bob, shake, pulse, rotate, tint (warning|clone), modulate, flash

signal frame_event(event: StringName, anim: StringName, frame_index: int)

const FLASH_SHADER: Shader = preload("res://shaders/manifest_flash.gdshader")
const FLASH_SHADER_UNSHADED: Shader = preload("res://shaders/manifest_flash_unshaded.gdshader")
const WARNING_TINT: Color = Color(1.6, 0.45, 0.45, 1.0)
const CLONE_TINT: Color = Color(0.32, 0.08, 0.1, 0.7)

@export var unit: String = "":
	set(value):
		unit = value
		if is_inside_tree():
			_load_unit()
@export var autoplay_anim: StringName = &""
@export var display_scale_override: float = 0.0
@export var procedural_enabled: bool = true

var manifest: Dictionary = {}
var facing: int = 1

var _base_scale: float = 1.0
var _anchor: Vector2 = Vector2.ZERO
var _base_position: Vector2 = Vector2.ZERO
var _proc_time: float = 0.0
var _flash_left: float = 0.0
var _flash_mat: ShaderMaterial = null
var _flash_mat_unshaded: ShaderMaterial = null
var _add_mat: CanvasItemMaterial = null
var _forced_tint: String = ""
var _forced_left: float = 0.0


func _ready() -> void:
	centered = false
	_anchor = position
	_base_position = position
	frame_changed.connect(_on_frame_changed)
	_load_unit()


func _load_unit() -> void:
	if unit.is_empty():
		return
	manifest = ManifestLoader.load_manifest(unit)
	if manifest.is_empty():
		return
	sprite_frames = ManifestLoader.build_sprite_frames(unit)
	offset = ManifestLoader.canvas_of(manifest).position
	_base_scale = display_scale_override if display_scale_override > 0.0 else float(manifest.get("scale", 1.0))
	_base_position = _anchor + Vector2(0.0, float(manifest.get("foot_offset", 0.0)))
	_flash_mat = ShaderMaterial.new()
	_flash_mat.shader = FLASH_SHADER
	_flash_mat_unshaded = ShaderMaterial.new()
	_flash_mat_unshaded.shader = FLASH_SHADER_UNSHADED
	_add_mat = CanvasItemMaterial.new()
	_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	# Additive FX are light sources themselves: never darkened by CanvasModulate.
	_add_mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_apply_transform(Vector2.ZERO, 0.0, 1.0, 1.0)
	if autoplay_anim != &"":
		play_anim(autoplay_anim)


## Moves the feet anchor (the node's authored position, before foot_offset).
func set_anchor_position(p: Vector2) -> void:
	_anchor = p
	_base_position = _anchor + Vector2(0.0, float(manifest.get("foot_offset", 0.0)))
	position = _base_position


func set_display_scale(s: float) -> void:
	display_scale_override = s
	_base_scale = s if s > 0.0 else float(manifest.get("scale", 1.0))


func has_anim(anim_name: StringName) -> bool:
	return sprite_frames != null and sprite_frames.has_animation(anim_name)


func anim_info(anim_name: StringName = animation) -> Dictionary:
	var anims: Dictionary = manifest.get("animations", {})
	return anims.get(String(anim_name), {})


func play_anim(anim_name: StringName, restart: bool = false) -> bool:
	if not has_anim(anim_name):
		return false
	if animation == anim_name and is_playing() and not restart:
		return true
	var info: Dictionary = anim_info(anim_name)
	material = _add_mat if String(info.get("blend", "mix")) == "add" else _flash_mat
	play(anim_name)
	if restart:
		frame = 0
	_proc_time = 0.0
	var proc: Dictionary = info.get("procedural", {})
	if proc.has("flash"):
		flash(float(proc.get("time", 0.06)))
	_emit_events_for(0)
	return true


func set_facing(dir: int) -> void:
	if dir != 0:
		facing = 1 if dir > 0 else -1


func flash(duration: float = 0.06) -> void:
	_flash_left = duration


## Overrides the animation's tint for `duration` s ("warning" | "clone").
## Warnings render self-lit so telegraphs read even outside sonar light.
func force_tint(kind: String, duration: float) -> void:
	_forced_tint = kind
	_forced_left = duration


func _on_frame_changed() -> void:
	_emit_events_for(frame)


func _emit_events_for(frame_index: int) -> void:
	var events: Array = anim_info().get("events", [])
	for e in events:
		if int((e as Dictionary).get("frame", -1)) == frame_index:
			frame_event.emit(StringName(str(e["event"])), animation, frame_index)


func _process(delta: float) -> void:
	if manifest.is_empty():
		return
	_proc_time += delta
	var proc: Dictionary = anim_info().get("procedural", {}) if procedural_enabled else {}
	var pos_off := Vector2.ZERO
	var rot: float = 0.0
	var sx: float = 1.0
	var sy: float = 1.0
	var mod := Color.WHITE

	if proc.has("breathe"):
		var k: float = sin(_proc_time * TAU / float(proc.get("period", 1.6))) * float(proc["breathe"])
		sy += k
		sx -= k * 0.5
	if proc.has("pulse"):
		var p: float = (sin(_proc_time * TAU / float(proc.get("period", 0.5))) * 0.5 + 0.5) * float(proc["pulse"])
		sx += p
		sy += p
	if proc.has("bob") and sprite_frames != null:
		pos_off.y = -absf(sin(_proc_time * PI * sprite_frames.get_animation_speed(animation))) * float(proc["bob"])
	if proc.has("shake"):
		var amp: float = float(proc["shake"])
		pos_off += Vector2(randf_range(-amp, amp), randf_range(-amp, amp) * 0.5)
	if proc.has("rotate"):
		rot = float(proc["rotate"])
	var tint: String = String(proc.get("tint", ""))
	if _forced_left > 0.0:
		_forced_left -= delta
		tint = _forced_tint
	match tint:
		"warning":
			# 0.4 s telegraph reads as a red blink (8 Hz), never as a steady colour.
			mod = Color.WHITE.lerp(WARNING_TINT, 0.5 + 0.5 * sin(_proc_time * TAU * 8.0))
		"clone":
			mod = CLONE_TINT
	if proc.has("modulate"):
		var m: Array = proc["modulate"]
		mod = Color(float(m[0]), float(m[1]), float(m[2]), float(m[3]))

	_apply_transform(pos_off, rot, sx, sy)
	self_modulate = mod

	if _flash_mat != null and material != _add_mat:
		material = _flash_mat_unshaded if tint == "warning" else _flash_mat
		_flash_left = maxf(_flash_left - delta, 0.0)
		(material as ShaderMaterial).set_shader_parameter(&"flash_amount", 1.0 if _flash_left > 0.0 else 0.0)


func _apply_transform(pos_off: Vector2, rot: float, sx: float, sy: float) -> void:
	position = _base_position + pos_off
	rotation = rot * float(facing)
	scale = Vector2(_base_scale * sx * float(facing), _base_scale * sy)
