class_name Fragment
extends Interactable

@export var fragment_id: int = 0

var _base_y: float = 0.0

func _ready() -> void:
	super._ready()
	_base_y = visual.position.y if visual != null else 0.0

func _process(_delta: float) -> void:
	if visual != null:
		visual.position.y = _base_y + sin(Time.get_ticks_msec() * 0.004) * 3.0

func _on_player_entered(_p: Node2D) -> void:
	GameState.collect_fragment(fragment_id)
	emit_noise(0.0, 0.0, NoiseEvent.NoiseType.CLINK)
	ParticlesFactory.spawn_fragment_pickup(get_parent(), global_position)
	queue_free()
