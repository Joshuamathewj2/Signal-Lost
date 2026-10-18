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

static func spawn_hit_spark(parent: Node, pos: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = 12
	p.lifetime = 0.2
	p.one_shot = true
	p.explosiveness = 1.0
	p.color = Color(0.3, 0.9, 1.0, 1.0) # Cyan spark

	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	p.material = mat

	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2(0, 150)
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 140.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0

	return _track_and_add(p, parent, pos)


static func spawn_sprite_hit_spark(parent: Node, pos: Vector2) -> Node2D:
	if parent == null: return null
	var spr := Sprite2D.new()
	spr.texture = load("res://assets/sprites/fx/fx_hit_spark_0.png") as Texture2D
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	spr.material = mat
	spr.global_position = pos
	spr.scale = Vector2(0.5, 0.5)
	spr.z_index = 30
	parent.add_child(spr)
	
	var tw := spr.create_tween()
	tw.tween_property(spr, "scale", Vector2(1.2, 1.2), 0.08)
	tw.parallel().tween_property(spr, "modulate:a", 0.0, 0.14)
	tw.tween_callback(spr.queue_free)
	return spr


static func spawn_blood_splat(parent: Node, pos: Vector2) -> Node2D:
	if parent == null: return null
	# Check Gore toggle in GameConfig / SaveData
	var gore_on: bool = true
	if GameConfig != null and "gore_enabled" in GameConfig:
		gore_on = bool(GameConfig.get("gore_enabled"))
	elif SaveData != null:
		gore_on = bool(SaveData.get_setting("gore", true))
		
	if not gore_on:
		return spawn_sprite_hit_spark(parent, pos)

	var spr := Sprite2D.new()
	spr.texture = load("res://assets/sprites/fx/fx_blood_splat_0.png") as Texture2D
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	spr.material = mat
	spr.global_position = pos
	spr.scale = Vector2(0.4, 0.4)
	spr.z_index = 28
	parent.add_child(spr)

	var tw := spr.create_tween()
	tw.tween_property(spr, "scale", Vector2(1.0, 1.0), 0.10)
	tw.parallel().tween_property(spr, "modulate:a", 0.0, 0.28)
	tw.tween_callback(spr.queue_free)
	return spr


static func spawn_smash_impact(parent: Node, pos: Vector2) -> Node2D:
	if parent == null: return null
	var spr := Sprite2D.new()
	spr.texture = load("res://assets/sprites/fx/fx_smash_impact_0.png") as Texture2D
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	spr.material = mat
	spr.global_position = pos
	spr.scale = Vector2(0.6, 0.6)
	spr.z_index = 26
	parent.add_child(spr)

	var tw := spr.create_tween()
	tw.tween_property(spr, "scale", Vector2(1.1, 1.1), 0.12)
	tw.parallel().tween_property(spr, "modulate:a", 0.0, 0.25)
	tw.tween_callback(spr.queue_free)
	return spr


static func spawn_sprite_dust(parent: Node, pos: Vector2) -> Node2D:
	if parent == null: return null
	var spr := Sprite2D.new()
	spr.texture = load("res://assets/sprites/fx/fx_dust_0.png") as Texture2D
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	spr.material = mat
	spr.global_position = pos
	spr.scale = Vector2(0.4, 0.4)
	spr.z_index = 24
	parent.add_child(spr)

	var tw := spr.create_tween()
	tw.tween_property(spr, "scale", Vector2(0.8, 0.8), 0.15)
	tw.parallel().tween_property(spr, "modulate:a", 0.0, 0.22)
	tw.tween_callback(spr.queue_free)
	return spr
