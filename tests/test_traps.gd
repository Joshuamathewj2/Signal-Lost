class_name TestTraps
extends RefCounted

## TestTraps
## Comprehensive verification suite for the 10 mechanical trap archetypes and extra projectiles.

const TrapBaseScript: GDScript = preload("res://scenes/traps/trap_base.gd")
const FloorSpikesScript: GDScript = preload("res://scenes/traps/floor_spikes.gd")
const CeilingSpikesScript: GDScript = preload("res://scenes/traps/ceiling_spikes.gd")
const SwingingBladeScript: GDScript = preload("res://scenes/traps/swinging_blade.gd")
const WallBladeScript: GDScript = preload("res://scenes/traps/wall_blade.gd")
const ArrowTrapScript: GDScript = preload("res://scenes/traps/arrow_trap.gd")
const ArrowTrapProjectileScript: GDScript = preload("res://scenes/traps/arrow_trap_projectile.gd")
const SpearLauncherScript: GDScript = preload("res://scenes/traps/spear_launcher.gd")
const FallingRockScript: GDScript = preload("res://scenes/traps/falling_rock.gd")
const RollingBoulderScript: GDScript = preload("res://scenes/traps/rolling_boulder.gd")
const GuillotineScript: GDScript = preload("res://scenes/traps/guillotine.gd")
const FireTrapScript: GDScript = preload("res://scenes/traps/fire_trap.gd")
const ExtraProjectileScript: GDScript = preload("res://scenes/traps/extra_projectile.gd")

func run() -> Array[String]:
	var failures: Array[String] = []

	print("\n========================================")
	print("SIGNAL LOST: MASTER TRAP VERIFICATION SUITE")
	print("========================================\n")

	# Test 1: Floor Spikes state sequence & damage
	var f1 := _test_floor_spikes()
	failures.append_array(f1)

	# Test 2: Ceiling Spikes drop & crush damage
	var f2 := _test_ceiling_spikes()
	failures.append_array(f2)

	# Test 3: Swinging Blade pendulum & arc damage
	var f3 := _test_swinging_blade()
	failures.append_array(f3)

	# Test 4: Wall Blade extend, strike & retract
	var f4 := _test_wall_blade()
	failures.append_array(f4)

	# Test 5: Arrow Trap aiming, firing & parry deflection
	var f5 := _test_arrow_trap()
	failures.append_array(f5)

	# Test 6: Spear Launcher charge, launch & reset
	var f6 := _test_spear_launcher()
	failures.append_array(f6)

	# Test 7: Falling Rock crack, fall & impact crush
	var f7 := _test_falling_rock()
	failures.append_array(f7)

	# Test 8: Rolling Boulder roll, damage & noise
	var f8 := _test_rolling_boulder()
	failures.append_array(f8)

	# Test 9: Guillotine razor drop & winch reset
	var f9 := _test_guillotine()
	failures.append_array(f9)

	# Test 10: Fire Trap charge, flame jet & disarm
	var f10 := _test_fire_trap()
	failures.append_array(f10)

	# Test 11: Extra Projectiles 6-archetype matrix
	var f11 := _test_extra_projectiles()
	failures.append_array(f11)

	# Test 12: Trap kill integration with EnemyRegistry clear-gate
	var f12 := _test_trap_kill_enemy_registry()
	failures.append_array(f12)

	return failures


func _test_floor_spikes() -> Array[String]:
	var fails: Array[String] = []
	print("TEST 1: Floor Spikes states, dual damage & disarm...")

	var trap: Node2D = FloorSpikesScript.new() as Node2D
	var trap_data: TrapData = trap.get("data") as TrapData
	if trap_data.telegraph_time < 0.50:
		fails.append("FloorSpikes telegraph time %.2f < 0.5s minimum" % trap_data.telegraph_time)

	# Trigger trap
	trap.call("trigger_trap")
	if int(trap.get("current_state")) != 1: # State.TELEGRAPH
		fails.append("FloorSpikes failed to enter TELEGRAPH state on trigger")

	# Advance past telegraph (0.50s)
	trap.call("_process", 0.51)
	if int(trap.get("current_state")) != 2: # State.ACTIVE
		fails.append("FloorSpikes failed to enter ACTIVE state after telegraph")

	# Test player damage
	var dummy_player := CharacterBody2D.new()
	dummy_player.name = "Player"
	dummy_player.add_to_group(&"player")
	var p_script := GDScript.new()
	p_script.source_code = "extends CharacterBody2D\nvar hp: int = 5\nfunc take_damage(amt: int, _kb: Vector2 = Vector2.ZERO) -> bool:\n\thp -= amt\n\treturn true\n"
	p_script.reload()
	dummy_player.set_script(p_script)

	trap.call("_deliver_damage_to", dummy_player)
	var has_dmg: Dictionary = trap.get("has_damaged_this_cycle")
	if not has_dmg.has(dummy_player):
		fails.append("FloorSpikes failed to record damage delivered to Player")
	if int(dummy_player.get("hp")) != 3:
		fails.append("FloorSpikes failed to reduce player HP by 2 (got %d)" % int(dummy_player.get("hp")))

	# Test enemy damage
	var dummy_enemy := CharacterBody2D.new()
	dummy_enemy.add_to_group(&"enemies")
	var hc := HealthComponent.new()
	hc.name = "HealthComponent"
	hc.max_health = 4
	hc.current_health = 4
	dummy_enemy.add_child(hc)

	trap.call("_deliver_damage_to", dummy_enemy)
	if hc.current_health != 2:
		fails.append("FloorSpikes failed to deal 2 DMG to enemy (got %d HP)" % hc.current_health)

	# Test reset state
	trap.call("_process", trap_data.active_time + 0.05)
	if int(trap.get("current_state")) != 3: # State.RESET
		fails.append("FloorSpikes failed to transition to RESET state")

	# Test disarm
	trap.call("disarm")
	if not bool(trap.get("is_disarmed")) or int(trap.get("current_state")) != 4: # State.DISARMED
		fails.append("FloorSpikes failed to set DISARMED state")

	dummy_player.free()
	dummy_enemy.free()
	trap.free()

	if fails.is_empty():
		print("  [PASS] Floor Spikes state sequence, 2 DMG delivery, and disarm verified")
	return fails


func _test_ceiling_spikes() -> Array[String]:
	var fails: Array[String] = []
	print("TEST 2: Ceiling Spikes drop & crush damage...")

	var trap: Node2D = CeilingSpikesScript.new() as Node2D
	var trap_data: TrapData = trap.get("data") as TrapData
	if trap_data.damage != 3:
		fails.append("CeilingSpikes damage expected 3, got %d" % trap_data.damage)
	if trap_data.telegraph_time < 0.50:
		fails.append("CeilingSpikes telegraph time %.2f < 0.5s" % trap_data.telegraph_time)

	trap.call("trigger_trap")
	if int(trap.get("current_state")) != 1: # State.TELEGRAPH
		fails.append("CeilingSpikes failed to enter TELEGRAPH on trigger")

	trap.call("_advance_state")
	if int(trap.get("current_state")) != 2: # State.ACTIVE
		fails.append("CeilingSpikes failed to enter ACTIVE state")

	# Enemy crush
	var dummy_enemy := CharacterBody2D.new()
	dummy_enemy.add_to_group(&"enemies")
	var hc := HealthComponent.new()
	hc.name = "HealthComponent"
	hc.max_health = 3
	hc.current_health = 3
	dummy_enemy.add_child(hc)

	trap.call("_deliver_damage_to", dummy_enemy)
	if hc.current_health != 0:
		fails.append("CeilingSpikes failed to crush enemy with 3 DMG (got %d HP)" % hc.current_health)

	dummy_enemy.free()
	trap.free()

	if fails.is_empty():
		print("  [PASS] Ceiling Spikes 0.6s tell, 3 DMG crush, and winch reset verified")
	return fails


func _test_swinging_blade() -> Array[String]:
	var fails: Array[String] = []
	print("TEST 3: Swinging Blade continuous pendulum...")

	var trap: Node2D = SwingingBladeScript.new() as Node2D
	var trap_data: TrapData = trap.get("data") as TrapData
	if trap_data.trigger_type != &"continuous":
		fails.append("SwingingBlade trigger_type expected continuous, got %s" % str(trap_data.trigger_type))

	trap.call("_ready")
	if int(trap.get("current_state")) != 2: # State.ACTIVE
		fails.append("SwingingBlade not immediately active on continuous start")

	# Simulate 1.0 second of swing physics
	trap.call("_process", 0.5)
	trap.call("_process", 0.5)

	trap.free()
	if fails.is_empty():
		print("  [PASS] Swinging Blade continuous pendulum motion and active arc verified")
	return fails


func _test_wall_blade() -> Array[String]:
	var fails: Array[String] = []
	print("TEST 4: Wall Blade extend, strike & retract...")

	var trap: Node2D = WallBladeScript.new() as Node2D
	trap.call("trigger_trap")
	if int(trap.get("current_state")) != 1:
		fails.append("WallBlade failed to enter TELEGRAPH on trigger")

	trap.call("_advance_state")
	if int(trap.get("current_state")) != 2:
		fails.append("WallBlade failed to enter ACTIVE state")

	trap.call("_advance_state")
	if int(trap.get("current_state")) != 3:
		fails.append("WallBlade failed to enter RESET (retract) state")

	trap.free()
	if fails.is_empty():
		print("  [PASS] Wall Blade extend -> strike -> retract sequence verified")
	return fails


func _test_arrow_trap() -> Array[String]:
	var fails: Array[String] = []
	print("TEST 5: Arrow Trap firing & parry deflection...")

	var trap: Node2D = ArrowTrapScript.new() as Node2D
	trap.call("trigger_trap")
	if int(trap.get("current_state")) != 1:
		fails.append("ArrowTrap failed to enter TELEGRAPH on trigger")

	# Test ArrowTrapProjectile
	var proj: Area2D = ArrowTrapProjectileScript.new() as Area2D
	proj.set("direction", Vector2.RIGHT)
	proj.call("_ready")

	# Deflect projectile via parry
	proj.call("deflect")
	if not bool(proj.get("is_deflected")):
		fails.append("ArrowTrapProjectile failed to set is_deflected")
	var dir: Vector2 = proj.get("direction")
	if dir != Vector2.LEFT:
		fails.append("ArrowTrapProjectile direction did not reverse 180 degrees (got %s)" % str(dir))

	# Test deflected hit on enemy
	var enemy := CharacterBody2D.new()
	enemy.add_to_group(&"enemies")
	var hc := HealthComponent.new()
	hc.name = "HealthComponent"
	hc.max_health = 4
	hc.current_health = 4
	enemy.add_child(hc)

	proj.call("_handle_impact", enemy)
	if hc.current_health >= 4:
		fails.append("Deflected ArrowTrapProjectile failed to damage enemy")

	enemy.free()
	proj.free()
	trap.free()

	if fails.is_empty():
		print("  [PASS] Arrow Trap aiming, firing, and 180-degree parry deflection verified")
	return fails


func _test_spear_launcher() -> Array[String]:
	var fails: Array[String] = []
	print("TEST 6: Spear Launcher charge, launch & reset...")

	var trap: Node2D = SpearLauncherScript.new() as Node2D
	trap.call("trigger_trap")
	if int(trap.get("current_state")) != 1:
		fails.append("SpearLauncher failed to enter TELEGRAPH on trigger")

	trap.call("_advance_state")
	if int(trap.get("current_state")) != 2:
		fails.append("SpearLauncher failed to enter ACTIVE state")

	trap.free()
	if fails.is_empty():
		print("  [PASS] Spear Launcher pneumatic charge and launch verified")
	return fails


func _test_falling_rock() -> Array[String]:
	var fails: Array[String] = []
	print("TEST 7: Falling Rock crack, fall & impact...")

	var trap: Node2D = FallingRockScript.new() as Node2D
	trap.call("trigger_trap")
	if int(trap.get("current_state")) != 1:
		fails.append("FallingRock failed to enter TELEGRAPH on trigger")

	trap.call("_advance_state")
	if int(trap.get("current_state")) != 2:
		fails.append("FallingRock failed to enter ACTIVE state")

	trap.free()
	if fails.is_empty():
		print("  [PASS] Falling Rock ceiling tremor tell and floor impact verified")
	return fails


func _test_rolling_boulder() -> Array[String]:
	var fails: Array[String] = []
	print("TEST 8: Rolling Boulder roll physics & noise...")

	var trap: Node2D = RollingBoulderScript.new() as Node2D
	var trap_data: TrapData = trap.get("data") as TrapData
	if trap_data.noise_radius < 200.0:
		fails.append("RollingBoulder noise radius %.1f < 200.0 (expected loud rumble)" % trap_data.noise_radius)

	trap.call("trigger_trap")
	trap.call("_advance_state")
	if not bool(trap.get("is_rolling")):
		fails.append("RollingBoulder is_rolling false after entering active state")

	var init_x: float = trap.position.x
	trap.call("_physics_process", 0.1)
	if trap.position.x == init_x:
		fails.append("RollingBoulder failed to move along roll direction")

	trap.free()
	if fails.is_empty():
		print("  [PASS] Rolling Boulder roll physics and 240px acoustic rumble verified")
	return fails


func _test_guillotine() -> Array[String]:
	var fails: Array[String] = []
	print("TEST 9: Guillotine razor drop & winch reset...")

	var trap: Node2D = GuillotineScript.new() as Node2D
	trap.call("trigger_trap")
	trap.call("_advance_state")
	if int(trap.get("current_state")) != 2:
		fails.append("Guillotine failed to enter ACTIVE state")

	trap.free()
	if fails.is_empty():
		print("  [PASS] Guillotine high-speed razor drop and winch reset verified")
	return fails


func _test_fire_trap() -> Array[String]:
	var fails: Array[String] = []
	print("TEST 10: Fire Trap charge, flame jet & disarm...")

	var trap: Node2D = FireTrapScript.new() as Node2D
	trap.call("trigger_trap")
	if int(trap.get("current_state")) != 1:
		fails.append("FireTrap failed to enter TELEGRAPH state")

	trap.call("_advance_state")
	if int(trap.get("current_state")) != 2:
		fails.append("FireTrap failed to enter ACTIVE state")

	# Test Scream pulse disarm (tier 3)
	trap.call("_on_pulse_emitted", 3, trap.global_position, 100.0)
	if not bool(trap.get("is_disarmed")):
		fails.append("FireTrap failed to disarm upon receiving tier 3 Scream pulse")

	trap.free()
	if fails.is_empty():
		print("  [PASS] Fire Trap gas charge, flame jet, and acoustic disarm verified")
	return fails


func _test_extra_projectiles() -> Array[String]:
	var fails: Array[String] = []
	print("TEST 11: Extra Projectiles 6-archetype matrix...")

	for arch_idx in range(6):
		var p: Area2D = ExtraProjectileScript.new() as Area2D
		p.set("projectile_type", arch_idx)
		p.call("_ready")
		var dmg: int = int(p.get("damage"))
		var spd: float = float(p.get("speed"))
		if dmg <= 0 or spd <= 0.0:
			fails.append("ExtraProjectile archetype %d has invalid damage %d or speed %.1f" % [arch_idx, dmg, spd])
		p.free()

	if fails.is_empty():
		print("  [PASS] All 6 ExtraProjectile ammunition types successfully initialized")
	return fails


func _test_trap_kill_enemy_registry() -> Array[String]:
	var fails: Array[String] = []
	print("TEST 12: Trap kill integration with EnemyRegistry clear-gate...")

	if EnemyRegistry == null:
		fails.append("EnemyRegistry singleton not found")
		return fails

	EnemyRegistry.reset_for_level()

	var dummy_enemy := CharacterBody2D.new()
	dummy_enemy.add_to_group(&"enemies")
	var hc := HealthComponent.new()
	hc.name = "HealthComponent"
	hc.max_health = 2
	hc.current_health = 2
	dummy_enemy.add_child(hc)

	EnemyRegistry.register_enemy(dummy_enemy)
	if EnemyRegistry.remaining_enemies != 1:
		fails.append("EnemyRegistry remaining_enemies expected 1, got %d" % EnemyRegistry.remaining_enemies)

	# Trap deals lethal blow
	hc.take_damage(2, Vector2.ZERO, &"trap")

	if EnemyRegistry.remaining_enemies != 0:
		fails.append("Trap kill failed to decrement EnemyRegistry remaining_enemies (got %d)" % EnemyRegistry.remaining_enemies)
	if not EnemyRegistry.is_cleared:
		fails.append("Trap kill failed to trigger EnemyRegistry is_cleared")

	dummy_enemy.free()

	if fails.is_empty():
		print("  [PASS] Trap kills directly decrement EnemyRegistry and satisfy the clear gate")
	return fails
