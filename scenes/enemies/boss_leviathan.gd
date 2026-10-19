class_name BossLeviathan
extends CharacterBody2D

## BossLeviathan
## Chapter II finale (data/manifests/boss_leviathan.json art).
## 24 HP, 260 poise, three phases split at 66% / 33% health:
##   1 WARDEN OF THE DEEP  overhead slam (+ shockwave), wide sweep, telegraphed dash
##   2 FRACTURE            + leaping slam that cracks the floor, energy pillars under the hero
##   3 ENRAGED             faster tells, shadow-clone dashes from both walls, sword rain
## Every attack has a >= 0.4 s red wind-up. Breaking poise staggers it for 2 s
## and hits taken while staggered deal double damage. Groups enemies + boss and
## the boss_defeated signal hook it into BossHealthBar / EnemyRegistry.

signal phase_changed(new_phase: int)
signal boss_defeated

enum Action { INTRO, IDLE, TELEGRAPH, ACTIVE, RECOVER, AIRBORNE, STAGGERED, TRANSITION, DEAD }

const UNIT: String = "boss_leviathan"
const GRAVITY: float = 1800.0
const SWORD_SCENE: PackedScene = preload("res://scenes/enemies/manifest_projectile.tscn")

@export var max_health: int = 24
@export var max_poise: float = 260.0
@export var intro_time: float = 1.6

@onready var health_comp: HealthComponent = $HealthComponent
@onready var poise_comp: PoiseComponent = $PoiseComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var hitbox: VillainHitbox = $Hitbox
@onready var visual: Node2D = $Visual

var sprite: ManifestSprite = null
var phase: int = 1
var action: Action = Action.INTRO
var timer: float = 0.0
var cooldown: float = 0.8
var facing: int = -1
var attack: Dictionary = {}
var _hit_done: bool = false
var _was_airborne: bool = false
var _last_attack: String = ""

## name -> attack spec. phase = first phase it is available in.
var ATTACKS: Dictionary = {
	"slam": {"phase": 1, "anim_tell": "windup", "anim": "slam", "telegraph": 0.80, "active": 0.20, "recovery": 0.80,
		"range": 80.0, "reach": 76.0, "damage": 2, "poise": 55.0, "knockback": 320.0, "radius": 120.0, "weight": 3},
	"sweep": {"phase": 1, "anim_tell": "windup", "anim": "sweep", "telegraph": 0.60, "active": 0.25, "recovery": 0.70,
		"range": 100.0, "reach": 96.0, "damage": 2, "poise": 40.0, "knockback": 280.0, "weight": 3},
	"dash": {"phase": 1, "anim_tell": "windup", "anim": "dash", "telegraph": 0.60, "active": 0.40, "recovery": 0.70,
		"range": 420.0, "min_range": 110.0, "reach": 34.0, "damage": 2, "poise": 40.0, "knockback": 300.0,
		"speed": 520.0, "weight": 2},
	"jump_slam": {"phase": 2, "anim_tell": "windup", "anim": "jump", "telegraph": 0.55, "active": 0.0, "recovery": 0.90,
		"range": 520.0, "min_range": 60.0, "reach": 60.0, "damage": 2, "poise": 50.0, "knockback": 340.0,
		"radius": 150.0, "weight": 3},
	"pillars": {"phase": 2, "anim_tell": "phase_transition", "anim": "slam", "telegraph": 0.50, "active": 0.30,
		"recovery": 0.60, "range": 600.0, "count": 3, "spacing": 54.0, "delay": 0.85, "weight": 2},
	"clones": {"phase": 3, "anim_tell": "enraged", "anim": "clone", "telegraph": 0.55, "active": 0.40, "recovery": 0.90,
		"range": 900.0, "speed": 470.0, "weight": 2},
	"sword_rain": {"phase": 3, "anim_tell": "enraged", "anim": "windup", "telegraph": 0.50, "active": 0.60,
		"recovery": 0.80, "range": 900.0, "count": 5, "spacing": 44.0, "weight": 2},
}


func _ready() -> void:
	add_to_group(&"enemies")
	add_to_group(&"boss")
	if EnemyRegistry != null:
		EnemyRegistry.register_enemy(self)
	collision_layer = 8
	collision_mask = 3

	health_comp.max_health = max_health
	health_comp.current_health = max_health
	health_comp.invulnerability_duration = 0.0
	health_comp.health_changed.connect(_on_health_changed)
	health_comp.died.connect(_on_died)
	health_comp.damaged.connect(_on_damaged)
	poise_comp.max_poise = max_poise
	poise_comp.current_poise = max_poise
	poise_comp.staggered.connect(_on_staggered)

	sprite = ManifestSprite.new()
	visual.add_child(sprite)
	sprite.unit = UNIT
	var cs: CollisionShape2D = $CollisionShape2D
	sprite.set_anchor_position(Vector2(0.0, cs.position.y + cs.shape.get_rect().end.y))
	sprite.set_facing(facing)
	sprite.play_anim(&"phase_transition")
	timer = intro_time


func _player() -> Node2D:
	return get_tree().get_first_node_in_group(&"player") as Node2D


func _physics_process(delta: float) -> void:
	if action == Action.DEAD:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		_apply_gravity(delta)
		move_and_slide()
		return
	timer -= delta
	var p: Node2D = _player()

	match action:
		Action.INTRO:
			velocity.x = 0.0
			if timer <= 0.0:
				_roar()
				_enter_idle(0.6)
		Action.IDLE:
			_idle_move(p, delta)
			cooldown -= delta
			if cooldown <= 0.0 and p != null:
				_choose_attack(p)
		Action.TELEGRAPH:
			velocity.x = move_toward(velocity.x, 0.0, 1600.0 * delta)
			if p != null and String(attack.get("name", "")) != "dash":
				_face_toward(p.global_position.x)
			if timer <= 0.0:
				_begin_active(p)
		Action.ACTIVE:
			_update_active(p)
			if timer <= 0.0:
				_begin_recover()
		Action.AIRBORNE:
			if not is_on_floor():
				_was_airborne = true
			elif _was_airborne:
				_land_slam()
		Action.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 1600.0 * delta)
			if timer <= 0.0:
				_enter_idle(_cooldown_for_phase())
		Action.STAGGERED, Action.TRANSITION:
			velocity.x = move_toward(velocity.x, 0.0, 1600.0 * delta)
			if timer <= 0.0:
				hurtbox.is_invulnerable = false
				sprite.play_anim(&"enraged" if phase == 3 else &"idle")
				_enter_idle(0.5)

	_apply_gravity(delta)
	move_and_slide()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, 900.0)


func _cooldown_for_phase() -> float:
	return [0.0, 1.0, 0.75, 0.45][phase]


func _tell_mult() -> float:
	return 0.75 if phase == 3 else 1.0


func _enter_idle(cd: float) -> void:
	action = Action.IDLE
	cooldown = cd
	attack = {}


func _face_toward(x: float) -> void:
	var f: int = 1 if x >= global_position.x else -1
	if f != facing:
		facing = f
		sprite.set_facing(facing)


func _idle_move(p: Node2D, _delta: float) -> void:
	if p == null:
		velocity.x = 0.0
		return
	_face_toward(p.global_position.x)
	var dist: float = absf(p.global_position.x - global_position.x)
	var spd: float = [0.0, 70.0, 85.0, 115.0][phase]
	velocity.x = float(facing) * spd if dist > 84.0 else 0.0
	var want: StringName = &"walk" if absf(velocity.x) > 1.0 else (&"enraged" if phase == 3 else &"idle")
	if sprite.animation != want:
		sprite.play_anim(want)


func _choose_attack(p: Node2D) -> void:
	var dist: float = absf(p.global_position.x - global_position.x)
	var pool: Array[String] = []
	var total: float = 0.0
	for n in ATTACKS:
		var a: Dictionary = ATTACKS[n]
		if int(a["phase"]) > phase or n == _last_attack:
			continue
		if dist > float(a["range"]) or dist < float(a.get("min_range", 0.0)):
			continue
		pool.append(n)
		total += float(a["weight"])
	if pool.is_empty():
		return  # keep walking in until something is in range
	var roll: float = randf() * total
	var pick: String = pool[0]
	for n in pool:
		roll -= float(ATTACKS[n]["weight"])
		if roll <= 0.0:
			pick = n
			break
	start_attack(pick)


## Public so tests can force a specific move.
func start_attack(attack_name: String) -> void:
	attack = ATTACKS[attack_name].duplicate()
	attack["name"] = attack_name
	_last_attack = attack_name
	_hit_done = false
	action = Action.TELEGRAPH
	timer = float(attack["telegraph"]) * _tell_mult()
	sprite.play_anim(StringName(str(attack["anim_tell"])), true)
	sprite.force_tint("warning", timer)
	if NoiseBus != null:
		NoiseBus.emit_noise(NoiseEvent.make(global_position, 260.0, 1.4, NoiseEvent.NoiseType.ENEMY, self))


func _begin_active(p: Node2D) -> void:
	action = Action.ACTIVE
	timer = float(attack["active"])
	sprite.play_anim(StringName(str(attack["anim"])), true)
	hitbox.configure(attack)
	_mark_clash_window(timer)
	match String(attack["name"]):
		"slam":
			_strike(float(attack["reach"]), false)
			_shockwave(float(attack["radius"]))
		"sweep":
			_strike(float(attack["reach"]), false)
			ManifestFx.spawn(get_parent(), UNIT, &"sword_trail", global_position + Vector2(float(facing) * 40.0, -30.0), facing, 0.3)
		"dash":
			velocity.x = float(facing) * float(attack["speed"])
			ManifestFx.spawn(get_parent(), UNIT, &"sword_trail", global_position, facing, 0.35)
		"jump_slam":
			_leap_at(p)
		"pillars":
			_spawn_pillars(p)
		"clones":
			_spawn_clones()
		"sword_rain":
			_spawn_swords(p)
	_swing_sfx()


func _update_active(_p: Node2D) -> void:
	if String(attack.get("name", "")) == "dash":
		velocity.x = float(facing) * float(attack["speed"])
		if not _hit_done:
			_strike(float(attack["reach"]), true)
		if is_on_wall():
			timer = 0.0
			get_tree().call_group(&"camera_rig", &"add_trauma", 0.4)


func _begin_recover() -> void:
	action = Action.RECOVER
	timer = float(attack.get("recovery", 0.6))
	if String(attack.get("name", "")) != "jump_slam":
		velocity.x *= 0.2


## Frontal (or both-sided) melee check against the hero.
func _strike(reach: float, both_sides: bool) -> bool:
	var p: Node2D = _player()
	if p == null or _hit_done:
		return false
	var d: Vector2 = p.global_position - global_position
	if absf(d.x) > reach or absf(d.y) > 72.0:
		return false
	if not both_sides and d.x * float(facing) < -12.0:
		return false
	_hit_done = true
	var hurt: HurtboxComponent = p.get_node_or_null("HurtboxComponent") as HurtboxComponent
	if hurt != null:
		hurt.receive_hit(hitbox)
	return true


func _shockwave(radius: float) -> void:
	var origin: Vector2 = global_position
	ManifestFx.spawn(get_parent(), UNIT, &"shockwave", origin + Vector2(0.0, 30.0), facing, 0.5)
	ParticlesFactory.spawn_smash_impact(get_parent(), origin + Vector2(0.0, 28.0))
	get_tree().call_group(&"camera_rig", &"add_trauma", 0.5)
	var p: Node2D = _player()
	if p != null and not _hit_done and p.global_position.distance_to(origin) <= radius:
		if not (p is CharacterBody2D) or (p as CharacterBody2D).is_on_floor():
			_hit_done = true
			var hurt: HurtboxComponent = p.get_node_or_null("HurtboxComponent") as HurtboxComponent
			if hurt != null:
				hurt.receive_hit(hitbox)
	if NoiseBus != null:
		NoiseBus.emit_noise(NoiseEvent.make(origin, 560.0, 3.0, NoiseEvent.NoiseType.IMPACT, self))


func _leap_at(p: Node2D) -> void:
	var tx: float = p.global_position.x if p != null else global_position.x
	var vy: float = -sqrt(2.0 * GRAVITY * 140.0)
	var flight: float = 2.0 * -vy / GRAVITY
	velocity = Vector2(clampf((tx - global_position.x) / flight, -560.0, 560.0), vy)
	action = Action.AIRBORNE
	_was_airborne = false
	timer = 3.0


func _land_slam() -> void:
	velocity.x = 0.0
	sprite.play_anim(&"jump_slam", true)
	_shockwave(float(attack["radius"]))
	_strike(float(attack["reach"]), true)
	ManifestFx.spawn(get_parent(), UNIT, &"floor_fracture", global_position + Vector2(0.0, 32.0), facing, 0.8)
	_begin_recover()


func _spawn_pillars(p: Node2D) -> void:
	if p == null:
		return
	var floor_y: float = p.global_position.y + 10.0
	var n: int = int(attack["count"])
	for i in n:
		var off: float = (float(i) - float(n - 1) * 0.5) * float(attack["spacing"])
		BossHazard.pillar(get_parent(), Vector2(p.global_position.x + off, floor_y), float(attack["delay"]) + 0.12 * float(i), self)


func _spawn_clones() -> void:
	var bounds: Rect2 = _arena_rect()
	var y: float = global_position.y
	BossHazard.clone_dash(get_parent(), Vector2(bounds.position.x + 40.0, y), 1, float(attack["speed"]), self)
	var late := BossHazard.clone_dash(get_parent(), Vector2(bounds.end.x - 40.0, y), -1, float(attack["speed"]), self)
	late.delay = 1.1


func _spawn_swords(p: Node2D) -> void:
	if p == null:
		return
	var n: int = int(attack["count"])
	for i in n:
		var off: float = (float(i) - float(n - 1) * 0.5) * float(attack["spacing"])
		var s: ManifestProjectile = SWORD_SCENE.instantiate() as ManifestProjectile
		s.unit = UNIT
		s.anim = &"floating_sword"
		s.direction = Vector2.DOWN
		s.speed = 300.0 + 30.0 * float(i % 2)
		s.damage = 1
		s.poise_damage = 25.0
		s.lifetime = 2.2
		s.source_turret = self
		s.position = Vector2(p.global_position.x + off, p.global_position.y - 230.0 - 24.0 * float(i % 2))
		get_parent().add_child(s)


func _arena_rect() -> Rect2:
	var lr: Node = get_tree().get_first_node_in_group(&"level_root")
	if lr != null and lr.has_method("get_room_bounds"):
		var r: Rect2i = lr.call("get_room_bounds")
		return Rect2(r.position + Vector2i(32, 0), r.size - Vector2i(64, 0))
	return Rect2(global_position.x - 500.0, 0.0, 1000.0, 600.0)


func _mark_clash_window(duration: float) -> void:
	set_meta(&"attack_live_until", float(Time.get_ticks_msec()) / 1000.0 + duration)


func _swing_sfx() -> void:
	if AudioManager != null:
		AudioManager.play_sfx(&"sfx_naginata_thrust", global_position, 0.6)


func _roar() -> void:
	sprite.play_anim(&"idle")
	get_tree().call_group(&"camera_rig", &"add_trauma", 0.6)
	if NoiseBus != null:
		NoiseBus.emit_noise(NoiseEvent.make(global_position, 700.0, 3.0, NoiseEvent.NoiseType.ENEMY, self))


# --- Damage / phases ------------------------------------------------------------

## Hits while staggered deal double damage (the punish window).
func intercept_hit(hitbox_area: Area2D) -> bool:
	if action == Action.STAGGERED and hitbox_area != null and hitbox_area.get_parent() != null \
			and hitbox_area.get_parent().is_in_group(&"player"):
		var base: int = int(hitbox_area.get("damage")) if hitbox_area.get("damage") != null else 1
		health_comp.take_damage(base * 2, Vector2.ZERO, &"punish")
		ParticlesFactory.spawn_sprite_hit_spark(get_parent(), global_position + Vector2(0.0, -30.0))
		HitStop.freeze(get_tree(), 0.08)
		return true
	return false


## Clash from the hero's katana: only nudges the boss.
func apply_impulse(v: Vector2, _lock: float = 0.0) -> void:
	if action == Action.IDLE or action == Action.RECOVER:
		velocity.x += v.x * 0.15


func _on_damaged(_amount: int, _kb: Vector2) -> void:
	sprite.flash(0.08)


func _on_health_changed(cur: int, max_hp: int) -> void:
	if action == Action.DEAD or cur <= 0:
		return
	var ratio: float = float(cur) / float(max_hp)
	if phase == 1 and ratio <= 0.66:
		_enter_phase(2)
	elif phase == 2 and ratio <= 0.33:
		_enter_phase(3)


func _enter_phase(n: int) -> void:
	phase = n
	phase_changed.emit(n)
	action = Action.TRANSITION
	timer = 1.4
	velocity.x = 0.0
	hurtbox.is_invulnerable = true
	poise_comp.reset_poise()
	sprite.play_anim(&"armor_break" if n == 2 else &"phase_transition", true)
	ManifestFx.spawn(get_parent(), UNIT, &"shockwave", global_position + Vector2(0.0, 30.0), facing, 0.6, 1.4)
	get_tree().call_group(&"camera_rig", &"add_trauma", 0.7)
	# Shove the hero back so the transition is a breather, not a trap.
	var p: Node2D = _player()
	if p != null and "velocity" in p and p.global_position.distance_to(global_position) < 160.0:
		p.set("velocity", Vector2(signf(p.global_position.x - global_position.x) * 320.0, -220.0))
	var hud: Node = get_tree().get_first_node_in_group(&"hud")
	if hud != null and hud.has_method("show_tutorial_prompt"):
		hud.call("show_tutorial_prompt", "THE LEVIATHAN FRACTURES THE FLOOR" if n == 2 else "THE LEVIATHAN IS ENRAGED")


func _on_staggered(_duration: float) -> void:
	if action == Action.DEAD or action == Action.TRANSITION:
		return
	action = Action.STAGGERED
	timer = 2.0
	velocity.x = 0.0
	sprite.play_anim(&"stagger", true)
	HitStop.freeze(get_tree(), 0.12)


func _on_died(_cause: StringName) -> void:
	if action == Action.DEAD:
		return
	action = Action.DEAD
	collision_layer = 0
	hurtbox.monitorable = false
	hurtbox.monitoring = false
	sprite.play_anim(&"defeat", true)
	get_tree().call_group(&"camera_rig", &"add_trauma", 0.9)
	HitStop.freeze(get_tree(), 0.25)
	for i in 5:
		ParticlesFactory.spawn_blood_splat(get_parent(), global_position + Vector2(randf_range(-20.0, 20.0), randf_range(-50.0, 0.0)))
	boss_defeated.emit()
	var t := create_tween()
	t.tween_interval(2.0)
	t.tween_property(self, "modulate:a", 0.0, 1.0)
	t.tween_callback(queue_free)
