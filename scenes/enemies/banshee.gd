class_name Banshee
extends EnemyBase

## Banshee (Wraith)
## Ethereal specter that floats unhindered through terrain.
## Upon detecting the player, initiates a 1.2s inhalation telegraph.
## If not silenced by a swift strike during this window, unleashes a deafening acoustic scream
## that alerts every hostile in the sector.

signal scream_unleashed
signal silenced

var is_inhaling: bool = false
var inhalation_timer: float = 0.0
var scream_cooldown: float = 0.0

func _ready() -> void:
	kind = &"banshee"
	has_gravity = false
	super._ready()
	if health_component != null:
		health_component.max_health = 1
		health_component.current_health = 1
	if poise_component != null:
		poise_component.max_poise = 10.0
		poise_component.current_poise = 10.0

func _physics_process(delta: float) -> void:
	if has_gravity and not is_on_floor():
		pass # Floating entity

	if scream_cooldown > 0.0:
		scream_cooldown -= delta

	if is_inhaling:
		inhalation_timer -= delta
		if inhalation_timer <= 0.0:
			_execute_scream()
		return

	# Float towards player if aware
	if awareness != null and awareness.is_alert:
		var player := get_tree().get_first_node_in_group(&"player") as Node2D
		if player != null and is_instance_valid(player):
			var to_player := (player.global_position - global_position)
			var dist := to_player.length()

			if dist > 80.0:
				velocity = to_player.normalized() * 50.0
				move_and_slide()

			if scream_cooldown <= 0.0 and dist <= 220.0:
				_start_inhalation()

func _start_inhalation() -> void:
	is_inhaling = true
	inhalation_timer = 1.2
	velocity = Vector2.ZERO
	var vis := get_node_or_null("Visual")
	if vis != null and vis.has_method("start_inhalation"):
		vis.call("start_inhalation")

func _execute_scream() -> void:
	is_inhaling = false
	scream_cooldown = 6.0
	var vis := get_node_or_null("Visual")
	if vis != null and vis.has_method("stop_inhalation"):
		vis.call("stop_inhalation")

	# Emit sector-wide deafening scream
	if NoiseBus != null:
		var ev := NoiseEvent.make(global_position, 800.0, 3.5, NoiseEvent.NoiseType.PULSE, self)
		NoiseBus.emit_noise(ev)

	# Alert all hostiles in sector
	var enemies := get_tree().get_nodes_in_group(&"enemies")
	for e in enemies:
		if is_instance_valid(e) and e != self and e.has_method("_on_heard"):
			var ev := NoiseEvent.make(global_position, 800.0, 3.5, NoiseEvent.NoiseType.PULSE, self)
			e.call("_on_heard", ev, 1.0)

	scream_unleashed.emit()

func _on_damaged(amount: int, knockback: Vector2) -> void:
	if is_inhaling:
		silenced.emit()
		is_inhaling = false
		var vis := get_node_or_null("Visual")
		if vis != null and vis.has_method("stop_inhalation"):
			vis.call("stop_inhalation")
	super._on_damaged(amount, knockback)
