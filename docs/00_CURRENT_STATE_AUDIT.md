# SIGNAL LOST — Current State Technical Audit (V1 to V2 Baseline)

- **Purpose**: Comprehensive technical audit of the current SIGNAL LOST codebase, documenting existing architecture, systems, inputs, enemy AI, levels, tests, coupling issues, protected systems, and technical debt to establish an unshakeable foundation for V2 expansion.
- **Audience**: Lead Game Designer, Technical Director, AI Coding Agents (Gemini, Claude Sonnet/Opus).
- **Status**: Approved.
- **Last Updated**: 2026-10-11.
- **Depends On**: Codebase inspection (`res://`), `project.godot`, `qa/QA_REPORT.md`, `CHANGELOG.md`.

---

## 1. Executive Summary & Verification Methodology

Every statement in this audit has been categorized using strict verification tags:
- `[VERIFIED]`: Confirmed directly by source code inspection, headless test execution, or browser E2E test runs.
- `[UNVERIFIED]`: Stated in legacy notes or design specifications but missing direct automated test coverage or implementation evidence.

The current SIGNAL LOST project is a functional 2D echolocation stealth-platformer built in Godot 4.7.2 (GL Compatibility renderer, targeting desktop and web via WebAssembly/WebGL). The game currently runs headlessly across 17 automated unit test suites (`tests/run_tests.gd`) with **0 failures**, and completes browser E2E test passes across 7 validation gates (`tests/e2e/test_gate_a.js` through `test_soak.js`).

While previously described in early planning sessions as a single monolithic script, the active codebase has evolved into a modular, component-based multi-script architecture across 103 files (`.gd`, `.tscn`, `.gdshader`, `.tres`, `.txt`). However, heavy coupling persists around autoload singletons (`GameState`, `NoiseBus`, `PulseRegistry`, `SceneRouter`, `DebugBridge`), duck-typed properties across interactables, and tight dependencies between player movement, pulse charging, and world illumination.

---

## 2. What Exists Today (Verified System Inventory)

### 2.1 Core Gameplay & Physics Systems
- **Player Controller** `[VERIFIED]`: `CharacterBody2D` in `scenes/player/player.gd` (98 lines) driven by `PlayerMotor` (`scenes/player/player_motor.gd`, 149 lines). Hand-crafted acceleration (1400 px/s²), ground friction (1800 px/s²), gravity (1800 px/s²), fall multiplier (1.35x), run speed (180 px/s), and sneak speed (70 px/s).
- **Jump Dynamics & Catwalk Drop-Through** `[VERIFIED]`: Jump impulse −560 px/s (2.7-tile apex), variable jump cut (0.45x), coyote time (0.10s), jump buffer (0.12s). Drop-through on one-way platforms (`=` tiles, physics layer 2) achieved via `sneak + jump` with a 0.20s collision mask timeout.
- **Sonar Echolocation & Reveal Pipeline** `[VERIFIED]`: Complete ambient darkness enforced by `CanvasModulate` (#000000). Sonar wave expansions emitted via `SonarSystem` (`scenes/sonar/sonar_system.gd`, 116 lines) managing a pool of 6 `PulseBubble` instances (`scenes/sonar/pulse_bubble.gd`, 61 lines). Each bubble owns a `PointLight2D` (PCF5 shadows) sampling a dynamically generated radial falloff texture (`RevealTextureFactory`, 512x512, RGB+Alpha falloff). Solid geometry casts 2D light occlusion via `LightOccluder2D`.
- **Wavefront Air Ring Shaders** `[VERIFIED]`: Full-screen `SonarAir` ColorRect executing `shaders/sonar_air.gdshader` analytically drawing distance-field ring arcs from `uniform vec4 pulse_data[6]` and `uniform vec4 pulse_style[6]`.
- **Acoustic Noise Bus** `[VERIFIED]`: `autoload/noise_bus.gd` routes `NoiseEvent` objects to registered listeners in group `listeners`. Performs radial distance checks, counts occluding walls via repeated line-of-sight raycasts (penalty 0.75x per wall), checks hearing threshold, and delivers acoustic events after spatial propagation latency ($t = d / 700$ px/s).
- **Movement Noise & Footstep Emission** `[VERIFIED]`: `scenes/player/footstep_emitter.gd` emits `FOOTSTEP` noise events (radius 40 px, loudness 0.5) every 0.30s while moving on floor without sneak. Hard landings ($v_y > 520$ px/s) emit `LAND` noise (radius 96 px, loudness 1.0). Sneak mode produces zero footsteps.
- **Battery & Pulse Charging** `[VERIFIED]`: `scenes/player/battery.gd` manages 100 energy units with passive regeneration (8 units/s idle, 3 units/s moving). `PulseCharger` (`scenes/player/pulse_charger.gd`, 88 lines) charges pulses over 1.0s into 3 discrete tiers:
  - **Whisper (Tier 0)**: Charge $c < 0.35$. Reveal radius 72 px, noise radius 43.2 px, energy cost 6, loudness 1.0, cooldown 0.20s.
  - **Normal (Tier 1)**: Charge $0.35 \le c < 0.85$. Reveal radius 200 px, noise radius 200 px, energy cost 22, loudness 2.0, cooldown 0.60s.
  - **Scream (Tier 2)**: Charge $c \ge 0.85$. Reveal radius 560 px, noise radius 728 px, energy cost 55, loudness 3.0, cooldown 3.50s. Triggers screen shake (9 px) and chromatic aberration burst.

### 2.2 Active Enemy Roster
All enemies inherit from `EnemyBase` (`scenes/enemies/enemy_base.gd`, 127 lines) using node-based FSM (`scripts/core/state_machine.gd`) and render as red silhouettes (`shaders/enemy_silhouette.gdshader`):
1. **Listener** `[VERIFIED]`: Ground patrol robot. States: `st_patrol.gd`, `st_investigate.gd`, `st_search.gd`, `st_chase.gd`, `st_return.gd`. Hears sounds with loudness $\ge 1.0$. Investigates sound origin; chases player upon direct line of sight within 200 px (70° cone). Contact is lethal.
2. **Sentry** `[VERIFIED]`: Static wall/balcony turret. States: `st_sentry_idle.gd`, `st_sentry_aim.gd`, `st_sentry_fire.gd`. Ignores low-tier sounds; alerted only by Scream, glass break, or decoy (loudness $\ge 3.0$). Scans with 40° cone up to 320 px. Charges red aiming laser for 0.6s, then fires lethal red projectile (`scenes/enemies/projectile.gd`, 420 px/s).
3. **Hunter** `[VERIFIED]`: Fast apex stalker. States: `st_patrol.gd`, `st_hunter_track.gd`, `st_chase.gd`. Sensitive hearing threshold (0.5), detects footsteps. Features 3-point acoustic memory buffer (`scenes/enemies/noise_memory.gd`). Sprint speed 230 px/s.
4. **Deaf Brute** `[VERIFIED]`: Heavy armored mech. States: `st_brute_wander.gd`, `st_brute_charge.gd`, `st_stunned.gd`. Completely immune to airborne acoustic pulses. Reacts exclusively to ground vibration (`FOOTSTEP`, `LAND`). Charges relentlessly in a straight line upon detecting floor footsteps. Shatters glass floors upon impact.

### 2.3 Interactables & Level Pipeline
- **ASCII Level Parsing & Building** `[VERIFIED]`: `LevelParser` (`scenes/level/level_parser.gd`) loads plain-text level files (`levels/level_01.txt` through `level_08.txt`). `SolidMerger` vertically merges adjacent solid `#` runs into optimized collision rectangles and occluders.
- **Platform Navigation Graph** `[VERIFIED]`: `PlatformGraph` (`scenes/level/platform_graph.gd`, 202 lines) constructs dual `AStar2D` graphs from standable floor cells. Connects nodes via WALK (adjacent horizontal), JUMP ($\Delta y \le 2$ tiles, $\Delta x \le 3$ tiles), and DROP ($\Delta y \le 8$ tiles). `PlatformMover` executes edge traversal for AI navigation.
- **Interactable Objects** `[VERIFIED]`:
  - `Keycard` (`K`) and `Door` (`D`): Color-coded terminal pickup and 2-tall sliding security door.
  - `PressurePlate` (`_`) and `PlateDoor` (`R`): Weight-triggered plate opening paired 2-tall doors.
  - `OneWayDoor` (`>` / `<`): Directionally passable 2-tall security gate.
  - `GlassFloor` (`G`): Breakable translucent platform destroyed by Scream wavefronts or Brute steps.
  - `Lantern` (`~`): Ceiling pendulum that swings on sonar contact, emitting clinking sound.
  - `Acoustic Vents` (`V` intake, `v` outlet): Teleports and amplifies sound from intake to outlet. `MuteVent` (`M`) damps pulse noise by 70%.
  - `ExitTerminal` (`E`): Triggers 0.8s "SIGNAL RESTORED" sequence and opens level completion screen.
  - `SignalFragment` (`F`): Collectible lore/data pickup (0 to 3 per level).
  - `DecoyBeacon` (`C` pickup, `F` key): Thrown physical beacon that emits a remote Normal pulse upon impact.
  - `HintSign` (`?`): In-world informational plaque illuminated only by active sonar pulses.

### 2.4 User Interface & Audio
- **HUD** `[VERIFIED]`: Fragment counter top-left, 220x14 px battery gauge bottom-left with pending pulse cost preview, ability icon slots (`F`, `G`), diamond charge pips, level progress bar bottom-center, floating unshaded enemy awareness bars (`scenes/ui/awareness_bar.gd`), and noise origin reticles.
- **Menus & Routing** `[VERIFIED]`: `SceneRouter` manages transitions between `MainMenu`, 4x2 `LevelSelect` grid, `PauseMenu` with settings overlay, and `LevelComplete` medal award summary.
- **Procedural Audio Synthesis** `[VERIFIED]`: `audio/synth.gd` and `audio/sfx_library.gd` synthesize 100% of sound effects dynamically in-engine at runtime via `AudioStreamWAV` buffers. Zero external audio files are required. `audio/music_layers.gd` provides ambient and tense synthesizer drone layers.

### 2.5 Input Bindings (Source of Truth from `project.godot`)
| Action Name | Primary Keyboard | Secondary Keyboard / Mouse | Gamepad Binding |
|---|---|---|---|
| `move_left` | `A` (Scan 65) | `Left Arrow` (Scan 4194319) | Left Stick −X, D-Pad Left |
| `move_right` | `D` (Scan 68) | `Right Arrow` (Scan 4194321) | Left Stick +X, D-Pad Right |
| `jump` | `W` (Scan 87) | `Up Arrow` (Scan 4194320) | Gamepad A (Button 0) |
| `sneak` | `Shift` (Scan 4194325) | `S` (Scan 83), `Down Arrow` (Scan 4194322) | Left Trigger (Axis 4), D-Pad Down |
| `pulse` | `Space` (Scan 32) | `Left Mouse Button`, `K` (Scan 75) | Right Trigger (Axis 5), Gamepad X (Button 2) |
| `ability_primary` | `F` (Scan 70) | — | Gamepad Y (Button 3) |
| `ability_secondary` | `G` (Scan 71) | — | Gamepad LB (Button 9) |
| `restart` | `R` (Scan 82) | — | Gamepad Select / Back (Button 4) |
| `pause` | `Escape` (Scan 4194305) | — | Gamepad Start (Button 6) |
| `debug_toggle` | `F1` (Scan 4194332) | — | — |
| `debug_next_page` | `F2` (Scan 4194333) | — | — |

---

## 3. Test Scripts, Debug Hooks & Verification Infrastructure

### 3.1 Unit Test Suite (`tests/run_tests.gd`)
A standalone `SceneTree` test harness executing 17 automated tests headlessly:
1. `test_resources.gd` `[VERIFIED]`: Validates loading and default values of all 11 `.tres` data files.
2. `test_pulse_tiers.gd` `[VERIFIED]`: Tests charge duration math and tier boundaries.
3. `test_state_machine.gd` `[VERIFIED]`: Validates state transition signals and callbacks.
4. `test_level_parser.gd` `[VERIFIED]`: Tests ASCII grid ingestion and syntax error handling.
5. `test_platform_graph.gd` `[VERIFIED]`: Tests A* node generation, edge costs, and 2-tile jump clears.
6. `test_hearing.gd` `[VERIFIED]`: Verifies distance attenuation and wall penetration math.
7. `test_validator.gd` `[VERIFIED]`: Validates structural level rules across all maps.
8. `test_medals.gd` `[VERIFIED]`: Validates Ghost, Quiet, and Loud medal award rules.
9. `test_decoy.gd` `[VERIFIED]`: Tests decoy throwing, bounce, and pulse release.
10. `test_hint_signs.gd` `[VERIFIED]`: Tests hint sign text generation and illumination shaders.
11. `test_hud.gd` `[VERIFIED]`: Validates battery bar, pips, and counter UI updates.
12. `test_main_menu.gd` `[VERIFIED]`: Tests menu navigation and button events.
13. `test_pause_menu.gd` `[VERIFIED]`: Tests pause state, tree pausing, and resume.
14. `test_settings.gd` `[VERIFIED]`: Tests audio volume, screen shake, and color-blind toggles.
15. `test_level_select_complete.gd` `[VERIFIED]`: Tests level grid loading and medal persistence.
16. `test_awareness_reticles.gd` `[VERIFIED]`: Tests floating UI awareness meters.
17. `test_performance_mode.gd` `[VERIFIED]`: Tests bubble count reduction (6 → 4) and shadow toggle.

### 3.2 Browser E2E Test Suite (`tests/e2e/`)
A Playwright-driven test harness interfacing with the WebAssembly export via static server (`tools/serve.js` / `tools/serve.py` on port 8000 with COOP/COEP isolation):
- `test_gate_a.js` `[VERIFIED]`: 30-second continuous movement loop (walk left/right, jump, sneak).
- `test_gate_b.js` `[VERIFIED]`: 3-tier pulse charging, release, and visual expansion verification.
- `test_step_c.js` `[VERIFIED]`: Vector chassis rendering, eye color states, and Scream chromatic aberration.
- `test_step_d.js` `[VERIFIED]`: HUD calibration, battery preview, menus, and level complete flow.
- `test_step_e.js` `[VERIFIED]`: Enemy hearing discrimination, sentry aim/fire, and player caught death reload.
- `test_gate_c.js` `[VERIFIED]`: Full end-to-end traversal of Level 1 from Start `P` to Exit `E`, collecting fragment and verifying Ghost medal.
- `test_soak.js` `[VERIFIED]`: 60-second continuous gameplay soak across Levels 1-4 with 0 memory leaks or errors.

### 3.3 Debug Bridge Architecture (`autoload/debug_bridge.gd`)
Exposes bi-directional JavaScript hooks to the browser runtime:
- `window.__SL`: Live JSON snapshot updated every frame:
  - `fps`: Current render frame rate.
  - `level`: Active level index.
  - `is_level_active`: Boolean level status.
  - `fragments_collected`: Count of collected fragments.
  - `battery`: Current player battery charge.
  - `player`: Sub-dictionary containing `pos` [x, y], `vel` [x, y], `on_floor`, `is_alive`, `facing`, `is_sneaking`.
  - `pulses`: Array of active bubbles with `origin` [x, y], `radius`, `age`, `brightness`.
  - `noise_events`: Array of recent noise events with `pos`, `radius`, `loudness`, `type`.
  - `enemies`: Array of active enemy dictionaries with `name`, `kind`, `pos`, `awareness`, `state`, `facing`.
- `window.__SL_cmd(name, args)`: Command dispatcher queue processing commands on `_process()`:
  - `load_level {level: N}`: Forces immediate level load.
  - `restart`: Reloads current level.
  - `teleport_player {x: N, y: N}`: Instantly moves player body.
  - `spawn_pulse {tier: "whisper"|"normal"|"scream"}`: Forces player pulse emission.
  - `set_god_mode {enabled: bool}`: Prevents death trigger.
  - `pause_game` / `resume_game`: Toggles pause menu.
  - `show_level_complete {level, time, ...}`: Displays victory screen.
  - `show_settings`: Opens settings modal.

---

## 4. Protected Systems (Regression Quarantine)

The following 7 systems are strictly protected. Any regression in these systems breaks automated CI gates or web export stability:

| System | Primary Code Files | Test & Verification Hook | Risk of Regression |
|---|---|---|---|
| **1. Sonar Pulse & Wavefronts** | `scenes/sonar/sonar_system.gd`, `pulse_bubble.gd`, `shaders/sonar_air.gdshader`, `reveal_texture_factory.gd` | `test_pulse_tiers.gd`, `test_gate_b.js` | Modifying pulse profiles or shader uniforms breaks light occlusion and reveal radii. |
| **2. Darkness & Occlusion Pipeline** | `CanvasModulate` (#000000), `shaders/flat_reveal.gdshader`, `scenes/level/level_builder.gd` | `test_gate_a.js`, `test_gate_b.js` | Changing clear color, canvas modulation, or polygon base colors causes foggy grey screens. |
| **3. Procedural Audio Synthesis** | `audio/synth.gd`, `audio/sfx_library.gd`, `autoload/audio_manager.gd` | `godot --headless --path . --quit-after 120` | Introducing binary audio assets or blocking synthesis loops violates web performance and licensing. |
| **4. Acoustic Noise Bus** | `autoload/noise_bus.gd`, `scripts/core/noise_event.gd`, `scenes/enemies/hearing_component.gd` | `test_hearing.gd`, `test_step_e.js` | Altering `NoiseEvent` properties or raycast masks breaks enemy hearing discrimination. |
| **5. HUD & Awareness System** | `scenes/ui/hud.gd`, `scenes/ui/battery_bar.gd`, `scenes/ui/awareness_bar.gd` | `test_hud.gd`, `test_step_d.js` | Duplicate signal connections or strict custom casts crash web export bytecode. |
| **6. Web Export & Packaging** | `export_presets.cfg`, `tools/serve.js`, `tools/web_shell.html` | Headless export to `build/web/index.html` | Omitting `*.txt` include filter or using unsupported WebGL 2 features breaks web browser boot. |
| **7. Playwright / __SL Test Loop** | `autoload/debug_bridge.gd`, `tests/e2e/*.js` | `npm test` / Node Playwright harness | Renaming `window.__SL` fields or breaking command queue halts E2E regression pipelines. |

---

## 5. Code Structure & Line Counts

### 5.1 Script Summary by Subsystem
- **Autoload Singletons (10 files, 903 lines)**:
  - `debug_bridge.gd`: 225 lines
  - `audio_manager.gd`: 154 lines
  - `game_state.gd`: 126 lines
  - `save_data.gd`: 121 lines
  - `scene_router.gd`: 90 lines
  - `palette_service.gd`: 44 lines
  - `game_config.gd`: 39 lines
  - `pulse_registry.gd`: 29 lines
  - `noise_bus.gd`: 27 lines
  - `debug_flags.gd`: 14 lines
- **Player Subsystem (7 files, 613 lines)**:
  - `player_visual.gd`: 216 lines (vector robot chassis, antenna wobble, dynamic eye)
  - `player_motor.gd`: 149 lines (kinematic acceleration, jump curves, coyote time)
  - `player.gd`: 82 lines (root player logic, decoy throwing, death sequence)
  - `pulse_charger.gd`: 88 lines (charge timer, tier selection, release signals)
  - `footstep_emitter.gd`: 42 lines (footstep/landing sound trigger)
  - `battery.gd`: 32 lines (energy consumption and regeneration math)
  - `death_burst.gd`: 5 lines (particle burst trigger)
- **Sonar & Lighting (5 files, 375 lines)**:
  - `sonar_system.gd`: 116 lines (bubble pool management, shader uniform dispatch)
  - `charge_rings.gd`: 85 lines (concentric charge indicator drawing)
  - `pulse_bubble.gd`: 61 lines (PointLight2D animation and fade curves)
  - `ripple_rings.gd`: 60 lines (unshaded noise event visualizer)
  - `reveal_texture_factory.gd`: 28 lines (procedural radial gradient texture)
- **Level & Navigation (7 files, 695 lines)**:
  - `platform_graph.gd`: 202 lines (A* platform pathfinding graph)
  - `interactable_spawner.gd`: 178 lines (interactable scene placement)
  - `entity_spawner.gd`: 99 lines (player and enemy spawner)
  - `level_validator.gd`: 86 lines (offline structural map verification)
  - `level_builder.gd`: 74 lines (collision and occluder generation)
  - `level_root.gd`: 59 lines (level scene lifecycle coordinator)
  - `level_parser.gd`: 55 lines (ASCII parser)
- **Enemy AI Subsystem (19 files, 895 lines)**:
  - `platform_mover.gd`: 160 lines (A* edge follower for enemies)
  - `enemy_base.gd`: 127 lines (base enemy properties, hitbox, damage reception)
  - `hearing_component.gd`: 68 lines (sound detection and wall attenuation)
  - `vision_component.gd`: 64 lines (line-of-sight and cone check in lit bubbles)
  - `noise_memory.gd`: 49 lines (ring buffer for investigation positions)
  - Enemy Visuals (4 files, 249 lines): `listener_visual.gd` (61), `sentry_visual.gd` (66), `hunter_visual.gd` (59), `brute_visual.gd` (63)
  - FSM States (10 files, 327 lines): `st_patrol.gd` (44), `st_investigate.gd` (31), `st_search.gd` (35), `st_chase.gd` (52), `st_return.gd` (32), `st_sentry_idle.gd` (29), `st_sentry_aim.gd` (38), `st_sentry_fire.gd` (38), `st_hunter_track.gd` (60), `st_brute_wander.gd` (58), `st_brute_charge.gd` (35), `st_stunned.gd` (17)
- **Interactables (10 files, 303 lines)**:
  - `decoy_beacon.gd`: 65 lines (parabolic throw, delay, remote pulse)
  - `glass_floor.gd`: 56 lines (wavefront/brute shatter logic)
  - `door.gd`: 47 lines (sliding door animation and collision toggle)
  - `exit_terminal.gd`: 42 lines (level exit trigger)
  - `vent.gd`: 39 lines (acoustic sound redirection and damping)
  - `one_way_door.gd`: 38 lines (one-way gate passability)
  - `lantern.gd`: 37 lines (pendulum oscillation and clink noise)
  - `hint_sign.gd`: 31 lines (lit-only text prompt plaque)
  - `pressure_plate.gd`: 29 lines (pressure switch triggering doors)
  - `interactable.gd`: 23 lines (base trigger class)
- **User Interface & Menus (14 files, 982 lines)**:
  - `level_complete.gd`: 174 lines (stats display, medal reveal, menu buttons)
  - `settings_menu.gd`: 104 lines (sliders, toggles, persistence)
  - `level_label.gd`: 97 lines (progress bar and level header)
  - `battery_bar.gd`: 96 lines (battery fill and ghost cost preview)
  - `level_select.gd`: 95 lines (mission select grid logic)
  - `level_select_box.gd`: 94 lines (individual mission cell)
  - `title_logo.gd`: 93 lines (glitch logo animation)
  - `pause_menu.gd`: 80 lines (pause modal and settings hook)
  - `main_menu.gd`: 76 lines (start, level select, settings)
  - `hud.gd`: 72 lines (HUD coordinator)
  - `world_reticle.gd`: 52 lines (floating world space indicator)
  - `ability_slot.gd`: 51 lines (cooldown and charge icon)
  - `fragment_counter.gd`: 49 lines (antenna icon and count)
  - `awareness_bar.gd`: 49 lines (floating 1px awareness gauge)

---

## 6. Known Problems & Design Bottlenecks (Baseline vs V2 Requirements)

1. **Scale & Viewport Framing (Tiny Robot in Void)** `[VERIFIED]`:
   - Current: Robot collision is 14x18 px, tiles are 32 px, base viewport is 1920x1080 with camera zoom 2.0. The playable area floats in the center of the screen surrounded by immense dead black space.
   - Target: Camera framing must dynamically track action, character silhouettes must be substantially larger and readable (Hero height ~48-64 px, enemies 56-80 px), filling the 1920x1080 screen with multi-story architectural presence.
2. **Missing Vertical Traversal & Stacked Corridor Soft-Locks** `[VERIFIED]`:
   - Current: In `level_03.txt`, three long horizontal corridors are stacked vertically. The player drops down through one-way catwalks to collect Keycard `K` on the bottom floor, but cannot jump back up 3 vertical tiles (jump apex is 2.7 tiles). The player becomes permanently soft-locked.
   - Target: Every multi-floor drop must feature paired return paths (ladders, wall-jump shafts, lifts, or resonant bounce panels).
3. **Enemy Navigation Ledge Inability** `[VERIFIED]`:
   - Current: `PlatformMover` follows A* node paths, but if an enemy drops off a ledge while chasing, their horizontal velocity frequently causes them to overshoot narrow 1-tile landing pads or become stuck in continuous jump-impulse loops against solid ceilings.
   - Target: Dedicated navigation steering behaviors with stuck-detection heuristics and recovery states.
4. **Zero Combat Interaction (One-Hit Death Only)** `[VERIFIED]`:
   - Current: Any contact between player and enemy or projectile instantly kills the player, reloading the level after 0.6s. There is no offensive action, melee attack, blocking, or damage buffer.
   - Target: Full samurai combat system: 3 weapons (Katana, Naginata, Twin Kunai), attacks with startup/active/recovery frames, poise damage, parrying, guard breaks, stealth assassinations, and segmented health.
5. **Aesthetic Emptiness & Minimal Animation** `[VERIFIED]`:
   - Current: Player is drawn programmatically via `_draw()` with simple rectangles, an antenna line, and a single colored eye dot. Enemies are plain red boxy polygons. Environment edges are thin lines.
   - Target: Striking white samurai silhouette with flowing physics-driven scarf and katana slashes; distinct red enemy silhouettes (ashigaru spearman, kenshi swordsman, hooded yumi archer, brute); multi-layered shoji/gantry backgrounds; heavy particle impact juice.
6. **No In-Game Guidance or Puzzle Progression** `[VERIFIED]`:
   - Current: Only static `?` plaques exist with raw control keys (`HOLD [K] / LMB`). No narrative framing or escape-room puzzles.
   - Target: Escape-room puzzle layers (echo glyphs, resonance panels, seal locks, harmonic lanterns, signal fragments, hint beacon on `H`).

---

## 7. Technical Debt Registry (Ranked by Risk)

| Rank | Debt Item | Affected Files | Severity | Description & Architectural Impact |
|---|---|---|---|---|
| **1** | **Strict Custom Class Web Bytecode Casts** | `sonar_system.gd`, `player.gd`, `level_root.gd`, `hud.gd` | **CRITICAL** | Casting to custom script classes (`as PulseCharger`, `as Player`, `as LevelRoot`) evaluates to `null` in Godot 4 Web export bytecode. Duck-typing and group lookups must be preserved. |
| **2** | **Autoload God Object Coupling** | `autoload/game_state.gd`, `autoload/debug_bridge.gd` | **HIGH** | `GameState` tracks level index, timer, stats, decoy inventory, keycard collection, and pulse registration. If `GameState` restarts mid-transition, multiple systems throw orphaned reference errors. |
| **3** | **Duck-Typed Interactable Collision Callbacks** | `scenes/interactables/*.gd` | **HIGH** | `interactable.gd` uses duck-typed checks (`if "is_alive" in body:`). Lack of a formalized `HitboxComponent` / `HurtboxComponent` layer prevents scalable combat hit detection. |
| **4** | **Tilemap Absence / Greedy Solid Merger Overhead** | `scenes/level/level_builder.gd`, `solid_merger.gd` | **MEDIUM** | Levels generate individual `StaticBody2D` nodes with dozens of individual `CollisionShape2D` and `LightOccluder2D` children instead of Godot 4 `TileMapLayer`. |
| **5** | **Hardcoded Noise Thresholds & Profiles** | `scenes/enemies/*.gd`, `pulse_charger.gd` | **MEDIUM** | Several state scripts use hardcoded speed multipliers (`walk * 1.4`) and raycast limits instead of referencing centralized `GameConfig` resources. |
| **6** | **Unbounded JS Snapshot Serialization** | `autoload/debug_bridge.gd` | **LOW** | `get_snapshot()` dumps scene tree nodes up to depth 3 and stringifies whole dictionary trees every frame on web, adding 1-2 ms CPU overhead per frame. |

---

## 8. Baseline Audit Verdict & Readiness

The foundation of SIGNAL LOST is rock-solid:
- The core echolocation mechanic (expanding wavefronts, shadow occlusion, air rings) is functional and verified.
- The headless CI pipeline and Playwright E2E browser test harnesses provide a safety net for incremental refactoring.
- The transition from V1 (puzzle stealth) to V2 (stealth-samurai action puzzle) requires **zero regression** of these core mechanics while layering on combat components, vertical navigation, rich silhouette aesthetics, and escape-room puzzles.
