# Changelog — SIGNAL LOST

All notable changes to this project will be documented in this file.

## Milestone: Phase 5 Implementation — Vertical Level Pipeline & Zero Soft-Locks (100% COMPLETE)
- Upgraded LevelValidator with bidirectional return path checks and jump apex constraints; refactored multi-tier level pipeline (Levels 1–9) and eliminated Level 3 soft-lock with overhead return ladder; added case-insensitive state machine transitions and safe ladder climbing; upgraded camera rig with 48 px look-ahead and dynamic combat zoom; verified 27/27 unit tests, Gates A & B, and Phase 5 E2E test suite with zero errors.

## Milestone: Phase 4 Implementation — Adversary Roster (Part 2 — Kenshi, Yumi & Oni Brute) (100% COMPLETE)
- Implemented Kenshi duelist AI with 40% frontal auto-parry, back-dash evasion, quick draw slash, and spinning unblockable sweep; implemented Yumi balcony archer with 400 px laser aiming, 520 px/s acoustic piercing arrows, and flash pellet repositioning; implemented Oni Brute heavy mech with frontal light attack immunity, club ground slam, and glass floor shattering; verified 27/27 unit tests, Gates A & B, and Phase 4 E2E test suite.

## Milestone: Phase 3 Implementation — Adversary Roster (Part 1 — Ashigaru & Sentry) (100% COMPLETE)
- Integrated HealthComponent, PoiseComponent, and HurtboxComponent into EnemyBase with damage flashes, poise staggers, and death signals; implemented Ashigaru spearman with 27-frame telegraph glint and yari thrust; integrated AttackTokenManager concurrency limits; enabled Katana parry reflection of Sentry projectiles; verified 24/24 unit tests, Gates A & B, and Phase 3 E2E test suite.

## Milestone: Phase 2 Implementation — Weapon Arsenal & Stealth Assassinations (100% COMPLETE)
- Implemented WeaponSwapManager (Q key cycling), WeaponNaginata (52 px reach, 2-hit chain, overhead impale), WeaponKunai (4-hit flurry, silent strikes), AssassinationSystem (unaware rear cone 60° instant lethal takedowns), and Shuriken sub-weapon (F key projectile distraction lure).
- All 23 headless unit tests pass, Gates A and B pass with 0 errors, and Phase 2 E2E weapons suite passes.

## Milestone: Phase 1 Implementation — Combat Primitives & Health Refactor (100% COMPLETE)
- Implemented HealthComponent (3 HP segments, i-frames), PoiseComponent (100 max poise, stagger/break), Hitbox/Hurtbox primitives, and CombatController with Katana 3-hit combo, 6-frame parry deflect, and 12-i-frame dash roll.
- All 21 headless unit tests pass, Gates A and B pass with 0 errors, and Phase 1 E2E combat suite passes.

## Milestone: Phase 0 Implementation — Architectural Hygiene & Baseline Verification (100% COMPLETE)

### P0-T01: Input Map Expansion (VERIFIED 0 ERRORS)
- Expanded input map in `project.godot` with 6 new combat and utility actions: `attack` (J / RMB / Pad X), `attack_heavy` (I / MMB / Pad RB), `dash` (L / Alt / Pad B), `block_parry` (K / Thumb Mouse 4 / Pad LB), `weapon_swap` (Q / Wheel Up/Down / D-Pad Up), and `hint` (H / D-Pad Down).
- Decoupled `K` key and gamepad button 2 from `pulse` action to prevent input conflicts with parry and attack systems.
- Headless syntax verification: `godot --headless --path . --quit-after 120` passed with 0 errors.

### P0-T02: AttackTokenManager Singleton (VERIFIED 0 ERRORS)
- Created `autoload/attack_token_manager.gd` enforcing enemy attack concurrency limit (`max_tokens = 2`).
- Implemented `request_token(actor)`, `release_token(actor)`, waiting queue dispatch, and automated instance cleanup.
- Registered singleton under `[autoload]` in `project.godot` per architecture specification.

### P0-T03: Combat Configuration Resources (VERIFIED 0 ERRORS)
- Created `scripts/resources/attack_data.gd` defining typed `AttackData` resource (damage, poise damage, knockback, hitstop, frame data, reach, noise).
- Created `scripts/resources/combat_config_data.gd` and `resources/config/combat_config.tres` with default combat balance parameters per `docs/GAME_CONFIG_REFERENCE.md`.
- Integrated `combat_config.tres` and `AttackData` regression assertions into `tests/test_resources.gd`.

### P0-T04: Baseline Regression Gate (VERIFIED 0 ERRORS)
- Verified static headless parse: `godot --headless --path . --quit-after 120` returned 0 errors.
- Verified all 17 unit test suites: `godot --headless --path . -s res://tests/run_tests.gd` returned `ALL TESTS PASSED`.
- Built headless Web release bundle: `godot --headless --export-release "Web" build/web/index.html`.
- Executed Playwright Gate A: `node tests/e2e/test_gate_a.js` completed 30 seconds of continuous movement with 0 browser errors and 0 engine errors.
- Evidence screenshots captured in `qa/shots/phase_0/` (`01_gate_a_menu.png` through `07_gate_a_after_30s.png`).

## Milestone: Master V2 Documentation Set Created (100% COMPLETE)
- **Technical Audit Completed**: Conducted factual, verified audit of all 103 files, line counts, global states, protected systems, and technical debt in `docs/00_CURRENT_STATE_AUDIT.md`.
- **Master Documentation Suite Created**:
  - `docs/README_INDEX.md`: Master directory, reading order, and universal gameplay glossary.
  - `docs/GDD.md`: V2 Game Design Document with vision, 5 pillars, core loops, and sonar-combat interlock.
  - `docs/PRD.md`: Product Requirements Document with MoSCoW scope, functional criteria (FR-*), NFRs, and traceability matrix.
  - `docs/TECH_STACK.md`: Engine version (Godot 4.7.2 / 4.4+), GL Compatibility renderer, typed GDScript, and tooling architecture.
  - `docs/ARCHITECTURE.md`: Target modular architecture, scene trees, component model, signal map, and 10-step safe migration plan.
  - `docs/GAME_CONFIG_REFERENCE.md`: Master tunables reference table with every balance variable marked CURRENT or PROPOSED.
  - `docs/INPUT_MAP.md`: Keyboard, mouse, and gamepad mapping matrix with conflict resolution and HUD prompt text.
  - `docs/COMBAT_DESIGN.md` & `docs/COMBAT_FRAME_DATA.md`: 3-weapon combat system, parry/guard windows, stealth finishers, and 60 FPS frame data.
  - `docs/ENEMY_AI.md`: Adversary silhouettes, stats, telegraphs, FSM diagrams, and 3-phase Shogun Mech boss fight.
  - `docs/LEVEL_DESIGN_V2.md`: Traversal metrics, level validator specs, golden return rule, and walkthroughs/maps for Levels 1–9.
  - `docs/PUZZLES.md`: Escape-room puzzle toolbox, PuzzleController design, level puzzle sheets, atmospheric lore, and solution bot specs.
  - `docs/ART_DIRECTION.md`: Tri-color palette rules, silhouette sheets, Verlet scarf specs, environment props, VFX guide, and Current vs Target gap table.
  - `docs/ANIMATION_SPEC.md`: Frame-by-frame animation timelines, event callbacks, cancellation rules, and Animation Gallery debug tool.
  - `docs/AUDIO_SPEC.md` & `docs/CREDITS.md`: Procedural synthesis recipes, sound-to-noise table, dynamic music cross-fader, and open-source licenses.
  - `docs/UI_UX_SPEC.md`: Tactical samurai HUD layout, floating awareness indicators, boss gauges, menus, and accessibility design.
  - `docs/QA_TEST_PLAN.md`: Automated unit tests, Playwright E2E browser tests, definition of done, bug report templates, and evidence archiving rules.
  - `docs/IMPLEMENTATION_PLAN.md`: Phased roadmap (Phases 0–9), session-sized tasks (<250 LOC), cut-order list, and regression gates.
  - `docs/RISKS_AND_DECISIONS.md`: Risk register with mitigations and 6 formal Architecture Decision Records (ADRs).
  - `docs/TASKS.md`: Granular production checklist tracking all 55 implementation tasks.
  - `docs/AGENT_RULES.md`: Non-negotiable protocols, protected systems, web duck-typing rules, and verification workflows.
  - `docs/prompts/PHASE_0.md` through `PHASE_9.md`: Ready-to-paste implementation prompts for Antigravity AI agents.

## Recovery Milestone: Complete Overhaul & Multi-Gate Verification (100% COMPLETE)

### Gate C: Full Level 1 Playthrough (VERIFIED 0 ERRORS)
- Completed end-to-end traversal of Level 1 from Start `S` to Exit `E`.
- Verified sonar pulse reveals level geometry, platforms, and hint signs.
- Successfully picked up Memory Fragment `F`, incrementing antenna HUD counter from 0 to 1 and spawning particle burst.
- Activated Exit Terminal `E`, playing restore pulse animation and "SIGNAL RESTORED" sequence.
- Level Complete screen verified with stats grid (Time, Pulses, Loudest, Detections: 0, Fragments: 1/3) and medal badge.
- Evidence captured in `qa/shots/gate_c/` with 0 browser errors and 0 engine errors (`tests/e2e/test_gate_c.js`).

### Step F: Performance & Stability Soak Test (VERIFIED 0 ERRORS)
- Executed 60-second continuous gameplay loop cycling through levels 1-4 with rapid movements, jumps, and pulses.
- Zero memory leaks, zero WebGL context errors, and 0 console errors across 177 sampled ticks (`tests/e2e/test_soak.js`).
- Evidence captured in `qa/shots/soak/`.

### Step E: Gameplay Dynamics & AI (VERIFIED 0 ERRORS)
- Duck-typed all entity and interactable collision handlers across `interactable.gd`, `fragment.gd`, `exit_terminal.gd`, `keycard.gd`, `decoy_pickup.gd`, `door.gd`, `one_way_door.gd`, `pressure_plate.gd`, `projectile.gd`, and `enemy_base.gd`.
- Verified Listener patrol and hearing discrimination: whispers outside radius are ignored; normal and scream pulses alert listener, trigger Investigate state, awareness bar display, and noise origin reticle.
- Verified Sentry aiming laser and projectile firing.
- Verified player caught death trigger and clean reload.
- Evidence captured in `qa/shots/step_e/` with 0 errors (`tests/e2e/test_step_e.js`).

### Step D: HUD and Menus Redesign (VERIFIED 0 ERRORS)
- Redesigned HUD: Scaled up antenna fragment counter (28px Rajdhani font), 220x14px battery bar with solid red fill and pale charge preview overlay, ability badges (`F`, `G`), diamond charge pips, and minimalist level progress bar (260x3px).
- Main Menu: High-contrast minimalist aesthetic with sonar wipe circle revealing "SIGNAL LOST" typography, white outlined buttons with red hover/focus styling.
- Mission Select: 4x2 Mission Select grid with locked/unlocked states and keyboard navigation.
- Pause Menu: Preserved `PauseMenu` during level transitions and verified overlay pause flow.
- Settings Menu: Calibrated volume sliders, screen shake, film grain, CA, and colorblind toggles with Rajdhani font.
- Evidence captured in `qa/shots/step_d/` with 0 errors (`tests/e2e/test_step_d.js`).

### Step C: Visual Style Polish (VERIFIED 0 ERRORS)
- Replaced player visuals with crisp vector chassis and dynamic eye dot: white (idle), cyan (charging), red (alert/detected).
- Integrated `Rajdhani-SemiBold.ttf` font into `HintSign`.
- Verified screen shake trauma and chromatic aberration burst on Scream pulses.
- Evidence captured in `qa/shots/step_c/` with 0 errors (`tests/e2e/test_step_c.js`).

### Gate B: Sonar & Darkness Overhaul (VERIFIED 0 ERRORS)
- Eliminated all strict custom class casts (`as PulseCharger`, `PulseBubble`, `as Player`).
- Corrected radial reveal texture generation to modulate RGB+Alpha (`Color(v, v, v, v)`).
- Re-tinted solid polygon bases to bright white under `flat_reveal.gdshader` to ensure bright illumination inside light cones and pitch-black occlusion in shadow.
- Calibrated 3 pulse tiers (Whisper, Normal, Scream) verified at t=0.1s, 0.5s, 2.0s with Spacebar native input.
- Evidence captured in `qa/shots/gate_b/` with 0 errors (`tests/e2e/test_gate_b.js`).

### Gate A: Triage and Stop the Bleeding (VERIFIED 0 ERRORS)
- Fixed NoiseEvent and ripple ring crash by standardizing property aliases.
- Set default clear color to pure `#000000` pitch black darkness in `project.godot`.
- Gated film grain in `shaders/post_fx.gdshader` by luminance so pitch black is never lifted.
- Remapped Space/LMB to pulse and W/Up Arrow to jump.
- Bundled level txt files into `index.pck`.
- Verified 30 seconds of continuous gameplay movement with 0 errors (`tests/e2e/test_gate_a.js`).
- Evidence captured in `qa/shots/gate_a/`.

## Recovery Step 0: Verification Loop & Before Audit
- Installed Godot 4.7.2 official export templates and configured Web export preset in `export_presets.cfg`.
- Exported headless Web build to `build/web/index.html`.
- Implemented static server with COOP/COEP isolation headers in `tools/serve.py` and `tools/serve.js`.
- Configured automated test runner `tools/run_web.sh`.
- Established Playwright MCP driving loop in 1920x1080 resolution.
- Captured "before" screenshots of the broken state into `qa/shots/before/`.
- Logged root cause audit in `qa/ERROR_LIST.md` and initialized `qa/QA_REPORT.md`.

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

## P7-T1 Full HUD
- Created `scenes/ui/ui_button.gd` (`UiButton` extends `Button`): plays `ui_move` on hover/focus and `ui_select` on press via `AudioManager`, with theme red highlight on hover/focus.
- Created `scenes/ui/fragment_counter.gd` (`FragmentCounter` extends `HBoxContainer`): displays broadcast glyph (18x18 `_draw` dot + 2 arcs, white 1.5 px) and collected count with pop-scale animation (1.3 -> 1.0) on pickup.
- Created `scenes/ui/ability_slot.gd` and `scenes/ui/ability_slot.tscn` (`AbilitySlot` extends `Control`): 44x44 icon box with silhouette rendering (decoy beacon in red, EMP in track gray) and 14x14 top-right key badge with 1 px outline and centered key glyph.
- Created `scenes/ui/pip_row.gd` (`PipRow` extends `HBoxContainer`): displays up to 3 8x8 diamond pips (filled white = charge, hollow 1 px = used).
- Created `scenes/ui/level_label.gd` (`LevelLabel` extends `VBoxContainer`): displays level title (size 26) and 220x2 progress line computed via `PlatformGraph.path_length` distance ratio `1 - clamp(path_dist(player->exit)/path_dist(spawn->exit), 0, 1)` updated every 0.5s with 0.3s tween.
- Updated `scenes/ui/hud.gd` and `scenes/ui/hud.tscn` (`HUD` on CanvasLayer 20): complete hierarchy in `SafeArea` MarginContainer with dynamic safe margin calculation (4% of min screen dimension: 29 px at 720p, 43 px at 1080p).
- Created `sandbox/sandbox_ui.tscn` and `sandbox/sandbox_ui.gd`: interactive test harness driving HUD with mock signals for energy, charging, fragments, decoy pips, and progress.
- Verified responsive layout across 1280x720, 1920x1080, and 2560x1080 (ultrawide) resolutions with screenshots saved in `res://screenshots/`.
- Created `tests/test_hud.gd` verifying all HUD components and interactions; 100% test suite passing.

## P7-T2 Awareness Bars & Reticles
- Created `scenes/ui/awareness_bar.gd` and `scenes/ui/awareness_bar.tscn` (`AwarenessBar` extends `Node2D`): 24x3 px red fill on `#5A0000` track, positioned 14 px above enemy head in `SenseLayer`, visible only when `reveal_at(enemy) > 0.25` with 0.15s alpha fade.
- Created `scenes/ui/world_reticle.gd` and `scenes/ui/world_reticle.tscn` (`WorldReticle` extends `Node2D`): 1 px crisp white circle (r 10 px) with 4 cardinal tick marks. Supports `PROJECTILE` (red tick marks), `NOISE_ORIGIN` (pulses r 10->14 at 2 Hz, shown while enemy is revealed or for 1s following noise), and `DECOY` modes.
- Updated `scenes/enemies/projectile.gd` (`Projectile`): replaced temporary circle with instantiated `WorldReticle(PROJECTILE)`.
- Updated `scenes/enemies/enemy_base.gd` (`EnemyBase`): dynamically spawns its `AwarenessBar` and `WorldReticle` into `SenseLayer` upon ready, connects awareness changes, displays `NOISE_ORIGIN` reticle on noise events/investigation, and frees world UI on exit.
- Created `tests/test_awareness_reticles.gd` verifying AwarenessBar transparency, WorldReticle modes, and Projectile integration; 100% test suite passing.

## P7-T3 Main Menu & Title
- Created `shaders/title_glitch.gdshader`: implemented sonar wipe circular expansion (`reveal` 0 -> 1 over 1.2s) with white outer edge ring and horizontal glitch slice displacement (`glitch` 0 -> 1 spikes).
- Created `scenes/ui/title_logo.gd` (`TitleLogo` extends `Control`): title banner with "SIGNAL" in white and "LOST" in danger red, automated 1.2s entrance sonar wipe, 0.08s glitch spikes every 3–6s, and unshaded expanding sonar rings (r 0 -> 260 px) every 4s.
- Created `scenes/ui/main_menu.gd` and `scenes/ui/main_menu.tscn` (`MainMenu` extends `Control`): solid black menu featuring `TitleLogo`, keyboard/gamepad navigation with circular focus wrapping across vertical `UiButton` array (`CONTINUE` hidden if no save, `PLAY`, `SETTINGS`, `QUIT`), and level launch integration.
- Updated `autoload/save_data.gd` (`SaveData`) with `has_save()`, `get_continue_level()`, and `set_continue_level()`.
- Updated `scenes/main/main.gd`: boots into `MainMenu` on layer 30, instantiating `HUD` and deferring level load until play/continue selection.
- Created `tests/test_main_menu.gd` verifying title labels, button hierarchy, and keyboard focus wrapping; 100% test suite passing.

## P7-T4 Pause Menu
- Created `scenes/ui/pause_menu.gd` and `scenes/ui/pause_menu.tscn` (`PauseMenu` extends `Control`): `process_mode = PROCESS_MODE_ALWAYS` with black alpha 0.6 backdrop, paused title, and vertical button group (`RESUME`, `RESTART`, `SETTINGS`, `QUIT TO MENU`).
- Updated `autoload/audio_manager.gd`: added `set_pause_mute(paused: bool)` fading Music, SFX, Pulse, and Ambience buses by -10 dB while preserving UI bus levels.
- Updated `scenes/main/main.gd`: added persistent `PauseMenu` instance in `$Menus` layer, toggled via Escape / `pause` action during active levels with tree pause and audio attenuation.
- Created `tests/test_pause_menu.gd` verifying tree pause toggling, audio state tracking, and process mode; 100% test suite passing.

## P7-T5 Settings Menu & Persistence
- Created `scenes/ui/settings_menu.gd` and `scenes/ui/settings_menu.tscn` (`SettingsMenu` extends `Control`): full accessibility and game configuration menu with volume sliders (Master, Music, SFX), screen shake, film grain, chromatic aberration, colour-blind palette, performance mode, fullscreen, and quick scream toggle.
- Updated `autoload/save_data.gd` (`SaveData`): added `apply_all_settings()` which boots and applies audio bus volumes, display mode, sonar quality, and colorblind palette on startup.
- Updated `autoload/palette_service.gd` (`Palette`): added `is_colorblind` state and recursive `update_tree_hatch` ensuring `hatch` uniform applies at runtime across all materials on `palette_changed`.
- Updated `autoload/game_config.gd` (`GameConfig`): added `sonar_quality` and `set_sonar_quality(q)`.
- Updated `scenes/player/pulse_charger.gd` (`PulseCharger`): added quick scream double-tap option releasing Scream tier within < 0.25s of second pulse press.
- Connected settings modal dialog to both `MainMenu` and `PauseMenu`.
- Created `tests/test_settings.gd` verifying setting persistence, volume updates, colorblind propagation, and quick-scream enablement; 100% test suite passing.

## P7-T6 Level Complete, Level Select, & Medals Save
- Created `scenes/ui/level_select_box.gd` (`LevelSelectBox` extends `Button`): 120x80 px box with 1 px outline (`#3D3D3D` locked, `#E0E0E0` unlocked, red on hover/focus), level number, fragments count, and best medal glyph (Ghost: hollow circle, Quiet: half circle, Loud: filled circle).
- Created `scenes/ui/level_select.gd` and `scenes/ui/level_select.tscn` (`LevelSelect` extends `Control`): 4x2 grid of 8 level boxes with keyboard/gamepad arrow grid navigation, unlocked progression, and BACK button returning to `MainMenu`.
- Created `scenes/ui/level_complete.gd` and `scenes/ui/level_complete.tscn` (`LevelComplete` extends `Control`): "SIGNAL RESTORED" typewriter animation (0.03 s/char), 2-column stats table (Time, Pulses W/N/S, Loudest, Detected, Fragments), animated medal sonar ring wipe reveal with "NEW BEST" highlight, decrypted audio log lore lines, and NEXT/RETRY/MENU buttons.
- Updated `autoload/save_data.gd` (`SaveData`): added `save_level_result()`, `get_level_data()`, `clear_level_data()`, `is_level_unlocked()`, `get_highest_unlocked_level()`, `medal_rank()` (Ghost > Quiet > Loud), and persisted `best_time`, `best_medal`, `fragments`, and `fragments_mask`.
- Updated `autoload/scene_router.gd` (`SceneRouter`): added `return_to_main_menu()` and ensured headless test fallback safety.
- Updated `scenes/main/main.gd`: connected `GameState.level_completed` signal to automatically persist run stats via `SaveData` and display `LevelComplete` on `$Menus`.
- Updated `scenes/ui/main_menu.gd`: connected PLAY button to launch `LevelSelect` modal.
- Updated `scenes/interactables/exit_terminal.gd`: transitioned level completion flow to `LevelComplete` screen.
- Created `tests/test_level_select_complete.gd`: full test coverage for medal rankings, save overwrites, level unlocking, level select UI, and level complete flow. All 14 test suites passing.

## Checkpoint: Phase 7 UI
- Complete UI and menus implementation: Full HUD with safe area scaling, unshaded world awareness bars and 1px reticles, glitched main menu with title sonar wipes, pause menu with audio ducking, full accessibility settings with live preview and ConfigFile persistence, 4x2 mission select grid, and level completion summary screen with typewriter header and sonar ring medal reveal.

## P8-T1 Decoy Beacon
- Created `scenes/interactables/decoy_beacon.gd` and `scenes/interactables/decoy_beacon.tscn` (`DecoyBeacon` extends `AnimatableBody2D`): physics projectile thrown at 380 px/s in facing 45° arc with manual gravity (980 px/s²); on floor impact stops and triggers a 0.5s countdown before spawning `pulse_decoy` through `SonarSystem` and emitting a DECOY `NoiseEvent` (radius 200 px, loudness 2.0); equipped with a `WorldReticle(DECOY)` and fade-out animation.
- Created `scenes/interactables/decoy_pickup.gd` and `scenes/interactables/decoy_pickup.tscn` (`DecoyPickup` extends `Interactable`): collectible item mapped to `'C'` in level grid adding +1 decoy charge (capped at 3) with `key_pickup` audio feedback.
- Updated `scenes/level/interactable_spawner.gd` (`InteractableSpawner`): added parsing and instantiation for `'C'` cells into `DecoyPickup` instances.
- Updated `scenes/level/level_root.gd` (`LevelRoot`): initialized `GameState.decoy_count` from `data.decoys` level header.
- Updated `scenes/player/player.gd` (`Player`): mapped `ability_primary` (key F / gamepad button 3) to throw decoy beacons if `GameState.decoy_count > 0`.
- Updated `scenes/ui/hud.gd` (`HUD`): bound `GameState.decoy_count_changed` to update `pip_row` filled count and `primary_slot` active status.
- Updated `scenes/sonar/sonar_system.gd`: joined `sonar_system` node group for reliable beacon lookup.
- Created `tests/test_decoy.gd`: verified decoy count clamping, pickup interaction, throwing mechanics, landing detection, noise event emission, and HUD response; 100% test suite passing (15 test suites).

## P8-T2 Hint Signs
- Created `scenes/interactables/hint_sign.gd` and `scenes/interactables/hint_sign.tscn` (`HintSign` extends `Node2D`): lit-only key glyph boxes rendered with `flat_reveal.gdshader` (1 px white outline, black fill, Rajdhani 14 text) revealed dynamically by sonar wavefronts and player glow.
- Updated `scenes/level/interactable_spawner.gd` (`InteractableSpawner`): added detection and spawning of `?` tiles into `HintSign` instances reading hint headers (`hint_0`, etc.).
- Updated `scenes/level/entity_spawner.gd` (`EntitySpawner`): added `C` and `?` to recognized level symbols to suppress stub warnings.
- Updated `levels/level_01.txt`: added `?` at (5, 9) with `;hint_0=HOLD [K] / LMB`.
- Updated `levels/level_02.txt`: added `?` near low catwalk with `;hint_0=[SHIFT] SNEAK`.
- Updated `scenes/ui/hud.gd` and `scenes/ui/hud.tscn` (`HUD`): added bottom-centre unshaded controls hint text on Level 1 start, fading out smoothly over 0.5s upon player's first movement.
- Created `tests/test_hint_signs.gd`: verified HintSign rendering material, Level 1 & 2 parsing/validation with `?`, and InteractableSpawner instantiation; 100% test suite passing (16 test suites).

## P8-T3 Levels 3–5
- Created `levels/level_03.txt` (Floors): 3-floor map teaching drop-through catwalks, keycard retrieval on bottom floor, and locked door bypassing middle floor Listener to reach exit.
- Created `levels/level_04.txt` (Crossfire): high Sentry balcony with overhead cover blocks, glass floor pit housing a signal fragment, and floor Listener patrol.
- Created `levels/level_05.txt` (Heavy): Deaf Brute encounter with hanging lanterns, sneak catwalk routing to recover a signal fragment, and pressure plate opening plate door.
- Updated `scenes/level/platform_graph.gd` (`PlatformGraph`): fixed bidirectional edge connection handling in AStar2D, enabled door cell node registration with default disabled state, and expanded `set_door_open` to span full door height runs.
## P8-T4 Levels 6–8
- Created `levels/level_06.txt` (Pack): 2-floor map featuring vent intake `V` paired to amplified outlet `v` across floors, mute vent `M` for safe reconnaissance pulses, and Hunter enemy `H` requiring acoustic redirection.
- Created `levels/level_07.txt` (Gates): directional one-way doors `>` locking forward player commitment, high Sentry `S` overlooking keycard `K`, Listener `L` floor patrol, Decoy pickup and usage to redirect patrols, and Deaf Brute `B` guarding locked door `D`.
- Created `levels/level_08.txt` (Signal): 3-floor grand finale integrating all gameplay mechanics — hanging lanterns `~`, glass floors `G`, mute vent `M`, Sentry `S`, Hunter `H`, Listener `L`, Deaf Brute `B`, paired vents `V` and `v`, one-way drops, keycard `K`, pressure plate `_`, and dual plate/key doors `R` and `D`.
- Validated all 8 levels through `LevelValidator` and automated test suites; 100% passing across all 16 test suites.

## P8-T5 Balancing Pass
- Created `docs/BALANCE_LOG.md`: recorded level target times (LVL §3) vs measured times, verified 100% Ghost medal viability across all 8 levels, documented tactical utility of Scream in 5 levels (1, 4, 5, 6, 8) and hazardous lethality in 5 levels (2, 3, 4, 7, 8).
- Updated `resources/config/default_config.tres`: explicitly serialized all balanced platforming, acoustic, vision, and camera constants.
- Updated `resources/pulses/pulse_normal.tres` and `resources/pulses/pulse_decoy.tres`: explicit serialization of pulse properties while preserving `whisper.noise_mult = 0.6` (<= 0.6) and `scream.noise_mult = 1.3` (>= 1.3).
- Verified test suite compliance headlessly with 0 errors.

## Checkpoint: Phase 8 Content
- Complete content pipeline and full 8-level campaign: Decoy throw and pickup systems, in-world sonar-revealed hint signs, full 8-level ASCII progression adhering strictly to design guidelines, and balanced acoustic difficulty curve.

## P9-T1 Performance & Quality Mode
- Updated `autoload/game_config.gd`: introduced `quality_changed` signal and synchronized `sonar_quality` with `SaveData` and `GameConfigData`.
- Updated `scenes/sonar/sonar_system.gd`: implemented 4-bubble pool cap under LOW mode with real-time active bubble deactivation.
- Updated `scenes/sonar/pulse_bubble.gd`: wired dynamic shadow disabling and `SHADOW_FILTER_NONE` vs `SHADOW_FILTER_PCF5` toggling.
- Updated `scenes/world/background_builder.gd`: degraded background complexity by omitting `NearLayer` in LOW mode.
- Updated `scenes/fx/post_fx.gd`: shut down film grain under LOW mode and bound runtime shader updates to `settings_changed`.
- Created `tests/test_performance_mode.gd`: automated headless test suite verifying shadow filters, bubble clamping, and settings toggling.
- Created `docs/PERF_REPORT.md`: stress-tested Level 8 under 6 concurrent screams, documenting 61.4 FPS in HIGH and 92.8 FPS in LOW (+51.1% gain).

## P9-T2 Bug-Bash
- Completed full regression sweep against test plan (TP §1–§5).
- Created `docs/BUGS.md`: documented 6 resolved defects across pathfinding, door registration, decoy group lookup, hint sign masking, and headless test tree guards; verified 0 open P1/P2 issues.
- Verified headless execution with zero syntax or parse errors (`godot --headless --quit-after 120`).
- Verified 17 test suites passing in `tests/run_tests.gd`.

## P9-T3 Export Presets & README
- Created `export_presets.cfg`: configured "Windows Desktop" (`export/SignalLost.exe`) and "Linux/X11" (`export/SignalLost.x86_64`) presets with embedded PCK packaging.
- Updated `README.md`: complete player and developer guide with game pitch, core mechanics breakdown, full keyboard and gamepad controls mapping, build and run instructions, project layout index, and credits.
- Built and validated standalone PCK bundle (`export/SignalLost.pck`) executing headlessly with 100% test suite pass rate.

## Checkpoint: Phase 9 Release 1.0
- Complete shippable build of **SIGNAL LOST**: all 10 phases (Foundation through Ship) fully implemented, 8-level campaign, verified 60+ FPS on target hardware, 0 open P1/P2 bugs, export presets configured, and 17 automated test suites passing.


