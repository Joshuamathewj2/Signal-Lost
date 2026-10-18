class_name ChainHook
extends Area2D

## ChainHook
## Heavy kusarigama sickle hook thrown by Chain Reaper up to 200px.
## On contact with player, hooks and drags player towards the reaper.
## Parry intercepts and snaps the chain, staggering the reaper.

@export var speed: float = 380.0
@export var max_range: float = 200.0

var direction: Vector2 = Vector2.RIGHT
var distance_traveled: float = 0.0
var reaper: Node2D = null
var hooked_player: Node2D = null
var is_returning: bool = false
var is_snapped: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(6, true) # Projectile/Attack
	set_collision_mask_value(1, true) # World
	set_collision_mask_value(3, true) # Player
	set_collision_mask_value(4, true) # Hurtboxes

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if is_snapped:
		return

	if hooked_player != null and is_instance_valid(hooked_player):
		if reaper != null and is_instance_valid(reaper):
			var to_reaper: Vector2 = (reaper.global_position - hooked_player.global_position).normalized()
			hooked_player.global_position += to_reaper * 320.0 * delta
			global_position = hooked_player.global_position
			if hooked_player.global_position.distance_to(reaper.global_position) <= 24.0:
				_release_hook()
		else:
			_release_hook()
		return

	if not is_returning:
		var step := speed * delta
		position += direction * step
		distance_traveled += step
		if distance_traveled >= max_range:
			is_returning = true
	else:
		if reaper != null and is_instance_valid(reaper):
			var to_reaper: Vector2 = (reaper.global_position - global_position).normalized()
			position += to_reaper * speed * delta
			if global_position.distance_to(reaper.global_position) <= 16.0:
				queue_free()
		else:
			queue_free()

func deflect(by_actor: Node = null) -> void:
	if is_snapped:
		return
	is_snapped = true
	if reaper != null and reaper.has_method("on_chain_snapped"):
		reaper.call("on_chain_snapped")

	if NoiseBus != null:
		var ev := NoiseEvent.make(global_position, 220.0, 2.0, NoiseEvent.NoiseType.CLINK, null)
		NoiseBus.emit_noise(ev)

	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if is_snapped or is_returning:
		return
	if body.is_in_group(&"player"):
		_hook_player(body)
	else:
		is_returning = true

func _on_area_entered(area: Area2D) -> void:
	if is_snapped or is_returning:
		return
	if area.is_in_group(&"player") or (area.get_parent() != null and area.get_parent().is_in_group(&"player")):
		var p := area.get_parent() as Node2D
		if p != null:
			_hook_player(p)

func _hook_player(p: Node2D) -> void:
	hooked_player = p
	if NoiseBus != null:
		var ev := NoiseEvent.make(global_position, 140.0, 1.2, NoiseEvent.NoiseType.COMBAT, self)
		NoiseBus.emit_noise(ev)

func _release_hook() -> void:
	hooked_player = null
	queue_free()
