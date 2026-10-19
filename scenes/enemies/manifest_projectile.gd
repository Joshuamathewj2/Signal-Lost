class_name ManifestProjectile
extends Projectile

## ManifestProjectile
## Enemy projectile drawn with a manifest animation (arrows, flail balls,
## floating swords). Keeps every Projectile rule: hurts the hero, can be parried
## back at its shooter, breaks on terrain. Optional gravity bends it into an arc.

@export var unit: String = ""
@export var anim: StringName = &"arrow"
@export var sprite_scale: float = 0.0
@export var arc_gravity: float = 0.0
@export var spin: float = 0.0     ## rad/s of visual spin (flail balls, swords)

var _holder: Node2D = null
var _sprite: ManifestSprite = null


func _ready() -> void:
	super._ready()
	if unit.is_empty():
		return
	_holder = Node2D.new()
	_holder.use_parent_material = true
	add_child(_holder)
	_sprite = ManifestSprite.new()
	_sprite.use_parent_material = true
	_sprite.procedural_enabled = false
	_sprite.display_scale_override = sprite_scale
	_holder.add_child(_sprite)
	_sprite.unit = unit
	_sprite.play_anim(anim)
	_orient()


func _physics_process(delta: float) -> void:
	if arc_gravity != 0.0 and not is_deflected:
		var v: Vector2 = direction * speed
		v.y += arc_gravity * delta
		speed = v.length()
		direction = v.normalized()
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	_orient()
	if spin != 0.0 and _holder != null:
		_holder.rotation += spin * delta


func _orient() -> void:
	if _holder == null or spin != 0.0:
		return
	_holder.rotation = direction.angle()


func _draw() -> void:
	# Faint red streak behind the art so the shot reads in total darkness.
	var col := Color.WHITE if is_deflected else Palette.color(&"danger")
	col.a = 0.55
	draw_line(-direction * 14.0, Vector2.ZERO, col, 1.5)


func deflect(by_actor: Node = null) -> void:
	super.deflect(by_actor)
	arc_gravity = 0.0
	_orient()
