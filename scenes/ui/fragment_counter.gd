class_name FragmentCounter
extends HBoxContainer

@onready var frag_icon: Control = $FragIcon
@onready var frag_count: Label = $FragCount

var _current_count: int = 0
var _pop_tween: Tween = null

func _ensure_nodes() -> void:
	if frag_icon == null:
		frag_icon = get_node_or_null("FragIcon") as Control
	if frag_count == null:
		frag_count = get_node_or_null("FragCount") as Label

func _ready() -> void:
	_ensure_nodes()
	if frag_icon != null and not frag_icon.draw.is_connected(_on_frag_icon_draw):
		frag_icon.draw.connect(_on_frag_icon_draw)
	
	if GameState != null and GameState.has_signal("run_stats_changed"):
		GameState.run_stats_changed.connect(_on_stats_changed)
		var frags: Array = GameState.stats.get("fragments", []) as Array
		set_count(frags.size(), false)
	else:
		set_count(0, false)

func _on_stats_changed(stats: Dictionary) -> void:
	var frags: Array = stats.get("fragments", []) as Array
	if frags.size() != _current_count:
		set_count(frags.size(), true)

func set_count(count: int, pop: bool = true) -> void:
	_ensure_nodes()
	_current_count = count
	if frag_count != null:
		frag_count.text = str(_current_count)
	if pop and is_inside_tree():
		_trigger_pop()

func _trigger_pop() -> void:
	pivot_offset = Vector2(0.0, size.y * 0.5)
	if _pop_tween != null and _pop_tween.is_valid():
		_pop_tween.kill()
	scale = Vector2(1.3, 1.3)
	_pop_tween = create_tween()
	_pop_tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_frag_icon_draw() -> void:
	_ensure_nodes()
	if frag_icon == null:
		return
	var white: Color = Palette.color(&"white")
	var dot_center := Vector2(6.0, 12.0)
	frag_icon.draw_circle(dot_center, 1.75, white)
	frag_icon.draw_arc(dot_center, 5.5, -PI * 0.5, 0.0, 16, white, 1.5)
	frag_icon.draw_arc(dot_center, 10.0, -PI * 0.5, 0.0, 16, white, 1.5)
