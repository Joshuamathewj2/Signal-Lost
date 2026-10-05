extends Node

var bubbles: Array = []
var space_provider: Node2D = null

func set_space_provider(n: Node2D) -> void:
	space_provider = n

func set_bubbles(active_list: Array) -> void:
	bubbles = active_list

func reveal_at(pos: Vector2) -> float:
	var max_b: float = 0.0
	var space_state: PhysicsDirectSpaceState2D = null
	if space_provider != null and is_instance_valid(space_provider) and space_provider.is_inside_tree():
		space_state = space_provider.get_world_2d().direct_space_state

	for b in bubbles:
		if b == null or not b.active:
			continue
		var d: float = pos.distance_to(b.origin)
		if d <= b.radius:
			var has_los: bool = true
			if space_state != null and d > 4.0:
				var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(b.origin, pos, 1)
				var hit: Dictionary = space_state.intersect_ray(query)
				if not hit.is_empty():
					has_los = false

			if has_los:
				max_b = maxf(max_b, b.brightness)

	return max_b

func player_revealed(player_pos: Vector2) -> bool:
	var thresh: float = GameConfig.data.reveal_visible_threshold if (GameConfig != null and GameConfig.data != null) else 0.25
	return reveal_at(player_pos) > thresh
