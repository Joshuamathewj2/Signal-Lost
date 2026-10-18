extends Node2D

## AtlasPreview
## Visual check for data/manifests/*.json. The same animation plays on a black
## half and a mid-grey half (halos / fringes show up on grey).
##
## Up/Down   unit            Left/Right  animation      A  auto-cycle on/off
## Space     pause           , / .       step frame     F  flip facing
## + / -     zoom            G           game scale     P  pivots + frame boxes
## R         reload manifests from disk (after re-running tools/atlas_prep.py)

const BG_BLACK: Color = Color(0.0, 0.0, 0.0)
const BG_GREY: Color = Color(0.5, 0.5, 0.5)
const PIVOT_COLOR: Color = Color(0.0, 1.0, 0.6)
const BOX_COLOR: Color = Color(0.2, 0.7, 1.0, 0.8)
const GAME_CAMERA_ZOOM: float = 2.0
const AUTO_CYCLE_LOOPS: int = 2
const AUTO_CYCLE_ONESHOT_HOLD: float = 0.8

var units: PackedStringArray = PackedStringArray()
var unit_idx: int = 0
var anim_names: PackedStringArray = PackedStringArray()
var anim_idx: int = 0
var zoom: float = 1.0
var game_scale: bool = false
var show_guides: bool = true
var auto_cycle: bool = true
var paused: bool = false

var _sprites: Array[ManifestSprite] = []
var _info: Label = null
var _help: Label = null
var _loops: int = 0
var _hold: float = 0.0


func _ready() -> void:
	units = ManifestLoader.list_units()
	for i in 2:
		var s := ManifestSprite.new()
		s.procedural_enabled = true
		add_child(s)
		s.animation_looped.connect(_on_looped)
		s.animation_finished.connect(_on_finished)
		_sprites.append(s)

	var layer := CanvasLayer.new()
	add_child(layer)
	_info = Label.new()
	_info.position = Vector2(24, 16)
	_info.add_theme_font_size_override(&"font_size", 20)
	layer.add_child(_info)
	_help = Label.new()
	_help.position = Vector2(24, 1000)
	_help.add_theme_font_size_override(&"font_size", 16)
	_help.modulate = Color(0.7, 0.7, 0.7)
	_help.text = "Up/Down unit   Left/Right anim   A auto-cycle   Space pause   ,/. step   F flip   +/- zoom   G game scale   P guides   R reload"
	layer.add_child(_help)

	if units.is_empty():
		_info.text = "No manifests in %s - run: python tools/atlas_prep.py" % ManifestLoader.MANIFEST_DIR
		return
	_select_unit(0)


func _select_unit(idx: int) -> void:
	unit_idx = wrapi(idx, 0, units.size())
	for s in _sprites:
		s.unit = units[unit_idx]
	anim_names = PackedStringArray()
	if _sprites[0].sprite_frames != null:
		anim_names = _sprites[0].sprite_frames.get_animation_names()
	_select_anim(0)


func _select_anim(idx: int) -> void:
	if anim_names.is_empty():
		return
	anim_idx = wrapi(idx, 0, anim_names.size())
	_loops = 0
	_hold = 0.0
	_apply_scale()
	for s in _sprites:
		s.play_anim(StringName(anim_names[anim_idx]), true)
		if paused:
			s.pause()
	queue_redraw()


func _apply_scale() -> void:
	var vp: Vector2 = get_viewport_rect().size
	for i in _sprites.size():
		var s: ManifestSprite = _sprites[i]
		var manifest_scale: float = float(s.manifest.get("scale", 1.0))
		s.set_display_scale((manifest_scale * GAME_CAMERA_ZOOM if game_scale else 1.0) * zoom)
		s.set_anchor_position(Vector2(vp.x * (0.25 + 0.5 * float(i)), vp.y * 0.72))


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var k: Key = (event as InputEventKey).keycode
	match k:
		KEY_UP: _select_unit(unit_idx - 1)
		KEY_DOWN: _select_unit(unit_idx + 1)
		KEY_LEFT: _select_anim(anim_idx - 1)
		KEY_RIGHT: _select_anim(anim_idx + 1)
		KEY_A: auto_cycle = not auto_cycle
		KEY_SPACE:
			paused = not paused
			for s in _sprites:
				if paused: s.pause()
				else: s.play()
		KEY_COMMA, KEY_PERIOD:
			paused = true
			for s in _sprites:
				s.pause()
				var n: int = s.sprite_frames.get_frame_count(s.animation)
				s.frame = wrapi(s.frame + (1 if k == KEY_PERIOD else -1), 0, n)
		KEY_F:
			for s in _sprites:
				s.set_facing(-s.facing)
		KEY_EQUAL, KEY_KP_ADD:
			zoom = minf(zoom * 1.25, 6.0)
			_apply_scale()
		KEY_MINUS, KEY_KP_SUBTRACT:
			zoom = maxf(zoom / 1.25, 0.1)
			_apply_scale()
		KEY_G:
			game_scale = not game_scale
			zoom = 1.0
			_apply_scale()
		KEY_P: show_guides = not show_guides
		KEY_R:
			DataLoader.clear_cache()
			ManifestLoader.clear_cache()
			_select_unit(unit_idx)
	queue_redraw()


func _on_looped() -> void:
	_loops += 1


func _on_finished() -> void:
	_hold = AUTO_CYCLE_ONESHOT_HOLD


func _process(delta: float) -> void:
	if anim_names.is_empty():
		return
	if auto_cycle and not paused:
		if _hold > 0.0:
			_hold -= delta
			if _hold <= 0.0:
				_advance()
		elif _loops >= AUTO_CYCLE_LOOPS:
			_advance()
	_update_info()
	queue_redraw()


func _advance() -> void:
	if anim_idx + 1 >= anim_names.size():
		_select_unit(unit_idx + 1)
	else:
		_select_anim(anim_idx + 1)


func _update_info() -> void:
	var s: ManifestSprite = _sprites[0]
	var info: Dictionary = s.anim_info()
	var n: int = s.sprite_frames.get_frame_count(s.animation) if s.sprite_frames != null else 0
	var lines: PackedStringArray = [
		"%s   (%d/%d)   %s" % [units[unit_idx], unit_idx + 1, units.size(), String(s.manifest.get("notes", ""))],
		"anim: %s  (%d/%d)   frame %d/%d   fps %s   loop %s   blend %s   anchor %s" % [
			s.animation, anim_idx + 1, anim_names.size(), s.frame + 1, n, str(info.get("fps", "")),
			str(info.get("loop", false)), str(info.get("blend", "mix")), str(info.get("anchor", "feet"))],
		"scale: manifest %.3f%s   zoom %.2f   auto-cycle %s%s" % [
			float(s.manifest.get("scale", 1.0)), "  x camera %.1f (game view)" % GAME_CAMERA_ZOOM if game_scale else "  (source px)",
			zoom, "on" if auto_cycle else "off", "   PAUSED" if paused else ""],
	]
	if info.has("faked"):
		lines.append("FAKED: %s" % str(info["faked"]))
	if info.has("procedural"):
		lines.append("procedural: %s" % JSON.stringify(info["procedural"]))
	if info.has("events"):
		lines.append("events: %s" % JSON.stringify(info["events"]))
	if info.has("note"):
		lines.append("note: %s" % str(info["note"]))
	_info.text = "\n".join(lines)


func _draw() -> void:
	var vp: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(0, 0, vp.x * 0.5, vp.y), BG_BLACK)
	draw_rect(Rect2(vp.x * 0.5, 0, vp.x * 0.5, vp.y), BG_GREY)
	if not show_guides or anim_names.is_empty():
		return
	for s in _sprites:
		var frames: Array = s.anim_info().get("frames", [])
		if s.frame >= frames.size():
			continue
		var f: Dictionary = frames[s.frame]
		var piv: Vector2 = ManifestLoader.pivot_of(f)
		var sc: float = absf(s.scale.y)
		var x0: float = -piv.x if s.facing > 0 else piv.x - float(f["w"])
		var box := Rect2(s.position + Vector2(x0, -piv.y) * sc, Vector2(float(f["w"]), float(f["h"])) * sc)
		draw_rect(box, BOX_COLOR, false, 1.0)
		draw_line(s.position + Vector2(-10, 0), s.position + Vector2(10, 0), PIVOT_COLOR, 2.0)
		draw_line(s.position + Vector2(0, -10), s.position + Vector2(0, 10), PIVOT_COLOR, 2.0)
		draw_line(Vector2(s.position.x - vp.x * 0.22, s.position.y), Vector2(s.position.x + vp.x * 0.22, s.position.y), Color(PIVOT_COLOR, 0.25), 1.0)
