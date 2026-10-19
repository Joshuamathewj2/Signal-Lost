class_name ManifestFx
extends Node2D

## ManifestFx
## One-shot effect played from a unit's manifest (shockwaves, slam bursts, floor
## fractures, guard sparks...). Self-lit so it reads outside sonar light, freed
## when the animation ends (or after `life` s for single-frame effects).

static func spawn(parent: Node, unit: String, anim: StringName, pos: Vector2, facing: int = 1, life: float = 0.45, scale_mult: float = 1.0) -> ManifestFx:
	if parent == null or not parent.is_inside_tree():
		return null
	var fx := ManifestFx.new()
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	fx.material = mat
	fx.z_index = 5
	parent.add_child(fx)
	fx.global_position = pos
	var s := ManifestSprite.new()
	s.use_parent_material = true
	fx.add_child(s)
	s.unit = unit
	if scale_mult != 1.0:
		s.set_display_scale(float(s.manifest.get("scale", 1.0)) * scale_mult)
	s.set_facing(facing)
	if not s.play_anim(anim, true):
		fx.queue_free()
		return null
	var t := fx.create_tween()
	t.tween_interval(life * 0.6)
	t.tween_property(fx, "modulate:a", 0.0, life * 0.4)
	t.tween_callback(fx.queue_free)
	return fx
