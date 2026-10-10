extends Node

signal run_stats_changed(stats: Dictionary)
signal detected
signal level_completed(stats: Dictionary)
signal decoy_count_changed(n: int)
signal keycard_changed(has_it: bool)

var level_index: int = 1
var has_keycard: bool = false:
	set(val):
		has_keycard = val
		keycard_changed.emit(has_keycard)

var decoy_count: int = 0:
	set(val):
		decoy_count = val
		decoy_count_changed.emit(decoy_count)

var alert_level: float = 0.0
var is_level_active: bool = false

var stats: Dictionary = {
	"time": 0.0,
	"pulses": {
		"whisper": 0,
		"normal": 0,
		"scream": 0
	},
	"loudest": 0,
	"detections": 0,
	"fragments": [] as Array[int],
	"level_index": 1
}

func _ready() -> void:
	if SceneRouter != null and SceneRouter.has_signal("level_loaded"):
		SceneRouter.level_loaded.connect(_on_level_loaded)

func _process(delta: float) -> void:
	if is_level_active:
		stats["time"] += delta

func _on_level_loaded(_level_root: Node) -> void:
	reset_run()

func reset_run() -> void:
	has_keycard = false
	is_level_active = true
	stats = {
		"time": 0.0,
		"pulses": {
			"whisper": 0,
			"normal": 0,
			"scream": 0
		},
		"loudest": 0,
		"detections": 0,
		"fragments": [] as Array[int],
		"level_index": level_index
	}
	run_stats_changed.emit(stats)

func register_pulse(profile: PulseProfile) -> void:
	if profile == null:
		return
	var id: String = str(profile.id)
	if id == "whisper":
		stats["pulses"]["whisper"] = stats["pulses"].get("whisper", 0) + 1
	elif id == "normal":
		stats["pulses"]["normal"] = stats["pulses"].get("normal", 0) + 1
		if stats["loudest"] < 1:
			stats["loudest"] = 1
	elif id == "scream":
		stats["pulses"]["scream"] = stats["pulses"].get("scream", 0) + 1
		stats["loudest"] = 2
	run_stats_changed.emit(stats)

func collect_fragment(id: int) -> void:
	var frags: Array = stats["fragments"] as Array
	if not frags.has(id):
		frags.append(id)
		run_stats_changed.emit(stats)

func register_detection(_enemy: Node = null) -> void:
	stats["detections"] += 1
	detected.emit()
	run_stats_changed.emit(stats)

func compute_medal(p_stats: Dictionary) -> StringName:
	var p_dict: Dictionary = p_stats.get("pulses", {})
	var norm_val: Variant = p_dict.get("normal")
	if norm_val == null:
		norm_val = p_dict.get(&"normal")
	if norm_val == null:
		norm_val = p_dict.get(1)
	var norm_count: int = int(norm_val) if norm_val != null else 0

	var scream_val: Variant = p_dict.get("scream")
	if scream_val == null:
		scream_val = p_dict.get(&"scream")
	if scream_val == null:
		scream_val = p_dict.get(2)
	var scream_count: int = int(scream_val) if scream_val != null else 0

	var det_count: int = p_stats.get("detections", 0)

	# Ghost: 0 Normal and 0 Scream pulses (decoys allowed) and 0 detections.
	if norm_count == 0 and scream_count == 0 and det_count == 0:
		return &"ghost"
	# Quiet: 0 Scream pulses, <= 1 detection.
	if scream_count == 0 and det_count <= 1:
		return &"quiet"
	# Loud: anything else.
	return &"loud"

func complete_level() -> void:
	is_level_active = false
	stats["medal"] = compute_medal(stats)
	level_completed.emit(stats)
