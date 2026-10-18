class_name ChainReaper
extends EnemyBase

## ChainReaper
## Hooded executioner armed with a weighted kusarigama chain hook (200px reach).
## Throws chain hook to ensnare and drag the player into lethal melee range.
## Parry snaps the chain, instantly staggering the reaper.

signal hook_thrown(hook: Node)
signal chain_snapped

const HOOK_SCENE: PackedScene = preload("res://scenes/enemies/chain_hook.tscn")

var hook_cooldown: float = 0.0
var active_hook: Node2D = null

func _ready() -> void:
	kind = &"chain_reaper"
	super._ready()
	if health_component != null:
		health_component.max_health = 3
		health_component.current_health = 3
	if poise_component != null:
		poise_component.max_poise = 50.0
		poise_component.current_poise = 50.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if hook_cooldown > 0.0:
		hook_cooldown -= delta

	if active_hook != null and is_instance_valid(active_hook):
		var vis := get_node_or_null("Visual")
		if vis != null and vis.has_method("set_hook_active"):
			vis.call("set_hook_active", true, active_hook.global_position)
	else:
		active_hook = null
		var vis := get_node_or_null("Visual")
		if vis != null and vis.has_method("set_hook_active"):
			vis.call("set_hook_active", false)

	if hook_cooldown <= 0.0 and active_hook == null and awareness != null and awareness.is_alert:
		var player := get_tree().get_first_node_in_group(&"player") as Node2D
		if player != null and is_instance_valid(player):
			var dist := global_position.distance_to(player.global_position)
			if dist >= 60.0 and dist <= 220.0:
				throw_hook(player.global_position)

func throw_hook(target_pos: Vector2) -> void:
	hook_cooldown = 3.0
	face(1 if target_pos.x > global_position.x else -1)

	var hook: Area2D = HOOK_SCENE.instantiate() as Area2D
	if hook == null:
		return

	hook.global_position = global_position + Vector2(float(facing) * 12.0, -14.0)
	hook.set("direction", (target_pos - global_position).normalized())
	hook.set("reaper", self)
	active_hook = hook

	get_parent().add_child(hook)
	hook_thrown.emit(hook)

	var vis := get_node_or_null("Visual")
	if vis != null and vis.has_method("show_tell"):
		vis.call("show_tell", &"exclamation")

	if NoiseBus != null:
		var ev := NoiseEvent.make(global_position, 120.0, 1.2, NoiseEvent.NoiseType.COMBAT, self)
		NoiseBus.emit_noise(ev)

func on_chain_snapped() -> void:
	chain_snapped.emit()
	if poise_component != null:
		poise_component.damage_poise(60.0, 2.0)
	if state_machine != null and state_machine.states.has(&"Stagger"):
		state_machine.change_state(&"Stagger", {"duration": 2.0})

	var vis := get_node_or_null("Visual")
	if vis != null and vis.has_method("flash"):
		vis.call("flash")
