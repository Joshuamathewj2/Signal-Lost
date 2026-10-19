class_name StVillainAttack
extends State

## StVillainAttack
## Data-driven attack state for the manifest villains. Attacks live in
## data/enemies/<kind>.json under "attacks"; each one is
##   telegraph (wind-up anim + self-lit red tint) -> active (strike) -> recovery.
## Types:
##   melee      one frontal hit at strike time
##   lunge      steps forward while striking (warden thrust, phantom slash)
##   dash       Fighter dash; hits once on contact during the dash
##   spin       hits both sides, `hits` times across the active window
##   shockwave  frontal hit + ground radius (also crushes nearby enemies)
##   projectile `count` shots fanned over `spread` degrees (arrows, flail, volley)
##   reposition no damage: hop away from the hero (archers)
## Hits go through the hero's HurtboxComponent, so parry / guard / clash apply.
## Keys: name, type, range, min_range, max_dy, telegraph, active, recovery,
## cooldown, weight, damage, poise, knockback, unblockable, anim_telegraph,
## anim_strike, tell, plus per-type extras (lunge_speed, hits, radius, count,
## spread, speed, gravity, projectile_anim, projectile_spin, fx).

enum Phase { TELEGRAPH, ACTIVE, RECOVERY }

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/enemies/manifest_projectile.tscn")
const MELEE_TYPES: PackedStringArray = ["melee", "lunge", "dash", "spin", "shockwave"]

var attack: Dictionary = {}
var phase: Phase = Phase.TELEGRAPH
var timer: float = 0.0
var hits_done: int = 0
var has_token: bool = false
var _cooldowns: Dictionary = {}
var _hit_landed: bool = false


func _now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0


func _attacks() -> Array:
	if actor == null or not ("enemy_data" in actor):
		return []
	return (actor.get("enemy_data") as Dictionary).get("attacks", [])


func _player() -> Node2D:
	return get_tree().get_first_node_in_group(&"player") as Node2D if is_inside_tree() else null


## Weighted pick among attacks that are off cooldown and fit the hero's position.
func pick_attack(player: Node2D) -> Dictionary:
	if actor == null or player == null:
		return {}
	var d: Vector2 = player.global_position - (actor as Node2D).global_position
	var dist: float = absf(d.x)
	var now: float = _now()
	var pool: Array = []
	var total: float = 0.0
	for a in _attacks():
		var atk: Dictionary = a
		if now < float(_cooldowns.get(atk.get("name", ""), 0.0)):
			continue
		if dist > float(atk.get("range", 40.0)) or dist < float(atk.get("min_range", 0.0)):
			continue
		if absf(d.y) > float(atk.get("max_dy", 48.0)):
			continue
		pool.append(atk)
		total += float(atk.get("weight", 1.0))
	if pool.is_empty():
		return {}
	var roll: float = randf() * total
	for atk in pool:
		roll -= float(atk.get("weight", 1.0))
		if roll <= 0.0:
			return atk
	return pool[pool.size() - 1]


func is_melee(atk: Dictionary) -> bool:
	return MELEE_TYPES.has(String(atk.get("type", "melee")))


func enter(msg: Dictionary = {}) -> void:
	attack = msg.get("attack", {})
	has_token = bool(msg.get("has_token", false))
	if attack.is_empty():
		attack = pick_attack(_player())
	if attack.is_empty() or actor == null:
		transition(&"Chase")
		return
	hits_done = 0
	_hit_landed = false
	phase = Phase.TELEGRAPH
	timer = float(attack.get("telegraph", 0.45))

	var mover: PlatformMover = actor.get_node_or_null("PlatformMover") as PlatformMover
	if mover != null:
		mover.stop()
	_face_player()

	var vis: Node = actor.get_node_or_null("Visual")
	if vis != null:
		if vis.has_method("play_anim"):
			vis.call("play_anim", StringName(str(attack.get("anim_telegraph", "telegraph"))))
		if bool(attack.get("tint", true)) and vis.get("sprite") != null:
			(vis.get("sprite") as ManifestSprite).force_tint("warning", timer)
		var tell: String = str(attack.get("tell", "危" if bool(attack.get("unblockable", false)) else ""))
		if not tell.is_empty() and vis.has_method("show_tell"):
			vis.call("show_tell", tell)
	if String(attack.get("type", "")) == "dash" and actor.get("fighter") != null:
		var f: Fighter = actor.get("fighter") as Fighter
		f.facing = int(actor.get("facing"))
	if NoiseBus != null:
		NoiseBus.emit_noise(NoiseEvent.make(actor.global_position, 120.0, 0.8, NoiseEvent.NoiseType.ENEMY, actor))


func physics_update(delta: float) -> void:
	if actor == null or attack.is_empty():
		return
	timer -= delta
	match phase:
		Phase.TELEGRAPH:
			if bool(attack.get("track", true)):
				_face_player()
			if timer <= 0.0:
				_begin_active()
		Phase.ACTIVE:
			_update_active()
			if timer <= 0.0:
				_begin_recovery()
		Phase.RECOVERY:
			if timer <= 0.0:
				_finish()


func _begin_active() -> void:
	phase = Phase.ACTIVE
	timer = float(attack.get("active", 0.12))
	var vis: Node = actor.get_node_or_null("Visual")
	if vis != null and vis.has_method("play_anim"):
		vis.call("play_anim", StringName(str(attack.get("anim_strike", "attack"))))
	if is_melee(attack) and actor.has_method("mark_attack_active"):
		actor.call("mark_attack_active", timer)

	var facing: int = int(actor.get("facing"))
	match String(attack.get("type", "melee")):
		"melee":
			_strike(false)
		"lunge":
			if actor.has_method("apply_impulse"):
				actor.call("apply_impulse", Vector2(float(facing) * float(attack.get("lunge_speed", 260.0)), 0.0), timer)
			_strike(false)
		"dash":
			var f: Fighter = actor.get("fighter") as Fighter
			if f != null:
				f.facing = facing
				f.request_dash(true)
			_fx(StringName(str(attack.get("fx", ""))))
		"spin":
			_strike(true)
		"shockwave":
			_strike(false)
			_shockwave()
		"projectile":
			_fire_projectiles()
		"reposition":
			var p: Node2D = _player()
			var f2: Fighter = actor.get("fighter") as Fighter
			if f2 != null and p != null:
				f2.jump_away(p.global_position.x, float(attack.get("distance", 112.0)))

	_emit_strike_noise()


func _update_active() -> void:
	match String(attack.get("type", "melee")):
		"dash":
			if not _hit_landed:
				_strike(false, float(attack.get("contact", 26.0)))
		"lunge":
			if not _hit_landed:
				_strike(false)
		"spin":
			var hits: int = int(attack.get("hits", 2))
			var active_len: float = float(attack.get("active", 0.4))
			var due: int = int(floor((active_len - timer) / maxf(active_len / float(hits), 0.01))) + 1
			if hits_done < mini(due, hits):
				_strike(true)


func _begin_recovery() -> void:
	phase = Phase.RECOVERY
	timer = float(attack.get("recovery", 0.4))
	var f: Fighter = actor.get("fighter") as Fighter
	if f != null and f.is_dashing():
		f.apply_knockback(Vector2(actor.velocity.x * 0.3, actor.velocity.y), 0.1)


func _finish() -> void:
	_cooldowns[attack.get("name", "")] = _now() + float(attack.get("cooldown", 0.8))
	var then: String = str(attack.get("then", ""))
	if not then.is_empty():
		for a in _attacks():
			if str((a as Dictionary).get("name", "")) == then:
				transition(&"Attack", {"attack": a, "force": true, "has_token": has_token})
				return
	transition(&"Chase", {"resume": true})


## Flinch / clash: the swing is cancelled into a short recovery.
func interrupt() -> void:
	if phase == Phase.RECOVERY:
		return
	var f: Fighter = actor.get("fighter") as Fighter if actor != null else null
	if f != null and f.is_dashing():
		f.apply_knockback(Vector2.ZERO, 0.15)
	phase = Phase.RECOVERY
	timer = 0.3


func exit() -> void:
	_release_token()


func _release_token() -> void:
	if has_token and AttackTokenManager != null and actor != null:
		AttackTokenManager.release_token(actor)
	has_token = false


func _face_player() -> void:
	var p: Node2D = _player()
	if p != null and actor.has_method("face"):
		actor.call("face", 1 if p.global_position.x >= actor.global_position.x else -1)
		var f: Fighter = actor.get("fighter") as Fighter
		if f != null and not f.is_dashing():
			f.facing = int(actor.get("facing"))


## One hit check against the hero. `reach_override` > 0 replaces the attack range
## (dash / lunge contact). Returns true when the hero was in the strike zone.
func _strike(both_sides: bool, reach_override: float = 0.0) -> bool:
	hits_done += 1
	var p: Node2D = _player()
	if p == null:
		return false
	var d: Vector2 = p.global_position - actor.global_position
	var reach: float = reach_override if reach_override > 0.0 else float(attack.get("reach", attack.get("range", 40.0)))
	if absf(d.y) > float(attack.get("height", 40.0)) or absf(d.x) > reach:
		return false
	if not both_sides and d.x * float(actor.get("facing")) < -8.0:
		return false
	_hit_landed = true
	_deliver(p)
	return true


func _deliver(p: Node2D) -> void:
	if bool(attack.get("unblockable", false)):
		# Guard and parry cannot stop it - only dodging (i-frames) can.
		var info := DamageInfo.make(int(attack.get("damage", 1)), actor, DamageInfo.Faction.ENEMY,
				Vector2(signf(p.global_position.x - actor.global_position.x) * float(attack.get("knockback", 200.0)), -80.0), &"unblockable")
		info.poise_damage = float(attack.get("poise", 30.0))
		info.hitstop_ms = 90
		info.shake = 0.3
		info.apply_to(p)
		return
	var hurt: HurtboxComponent = p.get_node_or_null("HurtboxComponent") as HurtboxComponent
	var hb: Area2D = actor.get_node_or_null("Hitbox") as Area2D
	if hurt == null or hb == null:
		if p.has_method("take_damage"):
			p.call("take_damage", int(attack.get("damage", 1)))
		return
	if hb.has_method("configure"):
		hb.call("configure", attack)
	hurt.receive_hit(hb)


func _shockwave() -> void:
	var radius: float = float(attack.get("radius", 96.0))
	var origin: Vector2 = actor.global_position
	var p: Node2D = _player()
	if p != null and not _hit_landed and p.global_position.distance_to(origin) <= radius:
		var on_ground: bool = not (p is CharacterBody2D) or (p as CharacterBody2D).is_on_floor()
		if on_ground:
			_hit_landed = true
			_deliver(p)
	var info := DamageInfo.make(int(attack.get("ally_damage", 1)), actor, DamageInfo.Faction.ENEMY, Vector2(220.0, -120.0), &"shockwave")
	Shockwave.strike(get_tree(), origin, radius, info, actor)
	_fx(StringName(str(attack.get("fx", "shockwave"))))
	ParticlesFactory.spawn_smash_impact(actor.get_parent(), origin)
	get_tree().call_group(&"camera_rig", &"add_trauma", float(attack.get("shake", 0.35)))


func _fire_projectiles() -> void:
	var p: Node2D = _player()
	var parent: Node = actor.get_parent()
	if parent == null:
		return
	var origin: Vector2 = actor.global_position + Vector2(float(actor.get("facing")) * 12.0, float(attack.get("muzzle_y", -14.0)))
	var aim: Vector2 = Vector2(float(actor.get("facing")), 0.0)
	if p != null:
		aim = (p.global_position + Vector2(0.0, -10.0) - origin).normalized()
	var count: int = int(attack.get("count", 1))
	var spread: float = deg_to_rad(float(attack.get("spread", 0.0)))
	var g: float = float(attack.get("gravity", 0.0))
	var spd: float = float(attack.get("speed", 460.0))
	if g > 0.0 and p != null:
		# Lob: aim above the target so gravity drops the shot onto it.
		var t: float = maxf(absf(p.global_position.x - origin.x) / spd, 0.15)
		aim = (p.global_position + Vector2(0.0, -10.0 - 0.5 * g * t * t) - origin).normalized()
	for i in count:
		var off: float = 0.0 if count == 1 else lerpf(-spread * 0.5, spread * 0.5, float(i) / float(count - 1))
		var proj: ManifestProjectile = PROJECTILE_SCENE.instantiate() as ManifestProjectile
		proj.unit = str(attack.get("projectile_unit", String(actor.get("enemy_data").get("manifest", ""))))
		proj.anim = StringName(str(attack.get("projectile_anim", "arrow")))
		proj.sprite_scale = float(attack.get("projectile_scale", 0.0))
		proj.spin = float(attack.get("projectile_spin", 0.0))
		proj.arc_gravity = g
		proj.direction = aim.rotated(off)
		proj.speed = spd
		proj.damage = int(attack.get("damage", 1))
		proj.poise_damage = float(attack.get("poise", 20.0))
		proj.lifetime = float(attack.get("lifetime", 2.5))
		proj.source_turret = actor
		proj.position = origin
		parent.add_child(proj)
	if AudioManager != null:
		AudioManager.play_sfx(&"sfx_arrow_whistle", origin)


func _fx(anim: StringName) -> void:
	if anim == &"":
		return
	var unit: String = String((actor.get("enemy_data") as Dictionary).get("manifest", ""))
	ManifestFx.spawn(actor.get_parent(), unit, anim, actor.global_position + Vector2(0.0, float(attack.get("fx_y", 12.0))), int(actor.get("facing")))


func _emit_strike_noise() -> void:
	if NoiseBus == null:
		return
	var loud: float = 1.6 if is_melee(attack) else 1.3
	NoiseBus.emit_noise(NoiseEvent.make(actor.global_position, float(attack.get("noise", 200.0)), loud, NoiseEvent.NoiseType.COMBAT, actor))
	if is_melee(attack) and AudioManager != null:
		AudioManager.play_sfx(&"sfx_katana_slash" if int(attack.get("damage", 1)) < 2 else &"sfx_naginata_thrust", actor.global_position, randf_range(0.75, 0.95))
