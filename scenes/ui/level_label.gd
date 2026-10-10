class_name LevelLabel
extends VBoxContainer

@onready var level_name_label: Label = $LevelName
@onready var progress_bar: Control = $Progress

var displayed_progress: float = 0.0
var _target_progress: float = 0.0
var _tween: Tween = null
var _timer: float = 0.0

func _ensure_nodes() -> void:
	if level_name_label == null:
		level_name_label = get_node_or_null("LevelName") as Label
	if progress_bar == null:
		progress_bar = get_node_or_null("Progress") as Control

func _ready() -> void:
	_ensure_nodes()
	custom_minimum_size = Vector2(220, 36)
	if progress_bar != null and not progress_bar.draw.is_connected(_on_progress_draw):
		progress_bar.draw.connect(_on_progress_draw)
		progress_bar.custom_minimum_size = Vector2(220, 2)
	
	if level_name_label != null:
		level_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var lvl_idx: int = GameState.level_index if GameState != null else 1
		level_name_label.text = "Level %d" % lvl_idx

	_recompute_progress()

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= 0.5:
		_timer = 0.0
		_recompute_progress()

func set_level_name(p_name: String) -> void:
	_ensure_nodes()
	if level_name_label != null:
		level_name_label.text = p_name

func set_progress(val: float, instant: bool = false) -> void:
	_ensure_nodes()
	_target_progress = clampf(val, 0.0, 1.0)
	if instant or not is_inside_tree():
		displayed_progress = _target_progress
		if progress_bar != null:
			progress_bar.queue_redraw()
		return

	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "displayed_progress", _target_progress, 0.3)
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(func() -> void:
		if progress_bar != null:
			progress_bar.queue_redraw()
	)

func _recompute_progress() -> void:
	_ensure_nodes()
	if not is_inside_tree():
		return
	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	var level_root: LevelRoot = null
	var router: Node = get_node_or_null("/root/SceneRouter")
	if router != null and "current_level_root" in router:
		level_root = router.get("current_level_root") as LevelRoot
	if level_root == null and player != null:
		level_root = player.get_parent() as LevelRoot
	if level_root == null:
		level_root = get_tree().root.find_child("LevelRoot", true, false) as LevelRoot

	if level_root != null and level_root.current_level_data != null:
		var data: LevelData = level_root.current_level_data
		if level_name_label != null:
			if not data.name.is_empty():
				level_name_label.text = data.name
			else:
				var lvl_idx: int = GameState.level_index if GameState != null else 1
				level_name_label.text = "Level %d" % lvl_idx

		if player != null and level_root.platform_graph != null:
			var graph: PlatformGraph = level_root.platform_graph
			var spawn_px := (Vector2(data.player_spawn) + Vector2(0.5, 1.0)) * 32.0
			var exit_px := (Vector2(data.exit_cell) + Vector2(0.5, 1.0)) * 32.0

			var total_dist: float = graph.path_length(spawn_px, exit_px)
			var cur_dist: float = graph.path_length(player.global_position, exit_px)

			if total_dist <= 0.0:
				total_dist = spawn_px.distance_to(exit_px)
				cur_dist = player.global_position.distance_to(exit_px)

			if total_dist > 0.0:
				var prog: float = 1.0 - clampf(cur_dist / total_dist, 0.0, 1.0)
				set_progress(prog)

	if progress_bar != null:
		progress_bar.queue_redraw()

func _on_progress_draw() -> void:
	_ensure_nodes()
	if progress_bar == null:
		return
	var track_col: Color = Palette.color(&"track")
	var white_col: Color = Palette.color(&"white")

	# 220x2 track
	progress_bar.draw_rect(Rect2(0, 0, 220, 2), track_col, true)
	var fill_w: float = 220.0 * clampf(displayed_progress, 0.0, 1.0)
	if fill_w > 0.0:
		progress_bar.draw_rect(Rect2(0, 0, fill_w, 2), white_col, true)
