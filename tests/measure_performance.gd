extends SceneTree

## MeasurePerformance
## Measures frame timing and rendering performance at 1920x1080 with animated sprites,
## multiple traps, enemy AI, particles, and physics simulation.

func _init() -> void:
	call_deferred(&"_run_benchmark")

func _run_benchmark() -> void:
	print("\n========================================")
	print("SIGNAL LOST: 1920x1080 60 FPS PERFORMANCE BENCHMARK")
	print("========================================\n")

	var arena_scene: PackedScene = load("res://scenes/test/combat_test_arena.tscn")
	var arena: Node2D = arena_scene.instantiate() as Node2D
	root.add_child(arena)

	# 1. Spawn Player
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: Node2D = player_scene.instantiate() as Node2D
	player.global_position = Vector2(400, 160)
	arena.add_child(player)

	# 2. Spawn 12 Enemies (3 Ronin, 3 Archer, 3 Spear, 3 Brute)
	var enemy_scenes: Array[PackedScene] = [
		load("res://scenes/enemies/kenshi.tscn"),
		load("res://scenes/enemies/yumi.tscn"),
		load("res://scenes/enemies/ashigaru.tscn"),
		load("res://scenes/enemies/brute.tscn")
	]
	for i in range(12):
		var sc: PackedScene = enemy_scenes[i % 4]
		var enemy: Node2D = sc.instantiate() as Node2D
		enemy.global_position = Vector2(100 + i * 50, 160)
		arena.add_child(enemy)

	# 3. Spawn 10 Active Traps
	var trap_scenes: Array[PackedScene] = [
		load("res://scenes/traps/floor_spikes.tscn"),
		load("res://scenes/traps/ceiling_spikes.tscn"),
		load("res://scenes/traps/swinging_blade.tscn"),
		load("res://scenes/traps/wall_blade.tscn"),
		load("res://scenes/traps/arrow_trap.tscn"),
		load("res://scenes/traps/spear_launcher.tscn"),
		load("res://scenes/traps/falling_rock.tscn"),
		load("res://scenes/traps/rolling_boulder.tscn"),
		load("res://scenes/traps/guillotine.tscn"),
		load("res://scenes/traps/fire_trap.tscn")
	]
	for i in range(trap_scenes.size()):
		var trap: Node2D = trap_scenes[i].instantiate() as Node2D
		trap.global_position = Vector2(150 + i * 60, 140)
		arena.add_child(trap)
		if trap.has_method("trigger_trap"):
			trap.call("trigger_trap")

	# Warmup 30 frames
	for f in range(30):
		await process_frame

	# Benchmark 180 frames (~3 seconds at 60 FPS)
	var frame_times: Array[float] = []
	var start_usec: int = Time.get_ticks_usec()
	var last_tick: int = start_usec

	for f in range(180):
		await process_frame
		var now: int = Time.get_ticks_usec()
		var dt_ms: float = float(now - last_tick) / 1000.0
		frame_times.append(dt_ms)
		last_tick = now

	var total_time_ms: float = float(Time.get_ticks_usec() - start_usec) / 1000.0
	var avg_frame_ms: float = total_time_ms / float(frame_times.size())
	var effective_fps: float = 1000.0 / avg_frame_ms if avg_frame_ms > 0.0 else 0.0

	frame_times.sort()
	var p99_idx: int = int(float(frame_times.size()) * 0.99)
	var p99_frame_ms: float = frame_times[mini(p99_idx, frame_times.size() - 1)]

	print("BENCHMARK RESULTS:")
	print("  Total Frames Sampled: %d" % frame_times.size())
	print("  Average Frame Time:   %.2f ms (Target: <= 16.67 ms)" % avg_frame_ms)
	print("  99th Percentile Time: %.2f ms" % p99_frame_ms)
	print("  Effective Frame Rate: %.1f FPS (Target: >= 60.0 FPS)" % effective_fps)

	var report_path: String = "res://docs/PERFORMANCE_REPORT.md"
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file != null:
		file.store_string("# SIGNAL LOST — 60 FPS Performance Report\n\n")
		file.store_string("**Resolution:** 1920x1080 (Target 60 FPS)\n")
		file.store_string("**Active Entities:** Player (AnimatedSprite2D) + 12 Animated Enemies (Ronin, Archer, Spear, Brute) + 10 Active Traps + Particles\n\n")
		file.store_string("| Metric | Measured | Target | Status |\n")
		file.store_string("|---|---|---|---|\n")
		file.store_string("| **Average Frame Time** | `%.2f ms` | `<= 16.67 ms` | %s |\n" % [avg_frame_ms, "PASS" if avg_frame_ms <= 16.67 else "WARN"])
		file.store_string("| **99th Percentile Frame Time** | `%.2f ms` | `<= 25.00 ms` | %s |\n" % [p99_frame_ms, "PASS" if p99_frame_ms <= 25.0 else "WARN"])
		file.store_string("| **Effective Frame Rate** | `%.1f FPS` | `>= 60.0 FPS` | %s |\n" % [effective_fps, "PASS" if effective_fps >= 60.0 else "WARN"])
		file.close()
		print("Saved performance benchmark report to %s" % report_path)

	quit(0)
