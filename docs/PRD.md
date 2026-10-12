# SIGNAL LOST — Product Requirements Document (PRD V2)

- **Purpose**: Authoritative product requirements, scope boundaries, testable functional criteria, non-functional quality standards, and traceability matrix for SIGNAL LOST V2.
- **Audience**: Technical Directors, Producers, System Architects, QA Engineers, AI Coding Agents.
- **Status**: Approved.
- **Last Updated**: 2026-10-11.
- **Depends On**: [00_CURRENT_STATE_AUDIT.md](file:///c:/vibe-game/docs/00_CURRENT_STATE_AUDIT.md), [GDD.md](file:///c:/vibe-game/docs/GDD.md).

---

## 1. Problem Statement & Objectives

### 1.1 Problem Statement
The current V1 implementation of SIGNAL LOST delivers a proven acoustic stealth-platforming mechanic (echolocation in pitch darkness), but suffers from four critical commercial and gameplay deficiencies:
1. **Zero Defensive/Offensive Interactivity**: Any contact with enemies or bullets results in an instant 0.6s death loop, frustrating players and precluding dynamic tactical recovery.
2. **Visual Monotony & Scale Issues**: The hero is a tiny 14x18 px box floating in an oversized 1920x1080 void; enemies are basic red rectangles with zero readable personality.
3. **Flawed Vertical Level Architecture**: Flat horizontal corridors lead to unrecoverable vertical soft-locks (e.g., Level 3 stacked corridors where falling creates an inescapable pit).
4. **Lack of Mid-to-Late Progression Depth**: Progression is limited to simple keycard-door triggers without puzzle layers, narrative intrigue, or escalating boss encounters.

### 1.2 Core Product Objectives
- **Objective 1**: Implement a fluid, high-stakes 2D samurai combat engine (3 weapons, parry, poise break, assassinations, segmented health) tightly coupled to the acoustic noise system.
- **Objective 2**: Transform visual presentation into a striking, full-screen tri-color aesthetic featuring large readable samurai/enemy silhouettes, multi-layer shoji backgrounds, and dynamic slash arcs.
- **Objective 3**: Deliver a 9-level vertical campaign incorporating escape-room puzzle mechanics (echo glyphs, resonance panels, seal locks) with **zero soft-locks**.
- **Objective 4**: Maintain 100% regression safety across all protected V1 systems (sonar wavefronts, darkness rendering, procedural audio, web export, and automated test hooks).

---

## 2. Target Player & Personas

- **The Precision Platformer Enthusiast**: Enjoys tight kinematic controls, high-stakes evasion, and instant-retry flow (*Celeste*, *Katana Zero*).
- **The Tactical Stealth Purist**: Values information asymmetry, patience, silent execution, and optimizing for ghost/stealth medals (*Mark of the Ninja*, *Gunpoint*).
- **The Soulslike Combat Fan**: Loves reading enemy attack tells, executing frame-tight parries, breaking poise meters, and mastering boss attack patterns (*Sekiro*).

---

## 3. Product Scope (MoSCoW Matrix)

### 3.1 MUST HAVE (V2 Release Gate)
- Full 3-weapon samurai combat system (Katana, Naginata, Twin Kunai) with startup/active/recovery frame windows and poise stagger.
- Segmented hero health (3 segments base) replacing instant one-hit death.
- Complete 6-tier enemy roster: Ashigaru (spearman), Kenshi (swordsman), Yumi (archer), Sentry (turret), Oni Brute (heavy), and Shogun Mech (boss).
- 9 vertical handcrafted levels parsed from ASCII matrices with automated reachability validation.
- Escape-room puzzle toolbox: Echo Glyphs, Resonance Panels, Seal Locks, Harmonic Lanterns, and Hint Beacon (`H`).
- Tri-color visual overhaul: large samurai silhouette with scarf physics, distinctive enemy shapes, and full-screen camera framing.
- Complete regression safety on all 17 unit tests and 7 E2E browser tests.

### 3.2 SHOULD HAVE (V2 High Priority)
- Dynamic procedural music layering that seamlessly blends from ambient acoustic drones to tense combat percussion upon detection.
- Full gamepad vibration/haptic feedback integration.
- Speedrun timer overlay and sector medal history viewer.

### 3.3 COULD HAVE (Post-V2 Polish)
- Custom level editor with live ASCII grid preview.
- Endless "Acoustic Arena" survival challenge mode.
- Additional cosmetic armor wraps unlocked by Ghost medals.

### 3.4 WON'T HAVE (Strictly Out of Scope)
- 3D assets or polygonal rendering pipelines.
- Online multiplayer or networked leaderboards.
- Voice acting or pre-rendered cinematic video files.
- Paid DLC, microtransactions, or arbitrary grinding systems.

---

## 4. Functional Requirements (FR)

Every requirement below carries a permanent ID, detailed description, and unambiguous testable acceptance criterion.

### 4.1 Combat Systems (FR-COMBAT)

| ID | Title | Description | Acceptance Criterion |
|---|---|---|---|
| **FR-COMBAT-001** | Katana 3-Hit Combo | Player can execute a 3-strike slash sequence with `attack` button within a 0.35s combo buffer window. | Strike 1 (1 dmg, 15 poise, 180 noise), Strike 2 (1 dmg, 15 poise, 200 noise), Strike 3 (2 dmg, 30 poise, 280 noise). Tested in `test_combat_combo.gd`. |
| **FR-COMBAT-002** | Naginata Reach & Pierce | Long-reach weapon with a forward thrust that penetrates through up to 2 aligned enemies and hits overhead lanterns. | Hitbox extends 48 px forward. Hits break enemy shields in 1 hit. Tested in `test_combat_weapons.gd`. |
| **FR-COMBAT-003** | Twin Kunai Rapid Dash | Dual daggers providing high attack speed (0.18s recovery) and silent assassination strikes. | Noise generated per strike $\le 90$ px. Dash attack pierces behind target. Tested in `test_combat_weapons.gd`. |
| **FR-COMBAT-004** | Frame-Tight Parry | Pressing `block` within 6 frames (0.10s) before an incoming strike deflects the attack, generates zero damage, and damages attacker poise. | Deflects hostile attack, inflicts 40 poise damage to attacker, triggers 0.10s hit-stop, and grants 16 i-frames. Tested in `test_combat_parry.gd`. |
| **FR-COMBAT-005** | Guard & Guard Break | Holding `block` outside the parry window absorbs 70% damage at the cost of hero poise. Zero poise triggers Guard Break. | Player enters 0.60s Guard Break stagger upon absorbing hit at 0 poise. Tested in `test_combat_guard.gd`. |
| **FR-COMBAT-006** | Stealth Assassination | Pressing `attack` directly behind an unaware enemy (distance $\le 28$ px, awareness $< 0.35$) executes a lethal finisher. | Instantly eliminates non-boss enemy, bypasses poise, and plays 0.40s finisher animation. Tested in `test_combat_stealth.gd`. |
| **FR-COMBAT-007** | Segmented Hero Health | Replace binary 1-hit death with 3 health segments. Each hostile strike depletes 1 segment unless deflected. | Health bar displays 3 discrete segments; taking damage triggers 0.08s hit-stop and 1.2s invulnerability flashing. Tested in `test_health_system.gd`. |
| **FR-COMBAT-008** | Attack Token Concurrency | AI coordinator restricts maximum simultaneous attacking enemies to 2 tokens. | In encounters with $\ge 3$ active enemies, no more than 2 enemies can be in attack startup simultaneously. Tested in `test_attack_tokens.gd`. |

### 4.2 Artificial Intelligence & Navigation (FR-AI)

| ID | Title | Description | Acceptance Criterion |
|---|---|---|---|
| **FR-AI-001** | Ashigaru Spearman AI | Frontline foot soldier with 42 px spear thrust, 0.45s telegraph, and coordinated patrol behaviors. | State machine executes Patrol, Investigate, Chase, Thrust. Thrust telegraphed by red glint. Tested in `test_ai_ashigaru.gd`. |
| **FR-AI-002** | Kenshi Swordsman AI | Agile duelist capable of parrying player slashes, dodging backward, and executing quick draw strikes. | Parries front slashes if player attacks predictably; staggers if hit from behind. Tested in `test_ai_kenshi.gd`. |
| **FR-AI-003** | Yumi Archer AI | Balcony-dwelling sniper firing high-speed acoustic arrows (520 px/s) revealed as red lines inside sonar bubbles. | Scans 40° cone up to 400 px; charges arrow for 0.70s with laser sight; arrows stick in walls. Tested in `test_ai_yumi.gd`. |
| **FR-AI-004** | Oni Brute Mech AI | Heavy armored juggernaut immune to light Katana slashes; vulnerable only to heavy thrusts or environment traps. | Light slashes bounce with metallic clang (0 damage); heavy thrust inflicts stagger. Shatters glass floors. Tested in `test_ai_brute.gd`. |
| **FR-AI-005** | Sentry Balcony Turret | Static defense node scanning 320 px with red laser sight, firing lethal projectiles on confirmation. | Preserves existing verified sentry behavior from V1 baseline with updated silhouette. Tested in `test_step_e.js`. |
| **FR-AI-006** | Shogun Mech Boss (3 Phases) | 3-phase climax boss: Phase 1 (Naginata sweeps), Phase 2 (Acoustic barrage & summons), Phase 3 (Overcharged speed & shockwaves). | Full phase transitions triggered at 66% and 33% HP with distinct telegraph sets. Tested in `test_boss_shogun.gd`. |
| **FR-AI-007** | Platform Graph AI Navigation | Enemies navigate vertical levels using directed A* graph supporting WALK, JUMP, DROP, and stuck-recovery. | Zero enemies get trapped in infinite jump loops; stuck enemies trigger 1.0s fallback pathing. Tested in `test_platform_graph.gd`. |

### 4.3 Level Design & Architecture (FR-LEVEL)

| ID | Title | Description | Acceptance Criterion |
|---|---|---|---|
| **FR-LEVEL-001** | 9 Handcrafted Vertical Levels | Deliver Levels 1–9 as ASCII files, scaling 3 to 6 screens wide with dedicated vertical shafts and return paths. | All 9 levels parse cleanly without ragged rows; dimensions $\le 48 \times 32$ tiles. Tested in `test_level_parser.gd`. |
| **FR-LEVEL-002** | Zero Soft-Lock Guarantee | Offline level validator simulates player jump limits (2.7 tiles apex, 3.5 tiles horizontal) and confirms exit reachability. | Automated test asserts 100% reachability from `P` to `E` for all 9 levels with 0 errors. Tested in `test_validator.gd`. |
| **FR-LEVEL-003** | Corridors Vertical Connection Fix | In Level 3 and all multi-floor sectors, every drop ledge must feature an associated climbable wall/ladder/lift return. | Dropping to lower floor never traps player; path to upper floor verified via PlatformGraph. Tested in `test_validator.gd`. |
| **FR-LEVEL-004** | Dynamic Camera Framing | CameraRig tracks player with smooth look-ahead (48 px) and dynamic zoom out (1.8x to 1.4x) during large combat encounters. | Level geometry fills 100% of the viewport; zero empty black void border outside level bounds. Tested in `test_camera_framing.gd`. |

### 4.4 Puzzle Systems (FR-PUZZLE)

| ID | Title | Description | Acceptance Criterion |
|---|---|---|---|
| **FR-PUZZLE-001** | Echo Glyphs | Wall-etched runes revealed only by specific sonar pulse tiers, giving puzzle clues and gate passcodes. | Whisper pulse reveals cyan rune; Normal pulse reveals white rune; Scream reveals red rune. Tested in `test_puzzle_glyphs.gd`. |
| **FR-PUZZLE-002** | Resonance Panels | Acoustic tuning panels that vibrate and trigger linked mechanisms when struck by matching pulse tiers. | Panel triggers paired door open state upon receiving matching `wavefront_passed` event. Tested in `test_puzzle_resonance.gd`. |
| **FR-PUZZLE-003** | Harmonic Lantern Sequences | Hanging lanterns that chime upon weapon strike; striking sequence in correct order opens sector blast gate. | Striking lanterns in order (1-2-3) within 8.0s unlocks gate; wrong order resets. Tested in `test_puzzle_lanterns.gd`. |
| **FR-PUZZLE-004** | Directional Seal Locks | Airlock doors requiring two distinct cryptographic artifacts or dual pressure plate activations. | Door opens only when both conditions are satisfied simultaneously. Tested in `test_puzzle_seals.gd`. |
| **FR-PUZZLE-005** | Emergency Exit Hint Beacon | Pressing `H` emits a directional acoustic ripple pointing towards `E` at the cost of a 120 px local noise radius. | Directional arrow renders for 1.5s; emits noise event to `NoiseBus`. Cooldown 5.0s. Tested in `test_puzzle_hint.gd`. |

### 4.5 Visuals, Art & Animation (FR-ANIM)

| ID | Title | Description | Acceptance Criterion |
|---|---|---|---|
| **FR-ANIM-001** | Samurai Hero Vector Rig | High-contrast white silhouette chassis with articulated limbs, katana scabbard, and physics-driven scarf. | Height 54 px at 1920x1080. Scarf trails velocity dynamically via Verlet points. Tested in `test_visual_hero.gd`. |
| **FR-ANIM-002** | Distinct Enemy Silhouettes | Ashigaru, Kenshi, Yumi, Brute, and Sentry feature unmistakable silhouette contours and readable weapon stances. | Proportions and silhouettes distinguishable in silhouette-only render tests. Tested in `test_visual_enemies.gd`. |
| **FR-ANIM-003** | Procedural Slash Arcs | Weapon swings generate crisp white curved line arcs (`Line2D` + shader fade) with directional spark particles. | Slash arc renders for 0.12s; angle matches attack direction. Tested in `test_slash_fx.gd`. |
| **FR-ANIM-004** | Multi-Layer Shoji Backgrounds | Parallax background featuring 3 depth planes of feudal-industrial architecture (shoji screens, gantries, pillars). | Background renders at z -10, -20, -30; scrolls with scales 0.30, 0.55, 0.80. Tested in `test_parallax_bg.gd`. |
| **FR-ANIM-005** | Animation Gallery Debug Scene | Dedicated debug scene (`scenes/debug/animation_gallery.tscn`) displaying all hero and enemy animations with frame scrubbing. | Allows manual inspection of startup, active, and recovery frames. Tested in `test_anim_gallery.gd`. |

### 4.6 Audio Systems (FR-AUDIO)

| ID | Title | Description | Acceptance Criterion |
|---|---|---|---|
| **FR-AUDIO-001** | Procedural Blade Impact SFX | Synthesize metallic clangs, blade swooshes, flesh slices, and parry deflects headlessly via `SfxLibrary`. | Synthesis completes in $< 350$ ms on boot with zero external audio dependencies. Tested in `test_sfx_library.gd`. |
| **FR-AUDIO-002** | Dynamic Combat Music Layer | Ambient synthetic drone seamlessly cross-fades into high-tempo taiko percussion when player is detected. | Audio bus cross-fade completes over 0.8s upon `GameState.detected()` signal. Tested in `test_music_layers.gd`. |
| **FR-AUDIO-003** | Noise Coupling Integrity | Every synthesized sound effect maps deterministically to a corresponding `NoiseEvent` on `NoiseBus`. | Assert 1:1 mapping between audio playback call and noise event dispatch. Tested in `test_audio_noise_coupling.gd`. |

### 4.7 User Interface & Accessibility (FR-UI)

| ID | Title | Description | Acceptance Criterion |
|---|---|---|---|
| **FR-UI-001** | Samurai Tactical HUD | Top-left: Level label, fragment counter, currency/score. Bottom-left: Weapon badge, segmented health, shuriken pips, battery bar. | Scaled for 1920x1080; unshaded; zero occlusion of center gameplay action. Tested in `test_hud.gd`. |
| **FR-UI-002** | Boss Vitality Gauge | Bottom-center boss health and poise bar appearing during the Shogun Mech encounter. | Gauge smoothly updates on damage; flashes white on poise stagger. Tested in `test_boss_hud.gd`. |
| **FR-UI-003** | Color-Blind Accessibility Mode | High-contrast accessibility toggle converting red danger indicators to white-bordered diagonal hatch fills. | Shader uniform `hatch = true` applies across all materials without performance penalty. Tested in `test_settings.gd`. |

### 4.8 Quality Assurance & Automation (FR-QA)

| ID | Title | Description | Acceptance Criterion |
|---|---|---|---|
| **FR-QA-001** | Full Headless Unit Test Suite | Headless test harness executes all unit tests in under 5.0 seconds. | Command `godot --headless --path . -s res://tests/run_tests.gd` outputs `ALL TESTS PASSED` with code 0. |
| **FR-QA-002** | Automated Playwright E2E Suite | Browser test suite executes end-to-end verification across movement, combat, sonar, and level completion. | `npm test` runs all gate scripts with 0 console errors and 0 page exceptions. |
| **FR-QA-003** | Evidence Archive Logging | Every phase test execution automatically outputs high-resolution PNG screenshots and console logs to `/qa/shots/`. | Directory `/qa/shots/<phase>/` contains timestamped verification evidence. |

---

## 5. Non-Functional Requirements (NFR)

- **NFR-PERF-001 (Frame Rate)**: Stable **60.0 FPS** on standard desktop builds and WebAssembly export running on integrated graphics (Intel UHD 620 baseline).
- **NFR-PERF-002 (Web Export Size)**: Total web distribution payload (WASM binary + `index.pck`) must not exceed **25.0 MB** uncompressed.
- **NFR-PERF-003 (Load Time)**: Cold boot to playable Main Menu must complete in under **2.5 seconds** on web; instant level restarts in under **0.20 seconds**.
- **NFR-CODE-001 (Zero Errors/Warnings)**: Clean console output on headless startup (`--quit-after 120`). Zero Godot engine script errors, null reference warnings, or leaked ObjectDB instances.
- **NFR-STYLE-001 (Strict Tri-Color Palette)**: Enforce `#000000` (background/void), `#FFFFFF` (player, edges, UI, arcs), and `#E00000` (hostile danger, blood, alert smudges). Zero unauthorized hues.

---

## 6. Success Metrics & Key Results

| Metric | Target | Measurement Method |
|---|---|---|
| **Level Completion Rate** | $\ge 85\%$ across test cohorts | Measured via playtest analytics logs. |
| **Average Level Duration** | 3.0 to 7.0 minutes per level | Timed from spawn `P` to terminal `E`. |
| **Soft-Lock Defect Count** | Exactly **0** | Verified by automated `LevelValidator` across all maps. |
| **Parry Timing Reliability** | $\pm 0.0$ frame jitter at 60 FPS | Validated via `test_combat_parry.gd` deterministic ticks. |
| **Ghost Medal Feasibility** | Viable on 100% of campaign levels | Verified by automated test bot path traversal. |

---

## 7. Requirement Traceability Matrix

| Requirement ID | Primary Design Spec | Target Architecture Module | Implementing Phase | Verification Test Script |
|---|---|---|---|---|
| **FR-COMBAT-001** | `COMBAT_DESIGN.md` | `scenes/player/combat/combat_controller.gd` | **Phase 1** | `tests/test_combat_combo.gd` |
| **FR-COMBAT-002** | `COMBAT_DESIGN.md` | `scenes/player/combat/weapon_naginata.gd` | **Phase 2** | `tests/test_combat_weapons.gd` |
| **FR-COMBAT-003** | `COMBAT_DESIGN.md` | `scenes/player/combat/weapon_kunai.gd` | **Phase 2** | `tests/test_combat_weapons.gd` |
| **FR-COMBAT-004** | `COMBAT_DESIGN.md` | `scenes/player/combat/parry_system.gd` | **Phase 1** | `tests/test_combat_parry.gd` |
| **FR-COMBAT-005** | `COMBAT_DESIGN.md` | `scenes/player/combat/poise_system.gd` | **Phase 1** | `tests/test_combat_guard.gd` |
| **FR-COMBAT-006** | `COMBAT_DESIGN.md` | `scenes/player/combat/assassination.gd` | **Phase 2** | `tests/test_combat_stealth.gd` |
| **FR-COMBAT-007** | `COMBAT_DESIGN.md` | `scenes/player/health_component.gd` | **Phase 1** | `tests/test_health_system.gd` |
| **FR-COMBAT-008** | `ENEMY_AI.md` | `autoload/attack_token_manager.gd` | **Phase 3** | `tests/test_attack_tokens.gd` |
| **FR-AI-001** | `ENEMY_AI.md` | `scenes/enemies/ashigaru.tscn` | **Phase 3** | `tests/test_ai_ashigaru.gd` |
| **FR-AI-002** | `ENEMY_AI.md` | `scenes/enemies/kenshi.tscn` | **Phase 4** | `tests/test_ai_kenshi.gd` |
| **FR-AI-003** | `ENEMY_AI.md` | `scenes/enemies/yumi.tscn` | **Phase 4** | `tests/test_ai_yumi.gd` |
| **FR-AI-004** | `ENEMY_AI.md` | `scenes/enemies/oni_brute.tscn` | **Phase 4** | `tests/test_ai_brute.gd` |
| **FR-AI-005** | `ENEMY_AI.md` | `scenes/enemies/sentry.tscn` | **Phase 3** | `tests/e2e/test_step_e.js` |
| **FR-AI-006** | `ENEMY_AI.md` | `scenes/enemies/boss_shogun.tscn` | **Phase 8** | `tests/test_boss_shogun.gd` |
| **FR-AI-007** | `ENEMY_AI.md` | `scenes/level/platform_graph.gd` | **Phase 0** | `tests/test_platform_graph.gd` |
| **FR-LEVEL-001** | `LEVEL_DESIGN_V2.md` | `levels/level_01.txt` ... `level_09.txt` | **Phase 5** | `tests/test_level_parser.gd` |
| **FR-LEVEL-002** | `LEVEL_DESIGN_V2.md` | `scenes/level/level_validator.gd` | **Phase 0** | `tests/test_validator.gd` |
| **FR-LEVEL-003** | `LEVEL_DESIGN_V2.md` | `levels/level_03.txt` | **Phase 5** | `tests/test_validator.gd` |
| **FR-LEVEL-004** | `LEVEL_DESIGN_V2.md` | `scenes/fx/camera_rig.gd` | **Phase 5** | `tests/test_camera_framing.gd` |
| **FR-PUZZLE-001**| `PUZZLES.md` | `scenes/interactables/echo_glyph.gd` | **Phase 6** | `tests/test_puzzle_glyphs.gd` |
| **FR-PUZZLE-002**| `PUZZLES.md` | `scenes/interactables/resonance_panel.gd`| **Phase 6** | `tests/test_puzzle_resonance.gd` |
| **FR-PUZZLE-003**| `PUZZLES.md` | `scenes/interactables/harmonic_lantern.gd`| **Phase 6** | `tests/test_puzzle_lanterns.gd` |
| **FR-PUZZLE-004**| `PUZZLES.md` | `scenes/interactables/seal_lock.gd` | **Phase 6** | `tests/test_puzzle_seals.gd` |
| **FR-PUZZLE-005**| `PUZZLES.md` | `scenes/player/hint_beacon.gd` | **Phase 6** | `tests/test_puzzle_hint.gd` |
| **FR-ANIM-001** | `ART_DIRECTION.md` | `scenes/player/player_visual.gd` | **Phase 7** | `tests/test_visual_hero.gd` |
| **FR-ANIM-002** | `ART_DIRECTION.md` | `scenes/enemies/visuals/*.gd` | **Phase 7** | `tests/test_visual_enemies.gd` |
| **FR-ANIM-003** | `ART_DIRECTION.md` | `scenes/fx/slash_arc.gd` | **Phase 7** | `tests/test_slash_fx.gd` |
| **FR-ANIM-004** | `ART_DIRECTION.md` | `scenes/world/background_builder.gd` | **Phase 7** | `tests/test_parallax_bg.gd` |
| **FR-ANIM-005** | `ANIMATION_SPEC.md` | `scenes/debug/animation_gallery.tscn` | **Phase 7** | `tests/test_anim_gallery.gd` |
| **FR-AUDIO-001** | `AUDIO_SPEC.md` | `audio/sfx_library.gd` | **Phase 8** | `tests/test_sfx_library.gd` |
| **FR-AUDIO-002** | `AUDIO_SPEC.md` | `audio/music_layers.gd` | **Phase 8** | `tests/test_music_layers.gd` |
| **FR-AUDIO-003** | `AUDIO_SPEC.md` | `autoload/noise_bus.gd` | **Phase 8** | `tests/test_audio_noise_coupling.gd` |
| **FR-UI-001** | `UI_UX_SPEC.md` | `scenes/ui/hud.gd` | **Phase 7** | `tests/test_hud.gd` |
| **FR-UI-002** | `UI_UX_SPEC.md` | `scenes/ui/boss_health_bar.gd` | **Phase 8** | `tests/test_boss_hud.gd` |
| **FR-UI-003** | `UI_UX_SPEC.md` | `autoload/palette_service.gd` | **Phase 0** | `tests/test_settings.gd` |
| **FR-QA-001** | `QA_TEST_PLAN.md` | `tests/run_tests.gd` | **Phase 0-9** | Continuous CI verification |
| **FR-QA-002** | `QA_TEST_PLAN.md` | `tests/e2e/*.js` | **Phase 0-9** | Playwright E2E verification |
| **FR-QA-003** | `QA_TEST_PLAN.md` | `tools/evidence_logger.gd` | **Phase 0-9** | Screenshot archive output |
