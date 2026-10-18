class_name ShadowAssassin
extends EnemyBase

## ShadowAssassin
## Cloaked ninja infiltrator (0.08 alpha optical camouflage).
## Revealed by acoustic pulses (PulseRegistry reveal > 0.2) or direct damage.
## Executes a telegraphed blink strike behind the player, parryable with precise timing.

signal blink_strike_started
signal revealed

var is_cloaked: bool = true
var reveal_timer: float = 0.0
var blink_cooldown: float = 0.0
var is_striking: bool = false
var strike_timer: float = 0.0

@onready var strike_hitbox: Area2D = $Hitbox

func _ready() -> void:
	kind = &"shadow_assassin"
	super._ready()
	if health_component != null:
		health_component.max_health = 2
		health_component.current_health = 2
	if poise_component != null:
		poise_component.max_poise = 30.0
		poise_component.current_poise = 30.0
	_set_cloaked(true)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if blink_cooldown > 0.0:
		blink_cooldown -= delta

	# Check acoustic pulse reveal
	if PulseRegistry != null:
		var rev: float = PulseRegistry.reveal_at(global_position)
		if rev >= 0.2:
			reveal(3.5)

	if reveal_timer > 0.0:
		reveal_timer -= delta
		if reveal_timer <= 0.0:
			_set_cloaked(true)

	if is_striking:
		strike_timer -= delta
		if strike_timer <= 0.0:
			_execute_stab()
		return

	# Blink strike behavior when alert
	if blink_cooldown <= 0.0 and awareness != null and awareness.is_alert:
		var player := get_tree().get_first_node_in_group(&"player") as Node2D
		if player != null and is_instance_valid(player):
			var dist := global_position.distance_to(player.global_position)
			if dist <= 200.0:
				_start_blink_strike(player)

func reveal(duration: float = 3.0) -> void:
	reveal_timer = maxf(reveal_timer, duration)
	if is_cloaked:
		_set_cloaked(false)
		revealed.emit()

func _set_cloaked(cloaked: bool) -> void:
	is_cloaked = cloaked
	var vis := get_node_or_null("Visual")
	if vis != null and vis.has_method("set_cloaked"):
		vis.call("set_cloaked", cloaked)

func _start_blink_strike(player: Node2D) -> void:
	blink_cooldown = 4.0
	is_striking = true
	strike_timer = 0.4 # Telegraph window
	blink_strike_started.emit()

	# Reappear 24px behind player
	var p_facing: int = 1
	if "facing" in player:
		p_facing = int(player.get("facing"))
	var behind_x: float = player.global_position.x - float(p_facing) * 24.0
	global_position = Vector2(behind_x, player.global_position.y)
	face(p_facing)

	var vis := get_node_or_null("Visual")
	if vis != null and vis.has_method("show_tell"):
		vis.call("show_tell", &"exclamation")

	if NoiseBus != null:
		var ev := NoiseEvent.make(global_position, 100.0, 1.0, NoiseEvent.NoiseType.COMBAT, self)
		NoiseBus.emit_noise(ev)

func _execute_stab() -> void:
	is_striking = false
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player != null and is_instance_valid(player) and global_position.distance_to(player.global_position) <= 36.0:
		# Attack player
		var hurtbox: Node = player.get_node_or_null("HurtboxComponent")
		if hurtbox != null and hurtbox.has_method("receive_hit"):
			hurtbox.call("receive_hit", strike_hitbox)
		elif player.has_method("die"):
			player.call("die", &"assassinated")

func _on_damaged(amount: int, knockback: Vector2) -> void:
	super._on_damaged(amount, knockback)
	reveal(4.0)
