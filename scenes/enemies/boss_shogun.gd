class_name BossShogun
extends CharacterBody2D

## BossShogun
## Climax Sector 9 Encounter: 18 HP Segments, 200 Poise, 3 Combat Phases.
## Combines Twin Naginata sweeps, arena acoustic shockwaves, Ashigaru summons,
## and blackout Overdrive Ronin flurry per ENEMY_AI.md §3.

signal phase_changed(new_phase: int)
signal boss_defeated
signal shockwave_emitted(pos: Vector2)
signal ashigaru_summoned(count: int)

enum Phase {
	BLADE_MASTER = 1,
	ACOUSTIC_BARRAGE = 2,
	OVERDRIVE_RONIN = 3
}

enum BossAction {
	IDLE,
	TELEGRAPH,
	ATTACKING,
	DASHING,
	STAGGERED,
	DEAD
}

@export var max_health: int = 18
@export var max_poise: float = 200.0

@onready var health_comp: HealthComponent = $HealthComponent
@onready var poise_comp: PoiseComponent = $PoiseComponent
@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var visual: Node2D = $Visual

var current_phase: int = Phase.BLADE_MASTER
var current_action: BossAction = BossAction.IDLE
var action_timer: float = 0.0
var cooldown_timer: float = 1.5
var facing: int = -1
var target_player: CharacterBody2D = null

# Attack execution state
var active_attack_name: StringName = &""
var active_damage: int = 2
var active_reach: float = 120.0
var flurry_strike_count: int = 0
var successful_parry_count: int = 0


func _ready() -> void:
	add_to_group(&"enemies")
	add_to_group(&"boss")
	if EnemyRegistry != null:
		EnemyRegistry.register_enemy(self)

	collision_layer = 8
	collision_mask = 3

	if health_comp != null:
		health_comp.max_health = max_health
		health_comp.current_health = max_health
		if not health_comp.health_changed.is_connected(_on_health_changed):
			health_comp.health_changed.connect(_on_health_changed)
		if not health_comp.died.is_connected(_on_died):
			health_comp.died.connect(_on_died)

	if poise_comp != null:
		poise_comp.max_poise = max_poise
		poise_comp.current_poise = max_poise
		if not poise_comp.staggered.is_connected(_on_staggered):
			poise_comp.staggered.connect(_on_staggered)

	if is_inside_tree() and get_tree() != null:
		target_player = get_tree().get_first_node_in_group(&"player") as CharacterBody2D


func _physics_process(delta: float) -> void:
	if current_action == BossAction.DEAD:
		return

	if target_player == null:
		target_player = get_tree().get_first_node_in_group(&"player") as CharacterBody2D

	# Face towards player
	if target_player != null and current_action != BossAction.ATTACKING:
		facing = 1 if target_player.global_position.x >= global_position.x else -1
		scale.x = absf(scale.x) * float(facing)

	# Action state machine
	match current_action:
		BossAction.IDLE:
			cooldown_timer -= delta
			# Slow repositioning towards player
			if target_player != null:
				var dist: float = global_position.distance_to(target_player.global_position)
				if dist > 140.0:
					velocity.x = float(facing) * (80.0 if current_phase < 3 else 140.0)
				else:
					velocity.x = 0.0
			move_and_slide()

			if cooldown_timer <= 0.0:
				_pick_next_attack()

		BossAction.TELEGRAPH:
			action_timer -= delta
			velocity = Vector2.ZERO
			if action_timer <= 0.0:
				_execute_active_attack()

		BossAction.ATTACKING:
			action_timer -= delta
			if action_timer <= 0.0:
				_finish_attack()

		BossAction.DASHING:
			action_timer -= delta
			move_and_slide()
			if action_timer <= 0.0:
				_finish_attack()

		BossAction.STAGGERED:
			action_timer -= delta
			velocity = Vector2.ZERO
			if action_timer <= 0.0:
				current_action = BossAction.IDLE
				cooldown_timer = 1.0


func _pick_next_attack() -> void:
	match current_phase:
		Phase.BLADE_MASTER:
			if randf() > 0.5:
				_start_telegraph(&"twin_sweep", 0.50, 2, 140.0) # 30f
			else:
				_start_telegraph(&"overhead_cleave", 0.40, 2, 100.0) # 24f

		Phase.ACOUSTIC_BARRAGE:
			var roll: float = randf()
			if roll < 0.45:
				_start_telegraph(&"shockwave", 0.60, 1, 300.0)
			elif roll < 0.75:
				_start_telegraph(&"twin_sweep", 0.45, 2, 140.0)
			else:
				_start_telegraph(&"overhead_cleave", 0.35, 2, 100.0)

		Phase.OVERDRIVE_RONIN:
			if randf() > 0.4:
				_start_telegraph(&"sonic_dash", 0.30, 2, 260.0) # 18f
			else:
				_start_telegraph(&"berserk_flurry", 0.25, 1, 90.0)


func _start_telegraph(atk_name: StringName, telegraph_time: float, dmg: int, reach_val: float) -> void:
	current_action = BossAction.TELEGRAPH
	active_attack_name = atk_name
	action_timer = telegraph_time
	active_damage = dmg
	active_reach = reach_val

	if visual != null:
		visual.show_tell("!")
		visual.flash()

	if NoiseBus != null:
		var ev: NoiseEvent = NoiseEvent.make(global_position, 160.0, 1.2, NoiseEvent.NoiseType.ENEMY, self)
		NoiseBus.emit_noise(ev)


func _execute_active_attack() -> void:
	current_action = BossAction.ATTACKING
	action_timer = 0.25

	if visual != null:
		visual.play_attack(active_attack_name)

	match active_attack_name:
		&"shockwave":
			_emit_acoustic_shockwave()
		&"sonic_dash":
			current_action = BossAction.DASHING
			action_timer = 0.20
			velocity.x = float(facing) * 550.0
			_strike_player()
		&"berserk_flurry":
			flurry_strike_count = 5
			successful_parry_count = 0
			_strike_player()
		_:
			_strike_player()


func _strike_player() -> void:
	if target_player == null:
		return

	var dist: float = global_position.distance_to(target_player.global_position)
	if dist <= active_reach:
		var combat_ctrl = target_player.get_node_or_null("CombatController")
		var defended: bool = false
		if combat_ctrl != null and combat_ctrl.has_method("intercept_hit"):
			# Check parry/guard
			defended = combat_ctrl.intercept_hit(hitbox)
			if defended:
				successful_parry_count += 1
				if active_attack_name == &"berserk_flurry" and successful_parry_count >= 3:
					_on_poise_broken()
					return

		if not defended:
			var player_hurtbox = target_player.get_node_or_null("HurtboxComponent")
			if player_hurtbox != null and player_hurtbox.has_method("receive_hit"):
				player_hurtbox.receive_hit(hitbox)

	if NoiseBus != null:
		var ev: NoiseEvent = NoiseEvent.make(global_position, 320.0, 2.5, NoiseEvent.NoiseType.COMBAT, self)
		NoiseBus.emit_noise(ev)


func _emit_acoustic_shockwave() -> void:
	shockwave_emitted.emit(global_position)
	var profile: PulseProfile = load("res://resources/pulses/pulse_scream.tres") as PulseProfile
	if profile != null and get_parent() != null:
		var bubble_scene: PackedScene = preload("res://scenes/sonar/pulse_bubble.tscn")
		var b: Node2D = bubble_scene.instantiate() as Node2D
		b.set("profile", profile)
		b.set("origin_pos", global_position)
		b.set("source_node", self)
		get_parent().add_child(b)

	if NoiseBus != null:
		var ev: NoiseEvent = NoiseEvent.make(global_position, 560.0, 3.0, NoiseEvent.NoiseType.COMBAT, self)
		NoiseBus.emit_noise(ev)

	_strike_player()


func _finish_attack() -> void:
	current_action = BossAction.IDLE
	velocity = Vector2.ZERO
	cooldown_timer = 1.0 if current_phase < 3 else 0.45


func _on_health_changed(cur: int, _max_hp: int) -> void:
	if current_phase == Phase.BLADE_MASTER and cur <= 12:
		_transition_phase(Phase.ACOUSTIC_BARRAGE)
	elif current_phase == Phase.ACOUSTIC_BARRAGE and cur <= 6:
		_transition_phase(Phase.OVERDRIVE_RONIN)


func _transition_phase(next_phase: Phase) -> void:
	current_phase = next_phase
	phase_changed.emit(int(next_phase))

	if visual != null:
		visual.set_phase(int(next_phase))

	# Phase transition shockwave
	_emit_acoustic_shockwave()

	if next_phase == Phase.ACOUSTIC_BARRAGE:
		_spawn_ashigaru_reinforcements(2)
	elif next_phase == Phase.OVERDRIVE_RONIN:
		if visual != null:
			visual.set_blackout(true)


func _spawn_ashigaru_reinforcements(count: int) -> void:
	ashigaru_summoned.emit(count)
	if get_parent() == null:
		return
	var ash_scene: PackedScene = preload("res://scenes/enemies/ashigaru.tscn")
	for i in range(count):
		var offset_x: float = -140.0 if i == 0 else 140.0
		var ash = ash_scene.instantiate() as Node2D
		ash.global_position = global_position + Vector2(offset_x, 0.0)
		get_parent().add_child(ash)


func _on_staggered(_dur: float = 0.0) -> void:
	_on_poise_broken()


func _on_poise_broken() -> void:
	current_action = BossAction.STAGGERED
	action_timer = 2.5
	if visual != null and visual.has_method("flash"):
		visual.call("flash")
	if HitStop != null and is_inside_tree() and get_tree() != null:
		HitStop.freeze(get_tree(), 0.15)


func _on_died(_cause: StringName) -> void:
	current_action = BossAction.DEAD
	boss_defeated.emit()
	if visual != null and visual.has_method("flash"):
		visual.call("flash")
	# Unlock exit terminal door in level if exists
	if is_inside_tree() and get_tree() != null:
		var exit_node = get_tree().get_first_node_in_group(&"exit")
		if exit_node != null and exit_node.has_method("unlock"):
			exit_node.call("unlock")
