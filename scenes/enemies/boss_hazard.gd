class_name BossHazard
extends Node2D

## BossHazard
## Leviathan arena hazards built from its manifest art:
##   PILLAR  floor fracture tell for `delay` s, then an energy pillar erupts and
##           hurts the hero once if inside its column.
##   CLONE   a dark shadow-clone of the boss dashes across the arena and hurts
##           the hero once on contact. Jump it or dash through it.
## Damage goes through the hero's HurtboxComponent via a VillainHitbox, so
## guard and parry still apply.

enum Mode { PILLAR, CLONE }

const UNIT: String = "boss_leviathan"

var mode: Mode = Mode.PILLAR
var delay: float = 0.8
var damage: int = 1
var width: float = 22.0
var height: float = 110.0
var speed: float = 460.0
var dir: int = 1
var life: float = 3.0
var source: Node = null

var _t: float = 0.0
var _armed: bool = false
var _done: bool = false
var _sprite: ManifestSprite = null
var _hitbox: VillainHitbox = null


static func pillar(parent: Node, pos: Vector2, p_delay: float, p_source: Node) -> BossHazard:
	var h := BossHazard.new()
	h.mode = Mode.PILLAR
	h.delay = p_delay
	h.source = p_source
	parent.add_child(h)
	h.global_position = pos
	return h


static func clone_dash(parent: Node, pos: Vector2, p_dir: int, p_speed: float, p_source: Node) -> BossHazard:
	var h := BossHazard.new()
	h.mode = Mode.CLONE
	h.dir = p_dir
	h.speed = p_speed
	h.source = p_source
	h.width = 26.0
	h.height = 60.0
	h.delay = 0.45
	parent.add_child(h)
	h.global_position = pos
	return h


func _ready() -> void:
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = mat
	z_index = 4
	_hitbox = VillainHitbox.new()
	_hitbox.configure({"damage": damage, "poise": 30.0, "knockback": 220.0})
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = 0
	_hitbox.monitoring = false
	add_child(_hitbox)
	_sprite = ManifestSprite.new()
	_sprite.use_parent_material = true
	add_child(_sprite)
	_sprite.unit = UNIT
	_sprite.set_facing(dir)
	if mode == Mode.PILLAR:
		_sprite.play_anim(&"floor_fracture", true)
		_sprite.force_tint("warning", delay)
	else:
		_sprite.play_anim(&"clone", true)
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, delay)
	queue_redraw()


func _physics_process(delta: float) -> void:
	_t += delta
	if not _armed and _t >= delay:
		_armed = true
		if mode == Mode.PILLAR:
			_sprite.play_anim(&"energy_pillar", true)
			ParticlesFactory.spawn_smash_impact(get_parent(), global_position)
			get_tree().call_group(&"camera_rig", &"add_trauma", 0.15)
			if NoiseBus != null:
				NoiseBus.emit_noise(NoiseEvent.make(global_position, 180.0, 1.6, NoiseEvent.NoiseType.IMPACT, source))
		queue_redraw()
	if _armed:
		if mode == Mode.CLONE:
			global_position.x += float(dir) * speed * delta
		if not _done:
			_check_hit()
	if _t >= delay + (0.45 if mode == Mode.PILLAR else life):
		set_physics_process(false)
		var t := create_tween()
		t.tween_property(self, "modulate:a", 0.0, 0.2)
		t.tween_callback(queue_free)


func _check_hit() -> void:
	var p: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
	if p == null:
		return
	var d: Vector2 = p.global_position - global_position
	if absf(d.x) > width or d.y > 8.0 or d.y < -height:
		return
	_done = true
	var hurt: HurtboxComponent = p.get_node_or_null("HurtboxComponent") as HurtboxComponent
	if hurt != null:
		hurt.receive_hit(_hitbox)


func _draw() -> void:
	if mode == Mode.PILLAR and not _armed:
		# Warning column so the eruption is readable in the dark.
		draw_rect(Rect2(-width, -height, width * 2.0, height), Color(0.9, 0.05, 0.05, 0.12))
		draw_line(Vector2(-width, 0.0), Vector2(width, 0.0), Color(1.0, 0.15, 0.15, 0.9), 2.0)
