extends Node2D

## Live locomotion parity harness for the hero.
## Drives the real player.tscn with scripted inputs at exact physics frames and
## records a trace of position/velocity. `--record` (user arg) writes the
## baseline; default mode compares against it and exits 0 (match) / 1 (drift).
##
##   godot --headless --path . res://tests/live/fighter_parity.tscn            # compare
##   godot --headless --path . res://tests/live/fighter_parity.tscn -- --record # baseline

const BASELINE_PATH: String = "res://tests/live/fighter_parity_baseline.json"
const TOLERANCE_PX: float = 0.01
const FLOOR_Y: float = 400.0
const LEDGE_X: float = 600.0

## Each scenario: [name, start_x, frames, {frame: [action, pressed]}]
const SCENARIOS: Array = [
	["run_up", 100.0, 70, {0: ["move_right", true]}],
	["stop", 100.0, 80, {0: ["move_right", true], 45: ["move_right", false]}],
	["full_jump", 100.0, 70, {2: ["jump", true]}],
	["short_hop", 100.0, 50, {2: ["jump", true], 4: ["jump", false]}],
	["run_jump", 100.0, 90, {0: ["move_right", true], 20: ["jump", true]}],
	["coyote_ok", 520.0, 60, {0: ["move_right", true], 31: ["jump", true]}],
	["coyote_late", 520.0, 60, {0: ["move_right", true], 40: ["jump", true]}],
	# Full jump lands on frame 39: a press 4 frames early is buffered, 8 frames early is not.
	["buffer_ok", 100.0, 90, {2: ["jump", true], 30: ["jump", false], 35: ["jump", true], 36: ["jump", false]}],
	["buffer_late", 100.0, 90, {2: ["jump", true], 30: ["jump", false], 31: ["jump", true], 32: ["jump", false]}],
]

var player: CharacterBody2D = null
var _frame: int = 0
var _scenario: Array = []
var _trace: Array = []
var _recording: bool = false


func _ready() -> void:
	_recording = OS.get_cmdline_user_args().has("--record")
	process_physics_priority = -100
	_build_floor()
	call_deferred(&"_run_all")


func _build_floor() -> void:
	# Floor from x=-200..LEDGE_X, then a pit (for coyote tests).
	var body := StaticBody2D.new()
	body.set_collision_layer_value(1, true)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(LEDGE_X + 200.0, 64.0)
	shape.shape = rect
	shape.position = Vector2((LEDGE_X - 200.0) * 0.5, FLOOR_Y + 32.0)
	body.add_child(shape)
	add_child(body)


func _run_all() -> void:
	var results: Dictionary = {}
	for sc in SCENARIOS:
		results[sc[0]] = await _run_scenario(sc)
	if _recording:
		var f := FileAccess.open(BASELINE_PATH, FileAccess.WRITE)
		f.store_string(JSON.stringify(results, " "))
		f.close()
		print("[parity] baseline recorded: %s" % BASELINE_PATH)
		_print_summary(results)
		get_tree().quit(0)
		return
	var base: Dictionary = DataLoader.load_json(BASELINE_PATH, PackedStringArray(), false)
	var failures: PackedStringArray = []
	for name in results:
		var a: Array = results[name]
		var b: Array = base.get(name, [])
		if a.size() != b.size():
			failures.append("%s: %d samples vs baseline %d" % [name, a.size(), b.size()])
			continue
		for i in a.size():
			var d: float = Vector2(a[i][0], a[i][1]).distance_to(Vector2(b[i][0], b[i][1]))
			if d > TOLERANCE_PX:
				failures.append("%s: frame %d drift %.3f px (now %s, was %s)" % [name, i, d, str(a[i]), str(b[i])])
				break
	_print_summary(results)
	if failures.is_empty():
		print("PASS fighter_parity: hero locomotion identical to baseline (%d scenarios)" % results.size())
		get_tree().quit(0)
	else:
		for f in failures:
			print("FAIL fighter_parity: ", f)
		get_tree().quit(1)


func _run_scenario(sc: Array) -> Array:
	for a in [&"move_left", &"move_right", &"jump", &"sneak"]:
		Input.action_release(a)
	if player != null:
		player.queue_free()
		await get_tree().physics_frame
	player = (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as CharacterBody2D
	player.position = Vector2(float(sc[1]), FLOOR_Y - 9.0)
	add_child(player)
	# Settle on the floor before the scripted inputs start.
	for i in 10:
		await get_tree().physics_frame
	_scenario = sc
	_trace = []
	_frame = 0
	while _frame < int(sc[2]):
		await get_tree().physics_frame
	_scenario = []
	return _trace


func _physics_process(_delta: float) -> void:
	if _scenario.is_empty() or player == null:
		return
	var inputs: Dictionary = _scenario[3]
	if inputs.has(_frame):
		var ev: Array = inputs[_frame]
		if ev[1]:
			Input.action_press(ev[0])
		else:
			Input.action_release(ev[0])
	# Sample the state produced by the previous physics step.
	_trace.append([snappedf(player.global_position.x, 0.001), snappedf(player.global_position.y, 0.001),
			snappedf(player.velocity.x, 0.001), snappedf(player.velocity.y, 0.001)])
	_frame += 1


func _print_summary(results: Dictionary) -> void:
	for name in results:
		var tr: Array = results[name]
		var apex: float = 0.0
		var y0: float = tr[0][1]
		for s in tr:
			apex = maxf(apex, y0 - float(s[1]))
		print("[parity] %-12s end=(%.1f, %.1f)  apex=%.1f px" % [name, tr[-1][0], tr[-1][1], apex])
