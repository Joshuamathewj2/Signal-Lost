class_name ParticlesFactory
extends RefCounted

const MAX_ALIVE: int = 300
static var alive_particles: int = 0

static func get_alive_count() -> int:
	return alive_particles

static func _track_and_add(p: CPUParticles2D, parent: Node, pos: Vector2) -> CPUParticles2D:
	if parent == null or p == null:
		return null

	var count: int = p.amount
	if alive_particles + count > MAX_ALIVE:
		DebugFlags.log(&"particles", "Particle limit reached: %d/%d" % [alive_particles, MAX_ALIVE])
		p.queue_free()
		return null

	alive_particles += count
	p.finished.connect(func() -> void:
		alive_particles = maxi(0, alive_particles - count)
		p.queue_free()
	)

	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	return p

static func spawn_fragment_pickup(parent: Node, pos: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = 16
	p.lifetime = 0.5
	p.one_shot = true
	p.explosiveness = 0.9
	p.color = Palette.color(&"white") if Palette != null else Color.WHITE

	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	p.material = mat

	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 12.0
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 80.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 2.5

	return _track_and_add(p, parent, pos)

static func spawn_glass_shatter(parent: Node, pos: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = 24
	p.lifetime = 1.2
	p.one_shot = true
	p.explosiveness = 1.0
	p.color = Palette.color(&"white") if Palette != null else Color.WHITE

	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.gravity = Vector2(0, 900)
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 200.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0

	return _track_and_add(p, parent, pos)

static func spawn_terminal_restore(parent: Node, pos: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = 40
	p.lifetime = 0.8
	p.one_shot = true
	p.explosiveness = 0.3
	p.color = Palette.color(&"white") if Palette != null else Color.WHITE

	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	p.material = mat

	p.direction = Vector2.UP
	p.spread = 35.0
	p.gravity = Vector2(0, -40)
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 130.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 2.5

	return _track_and_add(p, parent, pos)

static func spawn_projectile_impact(parent: Node, pos: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = 8
	p.lifetime = 0.3
	p.one_shot = true
	p.explosiveness = 1.0
	p.color = Palette.color(&"danger") if Palette != null else Color(0.88, 0.0, 0.0, 1.0)

	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	p.material = mat

	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2(0, 100)
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 100.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 2.5

	return _track_and_add(p, parent, pos)

static func spawn_landing_dust(parent: Node, pos: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = 6
	p.lifetime = 0.3
	p.one_shot = true
	p.explosiveness = 0.8
	p.color = Palette.color(&"near") if Palette != null else Color(0.24, 0.24, 0.24, 1.0)

	p.direction = Vector2.UP
	p.spread = 70.0
	p.gravity = Vector2(0, 120)
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 50.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 2.0

	return _track_and_add(p, parent, pos)
