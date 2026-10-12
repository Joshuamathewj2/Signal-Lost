class_name CombatController
extends Node

## CombatController
## Coordinates player melee combos, parry deflect windows, sustained guard,
## and invulnerable dash rolls per COMBAT_DESIGN.md and COMBAT_FRAME_DATA.md.

signal combo_changed(combo_index: int)
signal parry_success(attacker: Node)
signal guard_state_changed(is_guarding: bool)
signal dash_started

enum CombatState {
	IDLE,
	ATTACKING,
	PARRYING,
	GUARDING,
	DASHING
}

@export var player: CharacterBody2D
@export var motor: PlayerMotor
@export var health_comp: HealthComponent
@export var poise_comp: PoiseComponent
@export var hitbox: HitboxComponent
@export var weapon_swap_mgr: WeaponSwapManager
@export var assassination_sys: AssassinationSystem

var current_state: CombatState = CombatState.IDLE
var current_combo: int = 0
var combo_buffer: bool = false
var combo_timer: float = 0.0

var attack_timer: float = 0.0
var current_attack_data: AttackData = null

var parry_timer: float = 0.0
const PARRY_WINDOW: float = 0.10 # 6 frames at 60 FPS

var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
const DASH_DURATION: float = 0.25
const DASH_SPEED: float = 400.0
const DASH_COOLDOWN: float = 0.50

var attack_1_data: AttackData
var attack_2_data: AttackData
var attack_3_data: AttackData


func _ready() -> void:
	if player == null:
		player = get_parent() as CharacterBody2D
	if weapon_swap_mgr == null and player != null:
		weapon_swap_mgr = player.get_node_or_null("WeaponSwapManager")
	if assassination_sys == null and player != null:
		assassination_sys = player.get_node_or_null("AssassinationSystem")
	_init_attacks()


func _init_attacks() -> void:
	attack_1_data = AttackData.new()
	attack_1_data.attack_name = &"katana_slash_1"
	attack_1_data.damage = 1
	attack_1_data.poise_damage = 15.0
	attack_1_data.knockback_force = 120.0
	attack_1_data.hitstop_duration = 0.06
	attack_1_data.noise_radius = 180.0
	attack_1_data.noise_loudness = 1.5
	attack_1_data.startup_frames = 6
	attack_1_data.active_frames = 3
	attack_1_data.recovery_frames = 12

	attack_2_data = AttackData.new()
	attack_2_data.attack_name = &"katana_slash_2"
	attack_2_data.damage = 1
	attack_2_data.poise_damage = 15.0
	attack_2_data.knockback_force = 150.0
	attack_2_data.hitstop_duration = 0.06
	attack_2_data.noise_radius = 200.0
	attack_2_data.noise_loudness = 1.8
	attack_2_data.startup_frames = 5
	attack_2_data.active_frames = 3
	attack_2_data.recovery_frames = 14

	attack_3_data = AttackData.new()
	attack_3_data.attack_name = &"katana_slash_3"
	attack_3_data.damage = 2
	attack_3_data.poise_damage = 30.0
	attack_3_data.knockback_force = 320.0
	attack_3_data.hitstop_duration = 0.10
	attack_3_data.noise_radius = 280.0
	attack_3_data.noise_loudness = 2.5
	attack_3_data.startup_frames = 9
	attack_3_data.active_frames = 4
	attack_3_data.recovery_frames = 20


func _unhandled_input(event: InputEvent) -> void:
	if player != null and not player.get("is_alive"):
		return

	if event.is_action_pressed(&"attack"):
		handle_attack_input()
	elif event.is_action_pressed(&"attack_heavy"):
		handle_heavy_attack_input()
	elif event.is_action_pressed(&"ability_primary"):
		throw_shuriken()
	elif event.is_action_pressed(&"dash"):
		handle_dash_input()
	elif event.is_action_pressed(&"block_parry"):
		start_parry()
	elif event.is_action_released(&"block_parry"):
		stop_guard()


func _physics_process(delta: float) -> void:
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0 and current_state == CombatState.IDLE:
			current_combo = 0

	match current_state:
		CombatState.ATTACKING:
			_process_attack(delta)
		CombatState.PARRYING:
			parry_timer -= delta
			if parry_timer <= 0.0:
				if Input.is_action_pressed(&"block_parry"):
					current_state = CombatState.GUARDING
					guard_state_changed.emit(true)
				else:
					current_state = CombatState.IDLE
		CombatState.GUARDING:
			if not Input.is_action_pressed(&"block_parry"):
				stop_guard()
		CombatState.DASHING:
			_process_dash(delta)


func _get_active_weapon_type() -> int:
	if weapon_swap_mgr != null:
		return int(weapon_swap_mgr.current_weapon)
	return 0 # KATANA


func _get_max_combo_steps() -> int:
	match _get_active_weapon_type():
		1: return 2 # NAGINATA
		2: return 4 # KUNAI
		_: return 3 # KATANA


func handle_attack_input() -> void:
	if current_state == CombatState.IDLE:
		if assassination_sys != null and player != null:
			var target: Node2D = _find_assassination_target()
			if target != null and assassination_sys.execute(player, target):
				return
		start_combo_strike(1)
	elif current_state == CombatState.ATTACKING:
		combo_buffer = true


func handle_heavy_attack_input() -> void:
	if current_state != CombatState.IDLE:
		return

	current_state = CombatState.ATTACKING
	current_combo = 0
	combo_buffer = false

	var w_type: int = _get_active_weapon_type()
	match w_type:
		1:
			current_attack_data = WeaponNaginata.get_heavy_attack_data()
		2:
			current_attack_data = WeaponKunai.get_heavy_attack_data()
		_:
			current_attack_data = AttackData.new()
			current_attack_data.attack_name = &"katana_heavy_iai"
			current_attack_data.damage = 2
			current_attack_data.poise_damage = 45.0
			current_attack_data.knockback_force = 380.0
			current_attack_data.hitstop_duration = 0.12
			current_attack_data.noise_radius = 300.0
			current_attack_data.noise_loudness = 2.6
			current_attack_data.startup_frames = 14
			current_attack_data.active_frames = 4
			current_attack_data.recovery_frames = 24

	attack_timer = current_attack_data.total_duration_sec()

	if NoiseBus != null and player != null:
		var ev: NoiseEvent = NoiseEvent.make(
			player.global_position,
			current_attack_data.noise_radius,
			current_attack_data.noise_loudness,
			NoiseEvent.NoiseType.COMBAT,
			player
		)
		NoiseBus.emit_noise(ev)

	_configure_hitbox(current_attack_data)


func throw_shuriken() -> void:
	if player == null or not is_inside_tree():
		return

	var facing_dir: float = 1.0
	if motor != null:
		facing_dir = float(motor.facing)

	var shuriken := Shuriken.new()
	shuriken.global_position = player.global_position + Vector2(facing_dir * 16.0, 0.0)
	shuriken.direction = Vector2(facing_dir, 0.0)
	player.get_parent().add_child(shuriken)


func _find_assassination_target() -> Node2D:
	if player == null or not is_inside_tree():
		return null
	var enemies: Array[Node] = get_tree().get_nodes_in_group(&"enemies")
	for e in enemies:
		if e is Node2D and AssassinationSystem.can_assassinate(player, e as Node2D):
			return e as Node2D
	return null


func handle_dash_input() -> void:
	if dash_cooldown_timer > 0.0 or current_state == CombatState.DASHING:
		return
	if current_state == CombatState.ATTACKING and hitbox != null:
		hitbox.deactivate()

	current_state = CombatState.DASHING
	dash_timer = DASH_DURATION
	dash_cooldown_timer = DASH_COOLDOWN

	if health_comp != null:
		health_comp.start_invulnerability(0.20) # 12 i-frames at 60 FPS

	if NoiseBus != null and player != null:
		var ev: NoiseEvent = NoiseEvent.make(player.global_position, 60.0, 0.4, NoiseEvent.NoiseType.FOOTSTEP, player)
		NoiseBus.emit_noise(ev)

	dash_started.emit()


func start_combo_strike(step: int) -> void:
	current_combo = step
	current_state = CombatState.ATTACKING
	combo_buffer = false

	var w_type: int = _get_active_weapon_type()
	match w_type:
		1:
			current_attack_data = WeaponNaginata.get_attack_data(step - 1)
		2:
			current_attack_data = WeaponKunai.get_attack_data(step - 1)
		_:
			match step:
				1: current_attack_data = attack_1_data
				2: current_attack_data = attack_2_data
				3: current_attack_data = attack_3_data
				_: current_attack_data = attack_1_data

	attack_timer = current_attack_data.total_duration_sec()
	combo_timer = 0.35

	if NoiseBus != null and player != null:
		var ev: NoiseEvent = NoiseEvent.make(
			player.global_position,
			current_attack_data.noise_radius,
			current_attack_data.noise_loudness,
			NoiseEvent.NoiseType.COMBAT,
			player
		)
		NoiseBus.emit_noise(ev)

	_configure_hitbox(current_attack_data)
	combo_changed.emit(current_combo)


func _configure_hitbox(atk: AttackData) -> void:
	if hitbox == null:
		return
	hitbox.damage = atk.damage
	hitbox.poise_damage = atk.poise_damage
	hitbox.knockback_force = atk.knockback_force
	hitbox.hitstop_duration = atk.hitstop_duration
	hitbox.attack_data = atk
	hitbox.set_meta(&"weapon_type", _get_active_weapon_type())
	hitbox.set_meta(&"is_heavy", atk.poise_damage >= 50.0 or str(atk.attack_name).contains("heavy"))

	var facing_dir: float = 1.0
	if motor != null:
		facing_dir = float(motor.facing)
	hitbox.position = Vector2(facing_dir * atk.reach * 0.5, 0.0)


func _process_attack(delta: float) -> void:
	attack_timer -= delta
	if current_attack_data == null:
		current_state = CombatState.IDLE
		return

	var elapsed: float = current_attack_data.total_duration_sec() - attack_timer
	var s_time: float = current_attack_data.startup_duration_sec()
	var a_time: float = s_time + current_attack_data.active_duration_sec()

	if hitbox != null:
		if elapsed >= s_time and elapsed < a_time:
			if not hitbox.is_active:
				hitbox.activate()
		else:
			if hitbox.is_active:
				hitbox.deactivate()

	if attack_timer <= 0.0:
		if hitbox != null:
			hitbox.deactivate()
		var max_steps: int = _get_max_combo_steps()
		if combo_buffer and current_combo < max_steps:
			start_combo_strike(current_combo + 1)
		else:
			current_state = CombatState.IDLE
			if current_combo >= max_steps:
				current_combo = 0


func _process_dash(delta: float) -> void:
	dash_timer -= delta
	if player != null and motor != null:
		player.velocity.x = float(motor.facing) * DASH_SPEED
	if dash_timer <= 0.0:
		current_state = CombatState.IDLE


func start_parry() -> void:
	if current_state == CombatState.DASHING:
		return
	if current_state == CombatState.ATTACKING and hitbox != null:
		hitbox.deactivate()

	current_state = CombatState.PARRYING
	parry_timer = PARRY_WINDOW


func stop_guard() -> void:
	if current_state == CombatState.GUARDING:
		current_state = CombatState.IDLE
		guard_state_changed.emit(false)


## Intercepts an incoming hostile strike.
## Returns true if deflected or absorbed by guard.
func intercept_hit(hostile_hitbox: Area2D) -> bool:
	if current_state == CombatState.PARRYING:
		_execute_parry_deflect(hostile_hitbox)
		return true
	elif current_state == CombatState.GUARDING:
		_execute_guard_absorption(hostile_hitbox)
		return true
	return false


func _execute_parry_deflect(hostile_hitbox: Area2D) -> void:
	if health_comp != null:
		health_comp.start_invulnerability(0.266) # 16 i-frames

	var attacker: Node = hostile_hitbox.get_parent()
	if attacker != null:
		var hostile_poise: Node = attacker.get_node_or_null("PoiseComponent")
		if hostile_poise == null:
			for c in attacker.get_children():
				if c is PoiseComponent or c.get_script() == PoiseComponent:
					hostile_poise = c
					break
		if hostile_poise != null and hostile_poise.has_method("damage_poise"):
			hostile_poise.damage_poise(40.0)

	# Deflect projectile if parried strike is a ranged projectile
	if hostile_hitbox != null and hostile_hitbox.has_method("deflect"):
		hostile_hitbox.call("deflect", player)
	elif hostile_hitbox != null and hostile_hitbox.get_parent() != null and hostile_hitbox.get_parent().has_method("deflect"):
		hostile_hitbox.get_parent().call("deflect", player)

	if is_inside_tree() and get_tree() != null:
		HitStop.freeze(get_tree(), 0.12)

	if NoiseBus != null and player != null:
		var ev: NoiseEvent = NoiseEvent.make(player.global_position, 260.0, 2.2, NoiseEvent.NoiseType.COMBAT, player)
		NoiseBus.emit_noise(ev)

	parry_success.emit(attacker)


func _execute_guard_absorption(hostile_hitbox: Area2D) -> void:
	var incoming_dmg: int = int(hostile_hitbox.get("damage")) if hostile_hitbox.get("damage") != null else 1
	var poise_dmg: float = float(hostile_hitbox.get("poise_damage")) if hostile_hitbox.get("poise_damage") != null else 20.0

	var chip_dmg: int = maxi(1, int(float(incoming_dmg) * 0.3))
	if health_comp != null:
		health_comp.take_damage(chip_dmg, Vector2.ZERO, &"chip")

	if poise_comp != null:
		poise_comp.damage_poise(poise_dmg)

	if is_inside_tree() and get_tree() != null:
		HitStop.freeze(get_tree(), 0.06)
