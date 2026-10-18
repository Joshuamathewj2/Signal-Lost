class_name ManifestLoader
extends RefCounted

## ManifestLoader
## Converts atlas manifests (data/manifests/<unit>.json, produced by
## tools/atlas_prep.py) into SpriteFrames at load time.
##
## Pivot handling: every frame of a unit is padded (AtlasTexture.margin) into one
## shared canvas whose origin is the pivot, so the feet anchor sits on the same
## pixel in every frame -> no jitter between frames or animations. Use the
## canvas origin as the sprite offset (ManifestSprite does this).
## A frame's hand "override": {"ox", "oy"} wins over the generated pivot.

const MANIFEST_DIR: String = "res://data/manifests/"
const REQUIRED_KEYS: PackedStringArray = ["atlas", "atlas_size", "scale", "animations"]
const FRAME_KEYS: PackedStringArray = ["x", "y", "w", "h", "ox", "oy"]

static var _frames_cache: Dictionary = {}


static func path_for(unit_or_path: String) -> String:
	if unit_or_path.begins_with("res://"):
		return unit_or_path
	return MANIFEST_DIR + unit_or_path + ".json"


static func list_units() -> PackedStringArray:
	var units := PackedStringArray()
	var dir: DirAccess = DirAccess.open(MANIFEST_DIR)
	if dir == null:
		return units
	for f in dir.get_files():
		if f.ends_with(".json"):
			units.append(f.get_basename())
	units.sort()
	return units


## Loads and validates a manifest. Returns {} (and logs why) when invalid.
static func load_manifest(unit_or_path: String) -> Dictionary:
	var path: String = path_for(unit_or_path)
	var m: Dictionary = DataLoader.load_json(path, REQUIRED_KEYS)
	if m.is_empty():
		return m
	var atlas_size: Array = m["atlas_size"]
	var anims: Dictionary = m["animations"]
	for anim_name in anims:
		var a: Dictionary = anims[anim_name]
		var frames: Array = a.get("frames", [])
		if frames.is_empty():
			push_error("[ManifestLoader] %s: animation '%s' has no frames" % [path, anim_name])
			return {}
		var durations: Array = a.get("durations", [])
		if not durations.is_empty() and durations.size() != frames.size():
			push_error("[ManifestLoader] %s: '%s' has %d durations for %d frames" % [path, anim_name, durations.size(), frames.size()])
			return {}
		for i in frames.size():
			var f: Dictionary = frames[i]
			var ctx: String = "%s anim '%s' frame %d" % [path, anim_name, i]
			if not DataLoader.validate_keys(f, FRAME_KEYS, ctx).is_empty():
				return {}
			if f["x"] + f["w"] > atlas_size[0] or f["y"] + f["h"] > atlas_size[1]:
				push_error("[ManifestLoader] %s: rect outside atlas %s" % [ctx, str(atlas_size)])
				return {}
	return m


static func pivot_of(frame: Dictionary) -> Vector2:
	var piv := Vector2(float(frame["ox"]), float(frame["oy"]))
	var ov: Variant = frame.get("override")
	if ov is Dictionary:
		piv.x = float((ov as Dictionary).get("ox", piv.x))
		piv.y = float((ov as Dictionary).get("oy", piv.y))
	return piv


## Shared canvas of a unit in source pixels, relative to the pivot:
## position = (-left, -top), size = full padded frame size.
static func canvas_of(m: Dictionary) -> Rect2:
	var left: float = 0.0
	var top: float = 0.0
	var right: float = 0.0
	var bottom: float = 0.0
	var anims: Dictionary = m.get("animations", {})
	for anim_name in anims:
		for f in (anims[anim_name] as Dictionary)["frames"]:
			var piv: Vector2 = pivot_of(f)
			left = maxf(left, piv.x)
			top = maxf(top, piv.y)
			right = maxf(right, float(f["w"]) - piv.x)
			bottom = maxf(bottom, float(f["h"]) - piv.y)
	return Rect2(-left, -top, left + right, top + bottom)


static func build_sprite_frames(unit_or_path: String) -> SpriteFrames:
	var path: String = path_for(unit_or_path)
	if _frames_cache.has(path):
		return _frames_cache[path]
	var m: Dictionary = load_manifest(path)
	if m.is_empty():
		return null
	var atlas: Texture2D = load(String(m["atlas"])) as Texture2D
	if atlas == null:
		push_error("[ManifestLoader] %s: atlas texture '%s' not imported/loadable" % [path, m["atlas"]])
		return null

	var canvas: Rect2 = canvas_of(m)
	var sf := SpriteFrames.new()
	var anims: Dictionary = m["animations"]
	for anim_name in anims:
		var a: Dictionary = anims[anim_name]
		var fps: float = float(a.get("fps", 10.0))
		var durations: Array = a.get("durations", [])
		sf.add_animation(anim_name)
		sf.set_animation_loop(anim_name, bool(a.get("loop", false)))
		sf.set_animation_speed(anim_name, fps)
		var frames: Array = a["frames"]
		for i in frames.size():
			var f: Dictionary = frames[i]
			var piv: Vector2 = pivot_of(f)
			var tex := AtlasTexture.new()
			tex.atlas = atlas
			tex.region = Rect2(float(f["x"]), float(f["y"]), float(f["w"]), float(f["h"]))
			tex.margin = Rect2(-canvas.position.x - piv.x, -canvas.position.y - piv.y,
					canvas.size.x - float(f["w"]), canvas.size.y - float(f["h"]))
			tex.filter_clip = true
			var dur: float = float(durations[i]) if i < durations.size() else 1.0 / fps
			# SpriteFrames frame duration is relative: seconds = duration / fps.
			sf.add_frame(anim_name, tex, dur * fps)
	if sf.has_animation(&"default") and not anims.has("default"):
		sf.remove_animation(&"default")
	_frames_cache[path] = sf
	return sf


static func clear_cache() -> void:
	_frames_cache.clear()
