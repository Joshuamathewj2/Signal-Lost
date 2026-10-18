extends RefCounted

## Every atlas manifest validates, builds SpriteFrames, and keeps the pivot on a
## shared canvas origin (frames of a unit all have the same padded size).

func run() -> Array[String]:
	var failures: Array[String] = []
	var units: PackedStringArray = ManifestLoader.list_units()
	if units.size() < 11:
		failures.append("expected >= 11 manifests, found %d" % units.size())
	for unit in units:
		var m: Dictionary = ManifestLoader.load_manifest(unit)
		if m.is_empty():
			failures.append("%s: manifest failed validation" % unit)
			continue
		var sf: SpriteFrames = ManifestLoader.build_sprite_frames(unit)
		if sf == null:
			failures.append("%s: SpriteFrames build failed" % unit)
			continue
		var canvas: Rect2 = ManifestLoader.canvas_of(m)
		var anims: Dictionary = m["animations"]
		for anim_name in anims:
			if not sf.has_animation(anim_name):
				failures.append("%s: missing animation %s" % [unit, anim_name])
				continue
			var n: int = sf.get_frame_count(anim_name)
			if n != (anims[anim_name]["frames"] as Array).size():
				failures.append("%s.%s: frame count mismatch" % [unit, anim_name])
			for i in n:
				var tex: Texture2D = sf.get_frame_texture(anim_name, i)
				if tex == null or tex.get_size() != canvas.size:
					failures.append("%s.%s[%d]: padded frame size %s != canvas %s" % [unit, anim_name, i, str(tex.get_size() if tex else Vector2.ZERO), str(canvas.size)])
					break
		if float(m["scale"]) <= 0.0:
			failures.append("%s: scale must be > 0" % unit)
	var bad := DataLoader.load_json("res://data/__missing__.json")
	if not bad.is_empty():
		failures.append("DataLoader returned data for a missing file")
	return failures
