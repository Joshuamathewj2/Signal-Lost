class_name Drone
extends EnemyBase

## Drone
## Airborne patrol unit that hovers smoothly without gravity.
## Charges a high-powered laser beam (0.6s red telegraph sightline) when targeting the player.
## Fragile core: 1 shuriken hit destroys it instantly.
## Laser bolt is frame-tight deflectable via parry back into the drone.

signal laser_fired(projectile: Node)

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/enemies/projectile.tscn")

var is_charging: bool = false
var charge_timer: float = 0.0
var attack_cooldown: float = 0.0
var patrol_dir: int = 1
var start_y: float = 0.0

func _ready() -> void:
	kind = &"drone"
	has_gravity = false
	super._ready()
	start_y = global_position.y
	if health_component != null:
		health_component.max_health = 1
		health_component.current_health = 1
	if poise_component != null:
		poise_component.max_poise = 20.0
		poise_component.current_poise = 20.0

func _physics_process(delta: float) -> void:
	if has_gravity and not is_on_floor():
		pass # Overridden: no gravity

	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	var player := get_tree().get_first_node_in_group(&"player") as Node2D

	if is_charging:
		charge_timer -= delta
		if player != null and is_instance_valid(player):
			var vis := get_node_or_null("Visual")
			if vis != null and vis.has_method("start_telegraph"):
				vis.call("start_telegraph", player.global_position)
		if charge_timer <= 0.0:
			_fire_laser()
		return

	if awareness != null and awareness.is_alert and player != null and is_instance_valid(player):
		var target_pos := player.global_position + Vector2(0, -32.0)
		var to_target := target_pos - global_position
		var dist := to_target.length()

		face(1 if to_target.x > 0 else -1)

		# Approach or maintain distance
		if dist > 140.0:
			velocity = to_target.normalized() * 80.0
		elif dist < 80.0:
			velocity = -to_target.normalized() * 60.0
		else:
			velocity = Vector2.ZERO

		move_and_slide()

		if attack_cooldown <= 0.0 and dist <= 240.0:
			_start_charging(player.global_position)
	else:
		# Slow airborne patrol drift
		velocity.x = float(patrol_dir) * 40.0
		velocity.y = (start_y - global_position.y) * 1.5
		move_and_slide()
		if is_on_wall():
			patrol_dir = -patrol_dir
			face(patrol_dir)

func _start_charging(target_global: Vector2) -> void:
	is_charging = true
	charge_timer = 0.6
	velocity = Vector2.ZERO
	var vis := get_node_or_null("Visual")
	if vis != null and vis.has_method("start_telegraph"):
		vis.call("start_telegraph", target_global)

func _fire_laser() -> void:
	is_charging = false
	attack_cooldown = 2.0
	var vis := get_node_or_null("Visual")
	if vis != null and vis.has_method("stop_telegraph"):
		vis.call("stop_telegraph")

	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	var target_pos := player.global_position if (player != null and is_instance_valid(player)) else (global_position + Vector2(float(facing) * 100, 0))

	var proj := PROJECTILE_SCENE.instantiate() as Projectile
	if proj != null:
		proj.global_position = global_position
		proj.direction = (target_pos - global_position).normalized()
		proj.source_turret = self
		proj.speed = 520.0
		get_parent().add_child(proj)
		laser_fired.emit(proj)

	if NoiseBus != null:
		var ev := NoiseEvent.make(global_position, 160.0, 1.4, NoiseEvent.NoiseType.COMBAT, self)
		NoiseBus.emit_noise(ev)
