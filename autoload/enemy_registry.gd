extends Node

## EnemyRegistry
## Tracks hostile spawns and eliminations for clear-gate level progression.
## Enforces that the Exit Terminal remains locked until all sector hostiles are defeated.

signal enemy_registered(enemy: Node)
signal enemy_killed(enemy: Node, death_type: StringName)
signal count_changed(remaining: int, total: int)
signal all_enemies_cleared

var total_enemies: int = 0
var remaining_enemies: int = 0
var registered_enemies: Array[Node] = []
var living_enemies: Array[Node] = []
var killed_count: int = 0
var is_cleared: bool = false

var time_since_last_kill: float = 0.0
var _out_of_bounds_timers: Dictionary = {} # Node -> float

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if SceneRouter != null and SceneRouter.has_signal("level_loaded"):
		SceneRouter.level_loaded.connect(_on_level_loaded)

func _on_level_loaded(_level_root: Node) -> void:
	reset_for_level()

func reset_for_level() -> void:
	total_enemies = 0
	remaining_enemies = 0
	registered_enemies.clear()
	living_enemies.clear()
	killed_count = 0
	is_cleared = false
	time_since_last_kill = 0.0
	_out_of_bounds_timers.clear()
	count_changed.emit(0, 0)

func register_enemy(enemy: Node) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	if registered_enemies.has(enemy):
		return

	registered_enemies.append(enemy)
	living_enemies.append(enemy)
	total_enemies += 1
	remaining_enemies += 1
	is_cleared = false

	# Hook death / exit signals
	var health: Node = enemy.get_node_or_null("HealthComponent")
	if health != null and health.has_signal("died"):
		health.connect("died", func(cause: StringName) -> void:
			unregister_enemy(enemy, cause)
		)

	if enemy.has_signal("boss_defeated"):
		enemy.connect("boss_defeated", func() -> void:
			unregister_enemy(enemy, &"boss_defeat")
		)

	enemy.tree_exiting.connect(func() -> void:
		if living_enemies.has(enemy):
			unregister_enemy(enemy, &"tree_exit")
	)

	enemy_registered.emit(enemy)
	count_changed.emit(remaining_enemies, total_enemies)

func unregister_enemy(enemy: Node, death_type: StringName = &"killed") -> void:
	if not living_enemies.has(enemy):
		return

	living_enemies.erase(enemy)
	_out_of_bounds_timers.erase(enemy)
	remaining_enemies = maxi(0, remaining_enemies - 1)
	killed_count += 1
	time_since_last_kill = 0.0

	enemy_killed.emit(enemy, death_type)
	count_changed.emit(remaining_enemies, total_enemies)

	if remaining_enemies == 0 and not is_cleared:
		is_cleared = true
		all_enemies_cleared.emit()

func _physics_process(delta: float) -> void:
	if is_cleared or living_enemies.is_empty():
		return

	time_since_last_kill += delta

	# Edge Case 1: Out of bounds recovery (falls below map or gets stuck for > 10s)
	for i in range(living_enemies.size() - 1, -1, -1):
		var enemy: Node = living_enemies[i]
		if not is_instance_valid(enemy):
			living_enemies.remove_at(i)
			continue

		if enemy is Node2D:
			var n2d: Node2D = enemy as Node2D
			# Out of bounds check (> 2500 px down or < -500 px)
			if n2d.global_position.y > 2500.0 or n2d.global_position.y < -500.0:
				var cur_time: float = _out_of_bounds_timers.get(enemy, 0.0) + delta
				_out_of_bounds_timers[enemy] = cur_time
				if cur_time >= 10.0:
					# Defeat out-of-bounds enemy
					unregister_enemy(enemy, &"hazard_fall")
					if is_instance_valid(enemy):
						enemy.queue_free()
			else:
				_out_of_bounds_timers.erase(enemy)

func get_nearest_living_enemy(from_pos: Vector2) -> Node2D:
	var nearest: Node2D = null
	var min_dist: float = INF
	for e in living_enemies:
		if is_instance_valid(e) and e is Node2D:
			var d: float = from_pos.distance_squared_to((e as Node2D).global_position)
			if d < min_dist:
				min_dist = d
				nearest = e as Node2D
	return nearest

func is_compass_active() -> bool:
	return living_enemies.size() <= 2 or time_since_last_kill >= 60.0
