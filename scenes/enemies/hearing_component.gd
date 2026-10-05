class_name HearingComponent
extends Node2D

signal heard(event: NoiseEvent, strength: float)

@export var profile: EnemyProfile

func _ready() -> void:
	add_to_group(&"listeners")

static func evaluate(
	d: float,
	walls: int,
	event_radius: float,
	loudness: float,
	type: int,
	p_profile: EnemyProfile,
	wall_penalty: float
) -> float:
	if p_profile == null:
		return -1.0

	if not p_profile.accepted_types.has(type):
		return -1.0

	if loudness < p_profile.hearing_threshold:
		return -1.0

	var mult: float = p_profile.hearing_mult
	var r_max: float = event_radius * mult
	if r_max <= 0.0 or d > r_max:
		return -1.0

	var d_eff: float = d * (1.0 + wall_penalty * float(walls))
	if d_eff > r_max:
		return -1.0

	var strength: float = 1.0 - (d_eff / r_max)
	return clampf(strength, 0.001, 1.0)

func consider(event: NoiseEvent) -> void:
	if profile == null or event == null:
		return

	var owner_node: Node = owner if owner != null else get_parent()
	if event.source != null and (event.source == owner_node or event.source == self):
		return

	if not profile.accepted_types.has(event.type) or event.loudness < profile.hearing_threshold:
		return

	var p: Vector2 = global_position
	var d: float = p.distance_to(event.position)
	var r_max: float = event.radius * profile.hearing_mult
	if r_max <= 0.0 or d > r_max:
		return

	# Count walls with repeated raycasts (max 3)
	var walls: int = 0
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	if space_state != null:
		var exclude_rids: Array[RID] = []
		for _i in range(3):
			var query := PhysicsRayQueryParameters2D.create(event.position, p, 1, exclude_rids)
			var hit := space_state.intersect_ray(query)
			if hit.is_empty():
				break
			walls += 1
			exclude_rids.append(hit["rid"])

	var wall_penalty: float = GameConfig.data.wall_penalty if (GameConfig != null and GameConfig.data != null) else 0.75
	var strength: float = evaluate(d, walls, event.radius, event.loudness, event.type, profile, wall_penalty)
	if strength <= 0.0:
		return

	var sound_spd: float = GameConfig.data.sound_speed if (GameConfig != null and GameConfig.data != null) else 700.0
	var delay: float = d / sound_spd
	if delay <= 0.001:
		heard.emit(event, strength)
	else:
		get_tree().create_timer(delay).timeout.connect(func() -> void:
			if is_inside_tree():
				heard.emit(event, strength)
		)
