class_name TestPuzzleGlyphs
extends RefCounted

## Unit tests for EchoGlyph tier-selective reveal mechanics.

func run() -> Array[String]:
	var failures: Array[String] = []

	var glyph_script := load("res://scenes/interactables/echo_glyph.gd")
	if glyph_script == null:
		failures.append("Failed to load echo_glyph.gd")
		return failures

	# 1. Test Whisper tier reveal
	var glyph_whisper = glyph_script.new()
	glyph_whisper.required_tier = &"whisper"
	glyph_whisper._ready()

	var pulse_w := PulseProfile.new()
	pulse_w.id = &"whisper"

	glyph_whisper.on_wavefront(pulse_w, Vector2.ZERO)
	if not glyph_whisper.is_revealed:
		failures.append("EchoGlyph failed to reveal with matching whisper pulse")
	if not glyph_whisper.is_correct_tier:
		failures.append("EchoGlyph expected is_correct_tier=true on matching tier")
	if glyph_whisper.reveal_color != Color(0.2, 0.9, 1.0):
		failures.append("EchoGlyph expected cyan reveal color on whisper, got %s" % str(glyph_whisper.reveal_color))

	# 2. Test Normal tier reveal
	var glyph_normal = glyph_script.new()
	glyph_normal.required_tier = &"normal"
	glyph_normal._ready()

	var pulse_n := PulseProfile.new()
	pulse_n.id = &"normal"

	glyph_normal.on_wavefront(pulse_n, Vector2.ZERO)
	if not glyph_normal.is_revealed:
		failures.append("EchoGlyph failed to reveal with matching normal pulse")
	if glyph_normal.reveal_color != Color(1.0, 1.0, 1.0):
		failures.append("EchoGlyph expected white reveal color on normal, got %s" % str(glyph_normal.reveal_color))

	# 3. Test Scream tier reveal
	var glyph_scream = glyph_script.new()
	glyph_scream.required_tier = &"scream"
	glyph_scream._ready()

	var pulse_s := PulseProfile.new()
	pulse_s.id = &"scream"

	glyph_scream.on_wavefront(pulse_s, Vector2.ZERO)
	if not glyph_scream.is_revealed:
		failures.append("EchoGlyph failed to reveal with matching scream pulse")
	if glyph_scream.reveal_color != Color(1.0, 0.25, 0.25):
		failures.append("EchoGlyph expected red reveal color on scream, got %s" % str(glyph_scream.reveal_color))

	# 4. Test Mismatched tier (Whisper glyph struck by Normal pulse)
	var glyph_mismatch = glyph_script.new()
	glyph_mismatch.required_tier = &"whisper"
	glyph_mismatch._ready()

	glyph_mismatch.on_wavefront(pulse_n, Vector2.ZERO)
	if glyph_mismatch.is_correct_tier:
		failures.append("EchoGlyph should not register is_correct_tier=true on mismatched tier")
	if glyph_mismatch.reveal_alpha != 0.4:
		failures.append("EchoGlyph expected dim 0.4 alpha on wrong tier, got %f" % glyph_mismatch.reveal_alpha)

	# 5. Test alpha fade over time
	glyph_whisper._process(2.0)
	if glyph_whisper.reveal_alpha >= 1.0:
		failures.append("EchoGlyph expected alpha to decay after 2.0s, got %f" % glyph_whisper.reveal_alpha)

	glyph_whisper.free()
	glyph_normal.free()
	glyph_scream.free()
	glyph_mismatch.free()

	return failures
