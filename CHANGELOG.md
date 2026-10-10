# Changelog — SIGNAL LOST

All notable changes to this project will be documented in this file.

## P0-T1 Project settings & repo
- Initialized local Git repository
- Created `.gitignore` ignoring `.godot/`, `export/`, and `*.tmp`
- Created `project.godot` with 1280x720 canvas_items/expand stretch, GL Compatibility renderer, and shadow atlas size 2048
- Created directory hierarchy per ARCH §8 with `.gdkeep` files
- Created `README.md` stub

## P0-T2 Input map & layer names
- Configured 2D physics layer names (world, one_way, player, enemy, interactable, projectile, hazard_kill)
- Configured 2D render layer names (world_fg, world_bg, actors, air)
- Added all 11 input actions with keyboard, mouse, and gamepad bindings per ARCH §12

## P0-T3 Resource class scripts
- Created `GameConfigData` (`scripts/resources/game_config_data.gd`) with typed groups and tunable parameters per GDD §4.1, ARCH §13
- Created `PulseProfile` (`scripts/resources/pulse_profile.gd`) with noise and expand time helper methods
- Created `EnemyProfile` (`scripts/resources/enemy_profile.gd`) for AI parameters per AI §2, ARCH §13
- Created `LevelData` (`scripts/resources/level_data.gd`) for parsed ASCII levels
- Created `PaletteData` (`scripts/resources/palette_data.gd`) for theme and accessibility palettes

## P0-T4 Resource data files
- Generated `default_config.tres` with default gameplay values
- Generated 4 pulse profiles: `pulse_whisper.tres`, `pulse_normal.tres`, `pulse_scream.tres`, `pulse_decoy.tres`
- Generated 4 enemy profiles: `enemy_listener.tres`, `enemy_sentry.tres`, `enemy_hunter.tres`, `enemy_brute.tres`
- Generated 2 palette profiles: `palette_default.tres`, `palette_colorblind.tres`

## P0-T5 Core autoloads
- Created `autoload/game_config.gd` (`GameConfig`) loading config, pulse profiles, and enemy profiles
- Created `autoload/palette_service.gd` (`Palette`) providing color queries, runtime colorblind toggle, and `palette_changed` signal
- Created `autoload/debug_flags.gd` (`DebugFlags`) with F1/F2 toggle handling and debug logging
- Created `scripts/core/math_util.gd` (`MathUtil`) with ease_out_cubic, wave_radius, bubble_brightness, and ring_alpha functions
- Registered `GameConfig`, `Palette`, and `DebugFlags` in `project.godot`

## P0-T6 Stub autoloads
- Created `scripts/core/noise_event.gd` (`NoiseEvent`) with NoiseType enum and factory method
- Created `autoload/noise_bus.gd` (`NoiseBus`) with `noise_emitted` signal and debug log
- Created `autoload/pulse_registry.gd` (`PulseRegistry`) with `reveal_at`, `player_revealed`, and bubble tracking
- Created `autoload/game_state.gd` (`GameState`) with run stats, detections, fragment tracking, and level signals
- Created `autoload/scene_router.gd` (`SceneRouter`) with scene transitions, level loading, and restart methods
- Created `autoload/save_data.gd` (`SaveData`) managing settings and persistence with `user://save.cfg`
- Created `autoload/audio_manager.gd` (`AudioManager`) with SFX playback and reverb methods
- Registered all 9 autoloads in `project.godot` in exact ARCH §7 order

## P0-T7 Main scene & debug overlay shell
- Created `scenes/main/main.tscn` and `main.gd` with node hierarchy per ARCH §9
- Created `scenes/main/boot.gd` logging game, engine, and platform versions
- Created `scenes/debug/debug_overlay.tscn` and `debug_overlay.gd` displaying FPS and page indicators toggled via F1/F2
- Created `scenes/debug/debug_draw.gd` (`DebugDraw`) supporting circle, line, text, and polyline with TTL-based queue drawing
- Set `application/run/main_scene="res://scenes/main/main.tscn"` in `project.godot`

## P0-T8 Test harness
- Created `tests/run_tests.gd` headless test runner extending `SceneTree` dynamically discovering and executing `test_*.gd`
- Created `tests/test_resources.gd` testing all 11 `.tres` resources, whisper/normal/scream pulse noise radii, and MathUtil bubble brightness curves
- Verified TC runs headlessly and reports `ALL TESTS PASSED`

## P0-T9 Font & UI theme
- Bundled Rajdhani fonts (`Rajdhani-Medium.ttf`, `Rajdhani-SemiBold.ttf`) and `OFL.txt` under `assets/fonts/`
- Created `resources/theme/ui_theme.tres` with default font, sizes, Button StyleBoxes, and type variations (`TitleLabel`, `HudLabel`, `LevelNameLabel`, `MenuButton`)
- Registered `gui/theme/custom="res://resources/theme/ui_theme.tres"` in `project.godot`
- Extended `tests/test_resources.gd` to validate theme loading and typography variation sizes

## P1-T1 Player body & motor
- Created `scenes/player/player.tscn` and `player.gd` (CharacterBody2D layer 3, mask 1|2|5) with death handling
- Created `scenes/player/player_motor.gd` handling run (180 px/s), sneak (70 px/s), ground/air accel, fall gravity multiplier (1.35x), max fall speed (900 px/s), crouch collision adjustment (18 to 12 px), and ceiling raycast detection
- Created `scenes/player/player_visual.tscn` and `player_visual.gd` with robot silhouette placeholder (head, body, antenna) supporting facing, poses, and palette color binding
- Added player state and velocity diagnostics to debug overlay page 0

## P1-T2 Jump feel & one-way drop-through
- Implemented jump impulse (-560 px/s for ~87 px apex) in `scenes/player/player_motor.gd`
- Added coyote timer (0.10 s) and input jump buffer (0.12 s)
- Implemented jump cut multiplier (0.45x) on early release of jump key
- Implemented one-way platform drop-through on crouch+jump by disabling layer 2 mask for 0.20 s
- Added jump apex tracking to player motor and debug overlay

## P1-T3 Camera rig
- Created `scenes/fx/camera_rig.tscn` and `camera_rig.gd` with 2x zoom and position smoothing (speed 6.0)
- Implemented horizontal look-ahead (40 px leading facing direction, lerped at 3.0/s)
- Implemented vertical deadzone (24 px) and level boundary limit setting (`set_limits`)
- Added API stubs for trauma shake and zoom punch with warnings

## P1-T4 Gray-box player sandbox
- Created `sandbox/sandbox_player.tscn` and `sandbox_player.gd` (1280x720 room)
- Implemented 3 floors of StaticBody2D geometry with grey Polygon2D visuals
- Added 1-tile (32 px) and 2-tile (64 px) steps for verifying jump height
- Added 3-tile gap (96 px, passable) and 4-tile gap (128 px, impassable)
- Added two layer 2 one-way platforms with drop-through support
- Instanced Player, CameraRig, DebugOverlay, and DebugDraw in the sandbox

## P1-T5 Battery & pulse charger
- Created `scenes/player/battery.gd` managing energy expenditure, regen delay (0.8s), still regen (8/s), and moving regen (3/s)
- Created `scenes/player/pulse_charger.gd` with tier calculation (whisper, normal, scream), energy downgrade logic, and NoiseBus PULSE event emission
- Added `tests/test_pulse_tiers.gd` validating tier charge thresholds and energy downgrade calculation (passed in test runner)
- Updated `scenes/player/player.tscn` and `player.gd` wiring Battery and PulseCharger components
- Added battery energy and charging progress to debug overlay page 0

## P1-T6 Footstep emitter
- Created `scenes/player/footstep_emitter.gd` listening to `PlayerMotor.landed` and walking movement
- Emits `FOOTSTEP` noise events (radius 40 px, loudness 0.5) every 0.30s when on floor, not sneaking, and speed > 40 px/s
- Emits `LAND` noise events (radius 96 px, loudness 1.0) on landing with vertical impact speed > 520 px/s
- Added FootstepEmitter node to `scenes/player/player.tscn` and wired in `player.gd`

## P1-T7 Early HUD: charge rings & battery bar
- Created `scenes/sonar/charge_rings.gd` unshaded Node2D component drawing full/dashed reveal rings and rotating dashed red noise warning rings
- Created `scenes/ui/battery_bar.gd` custom Control with 1 px outline, red fill, ghost segments, drain flash remnants, and low battery blinks
- Created `scenes/ui/hud.tscn` and `hud.gd` binding player battery and pulse charger to the UI
- Instanced ChargeRings in `scenes/player/player.tscn` and HUD in `sandbox/sandbox_player.tscn`

## P2-T1 Reveal texture & PulseBubble
- Created `scenes/sonar/reveal_texture_factory.gd` generating a cached 512x512 RGBA8 radial falloff light texture with smooth vignette border
- Created `scenes/sonar/pulse_bubble.tscn` and `pulse_bubble.gd` with PointLight2D (ADD blend, PCF5 shadows, culling masks 1..4) driven by MathUtil wave radius and brightness curves

## P2-T2 SonarSystem pool
- Created `scenes/sonar/sonar_system.tscn` and `sonar_system.gd` managing pool of 6 PulseBubbles with oldest-recycling policy
- Added automatic connection to player PulseCharger.pulse_released events
- Implemented expanding wavefront detection triggering `on_wavefront` on nodes in group `wave_reactive`
- Implemented shader parameter generation (`pulse_data` and `pulse_style` arrays) for the sonar air material
- Added active bubble metrics (age, radius, energy) to debug overlay page 2

## P2-T3 flat_reveal & sonar_air shaders
- Created `shaders/flat_reveal.gdshader` turning point light coverage into crisp silhouette reveals with soft rim and hatch support
- Created `shaders/sonar_air.gdshader` rendering distance-field wavefront arcs and trailing rings occluded by point lights

## P2-T4 Rough edge lines
- Created `shaders/edge_line.gdshader` for soft line bloom falloff on platform borders
- Created `scenes/world/edge_line_factory.gd` generating procedural jagged white Line2Ds with FastNoiseLite jitter, glow outlines, and top-edge tufts/specks

## P2-T5 Parallax background silhouettes
- Created `scenes/world/bg_prop_factory.gd` generating pipes, pillars, gantries, hanging cables, lamps, vents, and machine blocks on render layer 2
- Created `scenes/world/background_builder.gd` creating 3 Parallax2D layers (Far, Mid, Near) with palette tints and scroll factors (0.35, 0.60, 0.85)

## P2-T6 Reveal query & ripple rings
- Implemented `PulseRegistry.reveal_at(pos)` querying active bubbles with direct space state line-of-sight raycasts
- Created `scenes/sonar/ripple_rings.gd` unshaded Node2D drawing expanding 3-concentric arc ripples for noise events
## P2-T7 Sonar vertical slice sandbox
- Created `sandbox/sandbox_sonar.gd` with debug pulse spawners (1/2/3), CanvasModulate toggle (C), multi-bubble stress test (L), and quality toggle (Q)
- Created `sandbox/sandbox_sonar.tscn` 40x22 dark room with 3 floors, pillars, ceiling overhang, 2 one-way catwalks, occluders, procedural jagged edges, SonarAir, SonarSystem, CameraRig, HUD, and 3 dummy silhouettes
- Equipped Player with radial GlowLight PointLight2D with shadow casting

## P3-T1 Node-based StateMachine & State
- Created `scripts/core/state.gd` (`State`) with enter, exit, update, physics_update, and transition helper
- Created `scripts/core/state_machine.gd` (`StateMachine`) managing child State nodes and state transitions with payload and force flags
- Created `tests/test_state_machine.gd` unit tests verifying state enter/exit sequencing and payload routing

## P3-T2 NoiseBus & HearingComponent
- Updated `autoload/noise_bus.gd` to dispatch noise events to the `listeners` group
- Created `scenes/enemies/hearing_component.gd` with wall count raycasting, attenuation math, and sound propagation delay timer
- Created `tests/test_hearing.gd` testing hearing threshold, wall attenuation penalty, distance checks, and enemy profile type filters

## P3-T3 EnemyBase & Core Perception Components
- Created `scenes/enemies/awareness.gd` (`Awareness`) tracking alert accumulation on noise/sight and decay over time
- Created `scenes/enemies/noise_memory.gd` (`NoiseMemory`) ring buffer with time-based 20s expiry
- Created `scenes/enemies/vision_component.gd` (`VisionComponent`) checking reveal threshold, sight cone, and line-of-sight raycasts
- Created `scenes/enemies/enemy_base.tscn` and `enemy_base.gd` (`EnemyBase`) coordinating perception components, gravity, facing, and contact hitbox

## P3-T4 PlatformMover Flat Mode
- Created `scenes/enemies/platform_mover.gd` (`PlatformMover`) with flat mode horizontal navigation, wall collision stop, ledge raycast detection, and patrol segment floor probing

## P3-T5 Listener FSM & Visual
- Created 5 listener state scripts (`st_patrol.gd`, `st_investigate.gd`, `st_search.gd`, `st_chase.gd`, `st_return.gd`) implementing patrol segment navigation, noise investigation, visual search, and detection chasing
- Created `scenes/enemies/visuals/listener_visual.tscn` and `listener_visual.gd` with silhouette, antenna, and alert tell overlays
- Created `scenes/enemies/listener.tscn` integrating enemy base, listener profile, visual, and 5-state StateMachine

## P3-T6 Enemy Shaders & Smudge
- Created `shaders/enemy_silhouette.gdshader` with danger color, alert 12Hz flicker, and state change flash
- Created `shaders/smudge_blur.gdshader` with domain-warped soft radial blob
- Created `scenes/enemies/smudge.tscn` and `smudge.gd` (`Smudge`) spawning in SenseLayer to render unrevealed presence cues with 1.2s fade-out
- Hooked enemy awareness alert updates, state flashes, and smudge triggers into `EnemyBase` and `ListenerVisual`

## P3-T7 Enemy Debug Page & Sandbox Enemy
- Updated `scenes/debug/debug_overlay.gd` to display enemy telemetry, states, awareness, vision cones, mover paths, and memory markers on Page 0
- Created `sandbox/sandbox_enemy.gd` and `sandbox/sandbox_enemy.tscn` featuring an active Listener enemy on patrol, right-click target steering, SenseLayer, unrevealed red smudge cues, and pulse interaction

## Checkpoint: Phase 3 Hearing and Listener
- Complete hearing and enemy state machine architecture functional; Listener patrols in darkness, ignores whisper, investigates normal/scream pulses, searches, and chases player with red smudge presence cues

## P4-T1 ASCII LevelParser
- Created `scenes/level/level_parser.gd` (`LevelParser`) parsing ASCII header lines and grid matrices into `LevelData`
- Created `levels/level_test.txt` 20x8 map containing all 24 legend characters and metadata headers
- Created `tests/test_level_parser.gd` validating header extraction, grid dimensions, spawn/exit coordinates, and legend cell registries

## P4-T2 SolidsBuilder & SolidMerger
- Created `scenes/level/solid_merger.gd` (`SolidMerger`) performing horizontal run grouping and vertical rectangle merging on grid data
- Created `scenes/level/level_builder.gd` (`LevelBuilder`) generating StaticBody2D layer 1 solids with CollisionShape2D, LightOccluder2D, black Polygon2D, and layer 2 one-way platforms

## P4-T3 EdgeBuilder from Grid
- Created `scenes/world/edge_builder.gd` (`EdgeBuilder`) extracting exposed solid cell edges, merging collinear runs, and adding jagged top lines with specks and one-way platform top edges
- Integrated EdgeBuilder into `LevelBuilder.build`

## P4-T4 PlatformGraph & Mover Graph Mode
- Created `scenes/level/platform_graph.gd` (`PlatformGraph`) building AStar2D waypoint networks from ASCII grids with WALK, JUMP (rise <= 2, dx <= 3), and DROP semantics
- Updated `scenes/enemies/platform_mover.gd` to execute graph-based path navigation, jump impulses, and one-way drop-throughs
- Created `tests/test_platform_graph.gd` validating Level 1 pathing, Level 2 jump connectivity, and height clearance restrictions

## P4-T5 LevelValidator
- Created `scenes/level/level_validator.gd` (`LevelValidator`) verifying map dimensions, borders, entity constraints, door pairing, vent pairs, and exit path reachability
- Created `tests/test_validator.gd` asserting all map files pass validation while synthetic broken maps trigger appropriate failures

## P4-T6 EntitySpawner & LevelRoot
- Created `scenes/level/entity_spawner.gd` (`EntitySpawner`) instantiating player, enemies, bounds, and logging stub warnings for unimplemented entities
- Created `scenes/level/level_root.tscn` and `level_root.gd` (`LevelRoot`) assembling full level pipeline: parsing, validation, background, level builder, platform graph, entity spawner, camera rig limits, and sonar air sizing
## P4-T7 SceneRouter & Levels 1-2
- Created `levels/level_01.txt` (Wake) and `levels/level_02.txt` (Listen) per LVL §4
- Updated `autoload/scene_router.gd` with level loading, instant restart, next level transition with screen fade, and F3 debug level-skip key
- Configured `scenes/main/main.gd` to boot directly into Level 1

## P5-T1 Base Interactables, Fragment, Keycard, and ExitTerminal
- Created `scenes/interactables/interactable.gd` (`Interactable`) and `interactable.tscn` providing layer 5 Area2D collision, player/enemy virtual handlers, and noise emission helpers
- Created `scenes/interactables/fragment.gd` (`Fragment`) and `fragment.tscn` with diamond polygon, bob animation, and `GameState.collect_fragment` integration
- Created `scenes/interactables/keycard.gd` (`Keycard`) and `keycard.tscn` with card visual and `GameState.has_keycard` trigger
- Created `scenes/interactables/exit_terminal.gd` (`ExitTerminal`) and `exit_terminal.tscn` with stand, unshaded blinking beacon dot, "SIGNAL RESTORED" sequence, and `GameState.complete_level` / `SceneRouter.next_level` transitions
- Updated `EntitySpawner` to spawn Fragments, Keycards, and Exit Terminals into the level interactables tree

## P5-T2 Doors & Pressure Plates
- Created `scenes/interactables/door.gd` (`Door`) and `door.tscn` supporting KEY and PLATE unlock modes, StaticBody2D layer 1 collision, LightOccluder2D, visual glyphs, platform graph node opening, and upward tween animation
- Created `scenes/interactables/pressure_plate.gd` (`PressurePlate`) and `pressure_plate.tscn` triggering the `plate_doors` group upon player or enemy contact with PLATE noise emission
- Updated `EntitySpawner` to pair vertical door cells into unified door instances and instantiate pressure plates

## P5-T3 One-Way Doors
- Created `scenes/interactables/one_way_door.gd` (`OneWayDoor`) and `one_way_door.tscn` with directional player pass-through sensor, chevron visuals, and non-occluding collision
- Updated `scenes/level/platform_graph.gd` to constrain horizontal WALK graph edges to the permitted direction through `>` and `<` cells
- Updated `EntitySpawner` to instantiate directional one-way doors for `>` and `<` map runs

## P5-T4 Glass Floor
- Created `shaders/glass_crack.gdshader` rendering cellular Voronoi cracks with flat reveal lighting
- Created `scenes/interactables/glass_floor.gd` (`GlassFloor`) and `glass_floor.tscn` with wave reactive crack/shatter, brute step detection, shard particles, GLASS noise emission, and platform graph standable updates
- Updated `EntitySpawner` to instantiate glass floor blocks from ASCII `G` cells

## P5-T5 Lantern
- Created `scenes/interactables/lantern.gd` (`Lantern`) and `lantern.tscn` featuring damped angular spring dynamics, tier-based wavefront impulse reactions, and throttled CLINK noise emission
- Updated `EntitySpawner` to instantiate suspended ceiling lanterns for `~` cells

## P5-T6 Vents
- Created `scenes/interactables/vent.gd` (`Vent`) and `vent.tscn` supporting INTAKE, OUTLET, and MUTE modes with grate visual and area monitoring
- Updated `autoload/noise_bus.gd` with resonance rerouting from intake vents to paired outlet vents with amplified radius, loudness, and 0.2s propagation delay
- Integrated pulse charger noise dampening (0.3x) when player is inside mute vent zone
- Updated `EntitySpawner` to pair i-th intake `V` with i-th outlet `v` in reading order and spawn mute vents `M`

## P5-T7 Sentry & Projectile
- Created `scenes/enemies/projectile.gd` (`Projectile`) and `projectile.tscn` with unshaded reticle ring, 420 px/s speed, player lethal impact, and wall IMPACT noise
- Created `scenes/enemies/visuals/sentry_visual.gd` (`SentryVisual`) and `sentry_visual.tscn` with rotating head and dashed red laser line
- Created `scenes/enemies/states/st_sentry_idle.gd` (`StSentryIdle`), `st_sentry_aim.gd` (`StSentryAim`), and `st_sentry_fire.gd` (`StSentryFire`) implementing sweep, aim/track, and projectile burst routines
- Created `scenes/enemies/sentry.tscn` without gravity and with disabled contact hitbox
- Updated `scenes/enemies/vision_component.gd` and `enemy_base.gd` with omnidirectional `facing_direction` support
- Updated `EntitySpawner` to spawn Sentry turrets from `S` cells

## P5-T8 Hunter
- Created `scenes/enemies/states/st_hunter_track.gd` (`StHunterTrack`) implementing FIFO noise memory inspection, sprint acceleration on loudness >= 3, and 1.2s periodic ENEMY ripple tell
- Created `scenes/enemies/visuals/hunter_visual.gd` (`HunterVisual`) and `hunter_visual.tscn` with predatory silhouette, sensor ears, and alert/flash shaders
- Created `scenes/enemies/hunter.tscn` inheriting `enemy_base.tscn` with `Track` state and Hunter enemy profile
- Updated `scenes/enemies/noise_memory.gd` with 48px spatial deduplication and `pop_oldest()`
- Updated `st_patrol.gd`, `st_search.gd`, `st_return.gd`, and `st_chase.gd` to integrate Hunter `Track` state transitions and 1.0s red ripple double-ping during chase
- Created `scenes/level/interactable_spawner.gd` to maintain strict single responsibility and keep `entity_spawner.gd` well under 250 lines
- Updated `scenes/level/entity_spawner.gd` to spawn Hunter enemies from `H` cells

## P5-T9 Brute
- Created `scenes/enemies/states/st_brute_wander.gd` (`StBruteWander`) implementing segment patrol, 0.7s step thud ripples (ENEMY type, loudness 0), and camera shake trauma (+0.03) when within 160 px of player
- Created `scenes/enemies/states/st_brute_charge.gd` (`StBruteCharge`) with exclamation tell, red flash, run speed rushing, and arrival / wall collision transitions to Stunned
- Created `scenes/enemies/states/st_stunned.gd` (`StStunned`) with 1.2s head shake and transition to Search
- Created `scenes/enemies/visuals/brute_visual.gd` (`BruteVisual`) and `brute_visual.tscn` featuring bulky silhouette, tell label, flash shader, and sinusoidal head shake stun animation
- Created `scenes/enemies/brute.tscn` inheriting `enemy_base.tscn` with `brute` group, Wander initial state, and deaf vibration profile
- Updated `st_search.gd` and `st_return.gd` to route to Charge and Wander for Brute state transitions
- Updated `scenes/level/entity_spawner.gd` to spawn Brute enemies from `B` cells

## P5-T10 GameState Rules & Medals
- Updated `autoload/game_state.gd` with complete run statistics tracking (`time`, `pulses` dictionary by tier, `loudest`, `detections`, `fragments`, `level_index`), run reset on level load, and `compute_medal` evaluating Ghost, Quiet, and Loud medals per GDD §8
- Updated `scenes/player/player.gd` with death handling (input disable, velocity zeroing, visual hide), delayed restart via `SceneRouter.restart_level()`, fall-out kill (`y > map_bottom + 200`), and automatic pulse registration via `PulseCharger`
- Updated `scenes/level/level_root.gd` to assign `map_bottom` to player instance from level data height
- Created `tests/test_medals.gd` covering all medal calculation rules and edge cases

## P6-T1 Post FX
- Created `shaders/post_fx.gdshader` per SHD §10 implementing screen vignette, pseudo-random film grain, 5-tap cross blur bright-pass bloom, monochromatic chromatic aberration offset, and detection flash
- Created `scenes/fx/post_fx.gd` (`PostFx`) and `post_fx.tscn` listening to scream pulses (triggering 0.012 CA burst decaying over 0.4s), enemy detections (triggering 0.35 flash and 0.008 CA burst), and debug key `P`
- Instanced `post_fx.tscn` into `Main/PostFx` CanvasLayer (layer 10) in `scenes/main/main.tscn`

## P6-T2 Camera Juice & Hit-Stop
- Created `scenes/fx/hitstop.gd` (`HitStop`) static helper freezing `Engine.time_scale` to 0.05 for 0.08s real-time duration
- Updated `scenes/fx/camera_rig.gd` (`CameraRig`) joining `camera_rig` group, implementing trauma quadratic shake model (decaying at 1.5/s with 10px amplitude), scream zoom punch (2.0 -> 2.12 -> 2.0), detection zoom punch (2.0 -> 2.06 -> 2.0), and death hit-stop + trauma trigger

## P6-T3 Robot Procedural Animation & Death Burst
- Created `scenes/player/death_burst.gd` (`DeathBurst`) and `death_burst.tscn` with 60 explosive square particles (180° spread, 300 gravity, 0.9s lifetime) auto-freeing on completion
- Updated `scenes/player/player_visual.tscn` with articulated body, head, unshaded eye dot, antenna with tip, 2-segment legs, and arms
- Updated `scenes/player/player_visual.gd` (`PlayerVisual`) implementing procedural animations for Idle (bob + wobble), Run (scissor legs, body bob, forward lean), Sneak (lowered squat, folded antenna), Jump/Fall, Land (squash recovery), Charge vibration, and Death disintegration with lingering eye pop

## P6-T4 Enemy Animations & Alert Glyphs
- Updated all enemy visual controllers (`listener_visual.gd`, `sentry_visual.gd`, `hunter_visual.gd`, `brute_visual.gd`) with unshaded Rajdhani-SemiBold 14 alert glyphs ("!" on chase, "?" on investigate) featuring pop-scale (0 -> 1.3 -> 1.0 in 0.18s), 0.6s hold, and 0.2s fade
- Implemented Listener 360° dish spin on alert and idle wobble
- Implemented Sentry 3px weapon recoil on fire and dashed aiming laser
- Implemented Hunter ear flattening in Track mode and sprint body stretch
- Implemented Brute 10 Hz ±8° head shake stun animation and flash synchronization

## P6-T5 Particles Factory
- Created `scenes/fx/particles_factory.gd` (`ParticlesFactory`) static particle manager with global alive cap <= 300
- Implemented static particle creators for Landing dust (6 particles), Glass shatter (24 particles), Fragment pickup (16 unshaded particles), Terminal signal restoration stream (40 particles), and Projectile wall impact (8 particles)
- Integrated factory calls into `fragment.gd`, `glass_floor.gd`, `exit_terminal.gd`, `projectile.gd`, and `player_motor.gd` (hard landings > 250 px/s)
- Displayed active particle count in `DebugOverlay` HUD

## P6-T6 Synth SFX & Audio Manager
- Created `default_bus_layout.tres` with Master Limiter (-1 dB), Music LPF, SFX bus, Pulse bus with Reverb, Ambience bus with Reverb, and UI bus
- Created `audio/synth.gd` (`Synth`) providing static DSP primitives (`sine`, `saw`, `square`, `noise`, `env_exp`, `glide`, `echo`, `lowpass_onepole`, and 16-bit little-endian mono 44.1 kHz `to_wav`)
- Created `audio/sfx_library.gd` (`SfxLibrary`) procedurally generating all 20 game audio effects at boot in ~200 ms (< 1500 ms spec limit)
- Updated `autoload/audio_manager.gd` (`AudioManager`) with a pool of 12 non-positional players, 8 positional players, dedicated Pulse player, dynamic Pulse reverb control, and automatic NoiseBus / pulse cue playback

## P6-T7 Music Layers
- Created `audio/music_layers.gd` (`MusicLayers`) with 4 synchronized procedural 8s loops (L0 ambient drone, L1 heartbeat pulse, L2 detuned tension pad, L3 120 BPM chase beat) dynamically fading based on alert level
- Updated `autoload/game_state.gd` with 10 Hz awareness sampling and 1.5s smoothed `alert_level` tracking
- Integrated player death low-pass muffle effect dropping Music bus filter cutoff to 800 Hz for 0.6s
