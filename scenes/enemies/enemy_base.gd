class_name EnemyBase
extends CharacterBody2D

## EnemyBase
## Core controller for all adversaries in SIGNAL LOST.
## Integrates:
## - Data-driven EnemyData / EnemyProfile
## - AnimatedSprite2D visual bindings with flip_h facing
## - Floating segmented HP and Poise bar
## - Reactive Combat AI: hit flinch, knockback, poise break, evade backstep, low-HP retreat/enrage, defend, punish
## - Vertical PlatformGraph traversal (jumping up, dropping down ledges, escape jumps)
## - Instant EnemyRegistry death accounting with lingering death animation & fade-out

@export var profile: EnemyProfile
@export var kind: StringName = &"listener"
@export var has_gravity: bool = true

@onready var hearing: HearingComponent = $HearingComponent
@onready var vision: VisionComponent = $VisionComponent
@onready var awareness: Awareness = $Awareness
@onready var memory: NoiseMemory = $NoiseMemory
@onready var state_machine: StateMachine = $StateMachine
@onready var mover: PlatformMover = $PlatformMover
@onready var hitbox: Area2D = $Hitbox
@onready var health_component: HealthComponent = get_node_or_null("HealthComponent")
@onready var poise_component: PoiseComponent = get_node_or_null("PoiseComponent")
@onready var hurtbox_component: HurtboxComponent = get_node_or_null("HurtboxComponent")

var facing: int = 1
var facing_direction: Vector2 = Vector2.ZERO
var last_noise: Dictionary = {}
var last_seen: Vector2 = Vector2.ZERO

var smudge: Node2D = null
var smudge_scene: PackedScene = preload("res://scenes/enemies/smudge.tscn")

var awareness_bar: Node2D = null
var awareness_bar_scene: PackedScene = preload("res://scenes/ui/awareness_bar.tscn")

var noise_reticle: Node2D = null
var world_reticle_scene: PackedScene = preload("res://scenes/ui/world_reticle.tscn")

var floating_hp_bar: FloatingEnemyBar = null

# Reactive Combat AI State Variables
var is_dead: bool = false
var is_enraged: bool = false
var is_evading: bool = false
var evade_cooldown: float = 0.0
var evade_timer: float = 0.0
var retreat_mode: bool = false
var stuck_timer: float = 0.0
var last_pos: Vector2 = Vector2.ZERO

## Optional shared locomotion layer (same physics as the hero). When present the
## Fighter owns gravity + move_and_slide and PlatformMover drives it via intents.
var fighter: Fighter = null
## data/enemies/<kind>.json (locomotion / jump / dash / nav / combat tuning)
var enemy_data: Dictionary = {}

## Emitted when this enemy reacts to a tagged hero noise (land / dash / parry).
signal reacted_to_hero(tag: StringName)
signal executed
signal wall_slammed

# Step 0C interaction state (tuning: data/combat.json)
var _recent_hits: Array[float] = []
var _dodge_ready_at: float = 0.0
var _knock_speed: float = 0.0
var _knock_window: float = 0.0
var _slammed: bool = false
## Real time (s) until which this enemy's melee is live (set by attack states via
## mark_attack_active). A hero slash arriving now is a clash, not damage.
var _attack_live_until: float = -100.0


func _ready() -> void:
	add_to_group(&"enemies")
	if EnemyRegistry != null:
		EnemyRegistry.register_enemy(self)

	fighter = get_node_or_null("Fighter") as Fighter
	if fighter != null:
		_setup_fighter()
	if NoiseBus != null:
		NoiseBus.noise_emitted.connect(_on_bus_noise)

	# Physics Layer 4 (enemy), Mask 1 (world) | 2 (one_way)
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(4, true)
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, true)

	if profile != null:
		if hearing != null: hearing.profile = profile
		if vision != null: vision.profile = profile
		if awareness != null: awareness.profile = profile
		if memory != null: memory.profile = profile

	if hearing != null: hearing.heard.connect(_on_heard)
	if vision != null:
		vision.player_spotted.connect(_on_player_spotted)
		vision.player_lost.connect(_on_player_lost)
	if awareness != null: awareness.awareness_changed.connect(_on_awareness_changed)
	if state_machine != null: state_machine.state_changed.connect(_on_state_changed)
	if hitbox != null: hitbox.body_entered.connect(_on_hitbox_body_entered)

	if health_component != null:
		health_component.damaged.connect(_on_damaged)
		health_component.died.connect(_on_died)
	if poise_component != null:
		poise_component.staggered.connect(_on_staggered)

	# Configure base stats per kind if not provided by profile
	match kind:
		&"kenshi":
			if health_component != null:
				health_component.max_health = 3
				health_component.current_health = 3
			if poise_component != null:
				poise_component.max_poise = 60.0
				poise_component.current_poise = 60.0
		&"yumi":
			if health_component != null:
				health_component.max_health = 1
				health_component.current_health = 1
			if poise_component != null:
				poise_component.max_poise = 20.0
				poise_component.current_poise = 20.0
		&"brute":
			if health_component != null:
				health_component.max_health = 6
				health_component.current_health = 6
			if poise_component != null:
				poise_component.max_poise = 120.0
				poise_component.current_poise = 120.0

	# Setup floating health and poise bar
	floating_hp_bar = FloatingEnemyBar.new()
	floating_hp_bar.name = "FloatingEnemyBar"
	floating_hp_bar.position = Vector2(0.0, float(enemy_data.get("bar_y", -32.0 if kind != &"brute" else -46.0)))
	add_child(floating_hp_bar)
	floating_hp_bar.setup(self)

	call_deferred(&"_setup_sense_ui")


func _setup_fighter() -> void:
	var path: String = "res://data/enemies/%s.json" % String(kind)
	if FileAccess.file_exists(path):
		enemy_data = DataLoader.load_json(path, PackedStringArray(["locomotion"]))
		fighter.stats = FighterStats.new().apply_dict(enemy_data, path)
		if mover != null:
			mover.configure_nav(enemy_data.get("nav", {}))
		_apply_vitals(enemy_data)
		if vision != null:
			vision.close_sense = float(enemy_data.get("close_sense", 80.0 if enemy_data.has("attacks") else 0.0))
	else:
		push_warning("[EnemyBase] %s has a Fighter but no %s; using default stats" % [name, path])
	fighter.landed.connect(func(impact: float) -> void:
		if impact > 300.0:
			ParticlesFactory.spawn_landing_dust(get_parent(), global_position)
	)


## JSON "health" / "poise" for data-driven villains.
func _apply_vitals(d: Dictionary) -> void:
	if d.has("health") and health_component != null:
		health_component.max_health = int(d["health"])
		health_component.current_health = int(d["health"])
	if d.has("poise") and poise_component != null:
		poise_component.max_poise = float(d["poise"])
		poise_component.current_poise = float(d["poise"])


## Velocity change routed through the Fighter when present (keeps one owner of
## body motion). Upward impulses become ballistic launches.
func apply_impulse(v: Vector2, lock: float = 0.0) -> void:
	if fighter != null:
		if v.y < 0.0 and is_on_floor() and lock <= 0.0:
			fighter.launch(v)
		else:
			fighter.apply_knockback(v, lock)
	else:
		velocity = v


func _setup_sense_ui() -> void:
	var sense_layer: Node = get_tree().get_first_node_in_group(&"sense_layer")
	if sense_layer != null:
		smudge = smudge_scene.instantiate() as Node2D
		sense_layer.add_child(smudge)
		smudge.visible = false

		awareness_bar = awareness_bar_scene.instantiate() as Node2D
		sense_layer.add_child(awareness_bar)
		if awareness_bar.has_method("setup"):
			awareness_bar.setup(self)

		noise_reticle = world_reticle_scene.instantiate() as Node2D
		if "reticle_type" in noise_reticle:
			noise_reticle.set("reticle_type", 1) # Type.NOISE_ORIGIN
		if noise_reticle.has_method("deactivate"):
			noise_reticle.deactivate()
		sense_layer.add_child(noise_reticle)


func _exit_tree() -> void:
	if smudge != null and is_instance_valid(smudge): smudge.queue_free()
	if awareness_bar != null and is_instance_valid(awareness_bar): awareness_bar.queue_free()
	if noise_reticle != null and is_instance_valid(noise_reticle): noise_reticle.queue_free()


func face(dir: int) -> void:
	if dir == 0 or is_dead:
		return
	facing = 1 if dir > 0 else -1
	var vis: Node = get_node_or_null("Visual")
	if vis != null:
		if vis.has_method("set_facing"):
			vis.call("set_facing", facing)
		elif vis is Node2D:
			(vis as Node2D).scale.x = float(facing)


func _physics_process(delta: float) -> void:
	if is_dead:
		if fighter != null:
			fighter.intent.clear()
			return
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		if has_gravity and not is_on_floor():
			velocity.y += 1800.0 * delta
		move_and_slide()
		return

	if evade_cooldown > 0.0:
		evade_cooldown -= delta
	if _knock_window > 0.0:
		_knock_window -= delta
		_check_wall_slam()

	if is_evading:
		evade_timer -= delta
		if evade_timer <= 0.0:
			is_evading = false
		if fighter == null:
			move_and_slide()
		return

	if fighter != null:
		# Fighter + PlatformMover handle gravity, movement and anti-stuck.
		if Engine.get_physics_frames() % 8 == 0:
			check_trap_ahead()
		return

	if has_gravity and not is_on_floor():
		var g: float = GameConfig.data.gravity if (GameConfig != null and GameConfig.data != null) else 1800.0
		velocity.y += g * delta

	# Anti-stuck recovery
	if velocity.length() > 5.0 and global_position.distance_to(last_pos) < 2.0:
		stuck_timer += delta
		if stuck_timer >= 3.0:
			stuck_timer = 0.0
			_resolve_stuck_state()
	else:
		stuck_timer = 0.0
		last_pos = global_position

	# Trap awareness check (avoid on patrol, small blunder chance on alert)
	if Engine.get_physics_frames() % 8 == 0:
		check_trap_ahead()


func _resolve_stuck_state() -> void:
	# Jump or pick alternative position if trapped
	if is_on_floor():
		apply_impulse(Vector2(float(-facing) * 120.0, -350.0))
	var mover_node: PlatformMover = get_node_or_null("PlatformMover") as PlatformMover
	if mover_node != null and mover_node.graph != null:
		var alt_point: int = mover_node.graph.nearest_node(global_position + Vector2(float(-facing) * 64.0, 0.0))
		if alt_point != -1 and mover_node.graph.node_positions.has(alt_point):
			mover_node.move_to(mover_node.graph.node_positions[alt_point], profile.run_speed if profile != null else 120.0)


func trigger_smudge() -> void:
	if smudge != null and PulseRegistry != null and PulseRegistry.reveal_at(global_position) <= 0.25:
		smudge.show_at(global_position, self)


func _on_heard(event: NoiseEvent, strength: float) -> void:
	last_noise = {
		"pos": event.position,
		"strength": strength,
		"loudness": event.loudness,
		"type": event.type
	}
	if awareness != null: awareness.on_heard(event, strength)
	if memory != null: memory.push_noise(event, strength)
	if noise_reticle != null: noise_reticle.setup_noise(event.position, self)
	trigger_smudge()


func _on_player_spotted(pos: Vector2) -> void:
	last_seen = pos
	if awareness != null: awareness.on_spotted()


func _on_player_lost() -> void:
	pass


func _on_awareness_changed(new_val: float, _old_val: float) -> void:
	var vis: Node = get_node_or_null("Visual")
	if vis != null and vis.has_method("set_alert"):
		vis.call("set_alert", new_val)


func _on_state_changed(_actor: Node, _from: StringName, to: StringName) -> void:
	var vis: Node = get_node_or_null("Visual")
	if vis != null and vis.has_method("flash"):
		vis.call("flash")

	if to == &"Investigate" or to == &"Search":
		if not last_noise.is_empty() and noise_reticle != null:
			var n_pos: Vector2 = last_noise.get("pos", global_position)
			noise_reticle.setup_noise(n_pos, self)
	elif to != &"Investigate" and to != &"Search":
		if noise_reticle != null:
			noise_reticle.deactivate()


func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	if profile != null and not profile.contact_kills:
		return
	if body != null and body.is_in_group(&"player"):
		if body.has_method("die"):
			body.call("die", &"caught")


func _on_damaged(amount: int, knockback: Vector2) -> void:
	if is_dead:
		return

	var w: Dictionary = CombatTuning.weight(weight_class())
	var armored: bool = is_hyper_armored()
	var kb: Vector2 = knockback * float(w.get("knockback_mult", 1.0))
	if armored:
		kb *= float(w.get("armored_knockback_mult", 0.1))
	if fighter != null:
		apply_impulse(velocity + kb, 0.0 if armored else float(w.get("stagger_lock", 0.2)))
	else:
		velocity += kb
	_arm_wall_slam(kb.x)
	var vis: Node = get_node_or_null("Visual")
	if vis != null:
		if vis.has_method("play_anim"):
			vis.call("play_anim", &"hurt")
		if vis.has_method("flash"):
			vis.call("flash")

	# Flinch interrupts attack wind-up unless hyper-armored (weight class / JSON states)
	if not armored:
		if state_machine != null and state_machine.current != null:
			if state_machine.current.has_method("interrupt"):
				state_machine.current.call("interrupt")

	# Check low HP (<25%) retreat or enrage
	if health_component != null:
		var hp_ratio: float = float(health_component.current_health) / float(health_component.max_health)
		if hp_ratio <= 0.25 and not retreat_mode:
			_trigger_low_hp_behavior()

	_register_hit_for_dodge()

	# Statistical evasion check (chance by type and cooldown)
	if not is_evading and evade_cooldown <= 0.0 and health_component != null and health_component.current_health > 0:
		var chance: float = profile.evade_chance if profile != null else 0.35
		_try_evade()


func _try_evade() -> bool:
	if is_dead or is_evading or evade_cooldown > 0.0:
		return false
	var chance: float = profile.evade_chance if profile != null else 0.35
	if GameState != null and GameState.has_method("get_enemy_evade_chance"):
		chance = GameState.get_enemy_evade_chance()
	if randf() < chance:
		return try_evade()
	return false


func try_evade() -> bool:
	if is_dead or is_evading or evade_cooldown > 0.0:
		return false

	is_evading = true
	evade_timer = 0.22 # ~13 frames
	evade_cooldown = 1.2

	# Backstep opposite to facing
	if fighter != null:
		fighter.apply_knockback(Vector2(float(-facing) * 220.0, -60.0 if is_on_floor() else velocity.y), evade_timer)
	else:
		velocity.x = float(-facing) * 220.0
		if is_on_floor():
			velocity.y = -60.0 # slight side-hop

	# Spawn dust telegraph
	ParticlesFactory.spawn_landing_dust(get_parent(), global_position)

	var vis: Node = get_node_or_null("Visual")
	if vis != null and vis.has_method("play_anim"):
		vis.call("play_anim", &"evade")

	return true


func _trigger_low_hp_behavior() -> void:
	retreat_mode = true
	if kind == &"brute":
		# Enrage: +40% speed and aggressive rush
		is_enraged = true
		if profile != null:
			profile.run_speed *= 1.4
		modulate = Color(1.2, 0.4, 0.4, 1.0)
		var vis: Node = get_node_or_null("Visual")
		if vis != null and vis.has_method("show_tell"):
			vis.call("show_tell", &"exclamation")
	else:
		# Light / Ranged retreat: fall back away from player & call for help
		var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
		if player != null and mover != null:
			var away_dir: float = signf(global_position.x - player.global_position.x)
			if away_dir == 0.0: away_dir = 1.0
			var escape_target := global_position + Vector2(away_dir * 180.0, 0.0)
			mover.move_to(escape_target, (profile.run_speed if profile != null else 120.0) * 1.25)
		
		# Call for help: loud sound alert
		if NoiseBus != null:
			var ev := NoiseEvent.make(global_position, 320.0, 2.5, NoiseEvent.NoiseType.ENEMY, self)
			NoiseBus.emit_noise(ev)


func escape_jump_upward() -> bool:
	if not is_on_floor() or is_dead:
		return false
	# Perform vertical leap to upper platform
	apply_impulse(Vector2(float(-facing) * 140.0, -440.0))
	ParticlesFactory.spawn_landing_dust(get_parent(), global_position)
	return true


func check_trap_ahead() -> bool:
	if is_dead or TrapRegistry == null:
		return false
	if not TrapRegistry.is_hazard_ahead(global_position, float(facing), 64.0):
		return false

	var is_alerted: bool = (awareness != null and awareness.value > 0.5) or retreat_mode
	if is_alerted:
		# Alerted/chasing: 25% chance to blunder blindly in
		if randf() < 0.25:
			return false
		# 75% chance to attempt jump over or evade
		if is_on_floor():
			apply_impulse(Vector2(float(facing) * 140.0, -350.0))
		return true
	else:
		# Normal patrol: avoid known traps by turning around
		face(-facing)
		if mover != null:
			mover.stop()
		return true


func _on_staggered(duration: float) -> void:
	if AttackTokenManager != null:
		AttackTokenManager.release_token(self)
	var vis: Node = get_node_or_null("Visual")
	if vis != null and vis.has_method("play_anim"):
		vis.call("play_anim", &"stun")
	if state_machine != null and state_machine.states.has(&"Stagger"):
		state_machine.change_state(&"Stagger", {"duration": duration})


func intercept_hit(hitbox_area: Area2D) -> bool:
	if is_dead:
		return false

	# Weapon clash, enemy side: our melee is live while the katana arrives.
	if _is_hero_attack(hitbox_area) and float(Time.get_ticks_msec()) / 1000.0 <= _attack_live_until:
		var hero_combat: Node = hitbox_area.get_parent().get_node_or_null("CombatController")
		if hero_combat != null and hero_combat.has_method("clash_with"):
			_attack_live_until = -100.0
			hero_combat.call("clash_with", self)
			return true

	# Execution: a staggered enemy struck by the hero is finished hard.
	if poise_component != null and poise_component.is_staggered and _is_hero_attack(hitbox_area):
		_execute_finisher(hitbox_area)
		return true

	if is_in_group(&"brute") or _shield_raised():
		var facing_dir: float = float(facing)
		var is_frontal: bool = (hitbox_area.global_position.x - global_position.x) * facing_dir >= -6.0
		if is_frontal:
			var is_penetrating: bool = false
			if hitbox_area.has_meta(&"is_heavy") and bool(hitbox_area.get_meta(&"is_heavy")):
				is_penetrating = true
			var p_dmg: float = float(hitbox_area.get("poise_damage")) if hitbox_area.get("poise_damage") != null else 0.0
			if p_dmg >= 50.0:
				is_penetrating = true

			if not is_penetrating:
				var vis: Node = get_node_or_null("Visual")
				if vis != null and vis.has_method("flash"):
					vis.call("flash")
				if enemy_data.has("manifest"):
					ManifestFx.spawn(get_parent(), String(enemy_data["manifest"]), &"guard_spark",
							global_position + Vector2(facing_dir * 12.0, -14.0), facing, 0.25)
					if AudioManager != null:
						AudioManager.play_sfx(&"sfx_blade_clash", global_position, 1.2)
				if NoiseBus != null:
					var ev := NoiseEvent.make(global_position, 120.0, 1.2, NoiseEvent.NoiseType.COMBAT, self)
					NoiseBus.emit_noise(ev)
				return true

	var sm: StateMachine = state_machine
	if sm == null: sm = get_node_or_null("StateMachine") as StateMachine
	if sm != null and sm.current != null and sm.current.has_method("intercept_hit"):
		return bool(sm.current.call("intercept_hit", hitbox_area))
	return false


## JSON "frontal_guard": a shield blocks frontal light hits except mid-attack.
func _shield_raised() -> bool:
	if not bool(enemy_data.get("frontal_guard", false)):
		return false
	return state_machine == null or state_machine.current == null or state_machine.current.name != &"Attack"


# --- Step 0C: weight classes, execution, dodge, wall slam, noise reactions ---

## Attack states call this when their hit window opens (melee only).
func mark_attack_active(duration: float) -> void:
	var window: float = float(CombatTuning.combat("clash").get("window_frames", 4)) / 60.0
	_attack_live_until = float(Time.get_ticks_msec()) / 1000.0 + duration + window


func weight_class() -> StringName:
	if enemy_data.has("weight_class"):
		return StringName(str(enemy_data["weight_class"]))
	return StringName(str(CombatTuning.combat("legacy_weight").get(String(kind), "medium")))


func is_hyper_armored() -> bool:
	var always: Variant = DataLoader.load_json(CombatTuning.COMBAT_JSON).get("legacy_hyper_armor_always", [])
	if always is Array and (always as Array).has(String(kind)):
		return true
	match String(CombatTuning.weight(weight_class()).get("hyper_armor", "never")):
		"always":
			return true
		"states":
			var states: Array = enemy_data.get("hyper_armor_states", [])
			return state_machine != null and state_machine.current != null and states.has(String(state_machine.current.name))
	return false


func _is_hero_attack(hitbox_area: Area2D) -> bool:
	if hitbox_area == null or hitbox_area is Projectile:
		return false
	var p: Node = hitbox_area.get_parent()
	return p != null and p.is_in_group(&"player")


func _execute_finisher(hitbox_area: Area2D) -> void:
	var cfg: Dictionary = CombatTuning.combat("execution")
	var base: int = int(hitbox_area.get("damage")) if hitbox_area.get("damage") != null else 1
	var dmg: int = int(round(float(base) * float(cfg.get("damage_mult", 2.0)))) + int(cfg.get("bonus_damage", 2))
	var dir: float = signf(global_position.x - hitbox_area.global_position.x)
	var info: DamageInfo = DamageInfo.make(dmg, hitbox_area.get_parent(), DamageInfo.Faction.PLAYER,
			Vector2((dir if dir != 0.0 else 1.0) * 260.0, -60.0), &"execution")
	info.hitstop_ms = int(cfg.get("hitstop_ms", 140))
	info.shake = float(cfg.get("shake", 0.55))
	info.apply_to(self)
	for i in int(cfg.get("burst_count", 3)):
		ParticlesFactory.spawn_blood_splat(get_parent(), global_position + Vector2(randf_range(-10.0, 10.0), randf_range(-24.0, 0.0)))
	ParticlesFactory.spawn_sprite_hit_spark(get_parent(), global_position + Vector2(0.0, -12.0))
	if NoiseBus != null:
		NoiseBus.emit_action(hitbox_area.get_parent(), global_position, &"execution")
	executed.emit()


func _arm_wall_slam(knock_vx: float) -> void:
	_knock_speed = absf(knock_vx)
	_knock_window = 0.35
	_slammed = false


func _check_wall_slam() -> void:
	if _slammed or is_dead or not is_on_wall():
		return
	var cfg: Dictionary = CombatTuning.combat("wall_slam")
	if _knock_speed < float(cfg.get("min_speed", 180.0)):
		return
	_slammed = true
	var info: DamageInfo = DamageInfo.make(int(cfg.get("bonus_damage", 1)), self, DamageInfo.Faction.NEUTRAL, Vector2.ZERO, &"wall_slam")
	info.hitstop_ms = int(cfg.get("hitstop_ms", 80))
	info.shake = float(cfg.get("shake", 0.35))
	info.apply_to(self)
	ParticlesFactory.spawn_landing_dust(get_parent(), global_position)
	ParticlesFactory.spawn_hit_spark(get_parent(), global_position + Vector2(float(-facing) * 8.0, -8.0))
	if NoiseBus != null:
		NoiseBus.emit_action(self, global_position, &"wall_slam", NoiseEvent.NoiseType.IMPACT)
	wall_slammed.emit()


func _register_hit_for_dodge() -> void:
	var cfg: Dictionary = CombatTuning.combat("dodge")
	var now: float = float(Time.get_ticks_msec()) / 1000.0
	_recent_hits.append(now)
	var window: float = float(cfg.get("window", 1.2))
	while not _recent_hits.is_empty() and now - _recent_hits[0] > window:
		_recent_hits.remove_at(0)
	if _recent_hits.size() >= int(cfg.get("hits_to_trigger", 2)) and now >= _dodge_ready_at and randf() < float(cfg.get("chance", 0.45)):
		_dodge_ready_at = now + float(cfg.get("cooldown", 2.0))
		_recent_hits.clear()
		dodge_away()


## Dash away from the hero (Fighter enemies) or backstep (legacy enemies).
func dodge_away() -> bool:
	if is_dead or (health_component != null and not health_component.is_alive()):
		return false
	var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	var away: int = -facing
	if player != null:
		away = 1 if global_position.x >= player.global_position.x else -1
	if fighter != null:
		fighter.facing = away
		if fighter.request_dash(true):
			var vis: Node = get_node_or_null("Visual")
			if vis != null and vis.has_method("play_anim"):
				vis.call("play_anim", &"evade")
			return true
		return false
	face(-away)
	evade_cooldown = 0.0
	return try_evade()


func _on_bus_noise(event: NoiseEvent) -> void:
	if is_dead or event == null or event.tag == &"" or event.source == null or not event.source.is_in_group(&"player"):
		return
	var r: Dictionary = CombatTuning.reaction(event.tag)
	if r.is_empty() or not is_inside_tree():
		return
	if global_position.distance_to(event.position) > float(r.get("max_distance", 0.0)):
		return
	if poise_component != null and poise_component.is_staggered:
		return
	# Walls block the reaction (same rule hearing uses).
	var q := PhysicsRayQueryParameters2D.create(global_position + Vector2(0.0, -8.0), event.position + Vector2(0.0, -8.0), 1)
	if not get_world_2d().direct_space_state.intersect_ray(q).is_empty():
		return
	var toward: int = 1 if event.position.x >= global_position.x else -1
	if bool(r.get("face", false)):
		face(toward)
	match event.tag:
		&"dash":
			if randf() < float(r.get("dodge_chance", 0.0)):
				dodge_away()
		&"parry":
			# The hero just turned a blow aside: hesitate and give ground.
			if AttackTokenManager != null:
				AttackTokenManager.release_token(self)
			if mover != null:
				mover.stop()
			apply_impulse(Vector2(float(-toward) * float(r.get("backoff", 120.0)), 0.0), float(r.get("hesitate", 0.35)))
	reacted_to_hero.emit(event.tag)


func _on_died(_cause: StringName) -> void:
	if is_dead:
		return
	is_dead = true

	if AttackTokenManager != null:
		AttackTokenManager.release_token(self)

	# A corpse never thinks again: no late swings or shots from a mid-attack state.
	if state_machine != null:
		if state_machine.current != null:
			state_machine.current.exit()
		state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	if mover != null:
		mover.stop()

	# Disable collision layers so corpse does not obstruct player or pathfinding
	collision_layer = 0
	collision_mask = 1 # only collide with world to stay on ground
	if hitbox != null:
		hitbox.monitoring = false
		hitbox.monitorable = false
	if hurtbox_component != null:
		hurtbox_component.monitoring = false
		hurtbox_component.monitorable = false

	# Play die animation
	var vis: Node = get_node_or_null("Visual")
	if vis != null:
		if vis.has_method("play_anim"):
			vis.call("play_anim", &"die")
		elif vis.has_method("flash"):
			vis.call("flash")

	# Linger briefly (1.0s) then fade out with tween before freeing
	var t := create_tween()
	t.tween_interval(1.0)
	t.tween_property(self, "modulate:a", 0.0, 0.4)
	t.tween_callback(queue_free)
