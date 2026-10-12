# SIGNAL LOST — Production Task Checklist & Tracker (V2)

- **Purpose**: Master operational task checklist reflecting the entire phased implementation plan, tracking granular status, task IDs, files touched, and agent assignments.
- **Audience**: Technical Directors, Producers, AI Coding Agents (Gemini, Claude Sonnet/Opus).
- **Status**: Approved.
- **Last Updated**: 2026-10-12.
- **Depends On**: [IMPLEMENTATION_PLAN.md](file:///c:/vibe-game/docs/IMPLEMENTATION_PLAN.md), [QA_TEST_PLAN.md](file:///c:/vibe-game/docs/QA_TEST_PLAN.md).

---

## 1. Production Progress Summary

- **Total Tasks**: **55 Tasks** across 10 Phases (Phase 0 through 9).
- **Completed**: `4 / 55` (7.3%)
- **In Progress**: `0 / 55` (0%)
- **Pending**: `51 / 55` (92.7%)

---

## 2. Granular Task Checklist

### PHASE 0: Architectural Hygiene & Regression Setup
- [x] **P0-T01**: Expand input map in `project.godot` with `attack`, `attack_heavy`, `dash`, `block_parry`, `weapon_swap`, `hint`.
  - *Files Touched*: `project.godot` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED
- [x] **P0-T02**: Implement `AttackTokenManager` singleton for enemy attack concurrency cap (max 2).
  - *Files Touched*: `autoload/attack_token_manager.gd`, `project.godot` | *Owner*: Opus 5.5 | *Status*: COMPLETED
- [x] **P0-T03**: Create `AttackData` resource script and default combat tunables in `resources/config/combat_config.tres`.
  - *Files Touched*: `scripts/resources/attack_data.gd`, `scripts/resources/combat_config_data.gd`, `resources/config/combat_config.tres` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED
- [x] **P0-T04**: Execute regression verification: run all 17 unit tests and `test_gate_a.js`. Log evidence to `/qa/shots/phase_0/`.
  - *Files Touched*: `tests/e2e/test_gate_a.js` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED

---

### PHASE 1: Combat Primitives & Health Refactor
- [x] **P1-T01**: Implement `HealthComponent` managing 3 integer segments, i-frames, and death signals.
  - *Files Touched*: `scenes/combat/health_component.gd`, `tests/test_health_system.gd` | *Owner*: Opus 5.5 | *Status*: COMPLETED
- [x] **P1-T02**: Implement `PoiseComponent` tracking balance meter (100.0 max), poise damage, and stagger triggers.
  - *Files Touched*: `scenes/combat/poise_component.gd`, `tests/test_combat_guard.gd` | *Owner*: Opus 5.5 | *Status*: COMPLETED
- [x] **P1-T03**: Implement standardized `HitboxComponent` and `HurtboxComponent` 2D area primitives.
  - *Files Touched*: `scenes/combat/hitbox_component.gd`, `scenes/combat/hurtbox_component.gd` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED
- [x] **P1-T04**: Implement `CombatController` on player handling `J` combo slashes and noise emission.
  - *Files Touched*: `scenes/player/combat_controller.gd`, `scenes/player/player.gd` | *Owner*: Opus 5.5 | *Status*: COMPLETED
- [x] **P1-T05**: Implement 6-frame deflect window on `block_parry` with 40 poise damage and spark triggers.
  - *Files Touched*: `scenes/player/combat/parry_system.gd`, `tests/test_combat_parry.gd` | *Owner*: Opus 5.5 | *Status*: COMPLETED
- [x] **P1-T06**: Implement 15-frame dash roll on `L` with 12 i-frames and 0.50s cooldown.
  - *Files Touched*: `scenes/player/combat/dash_system.gd`, `scenes/player/player_motor.gd` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED
- [x] **P1-T07**: Run `test_combat_combo.gd` and capture combat evidence to `/qa/shots/phase_1/`.
  - *Files Touched*: `tests/test_combat_combo.gd` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED

---

### PHASE 2: Weapon Arsenal & Stealth Assassinations
- [x] **P2-T01**: Implement `WeaponSwapManager` cycling Katana $\to$ Naginata $\to$ Kunai via `weapon_swap` (`Q`).
  - *Files Touched*: `scenes/player/combat/weapon_swap.gd` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED
- [x] **P2-T02**: Implement `WeaponNaginata` with 52 px reach, group piercing, and overhead lantern strikes.
  - *Files Touched*: `scenes/player/combat/weapon_naginata.gd` | *Owner*: Opus 5.5 | *Status*: COMPLETED
- [x] **P2-T03**: Implement `WeaponKunai` with rapid 4-hit flurry, low noise profile, and wall-cling slice.
  - *Files Touched*: `scenes/player/combat/weapon_kunai.gd` | *Owner*: Opus 5.5 | *Status*: COMPLETED
- [x] **P2-T04**: Implement `AssassinationSystem` for instant stealth rear finishers on unaware guards.
  - *Files Touched*: `scenes/player/combat/assassination.gd`, `tests/test_combat_stealth.gd` | *Owner*: Opus 5.5 | *Status*: COMPLETED
- [x] **P2-T05**: Implement thrown physical shuriken on `ability_primary` (`F`) for remote distractions.
  - *Files Touched*: `scenes/player/subweapons/shuriken.gd` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED
- [x] **P2-T06**: Execute `test_combat_weapons.gd` and capture evidence to `/qa/shots/phase_2/`.
  - *Files Touched*: `tests/test_combat_weapons.gd` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED

---

### PHASE 3: Adversary Roster (Part 1 — Ashigaru & Sentry)
- [x] **P3-T01**: Wire `HealthComponent`, `PoiseComponent`, and `HurtboxComponent` into `enemy_base.gd`.
  - *Files Touched*: `scenes/enemies/enemy_base.gd` | *Owner*: Opus 5.5 | *Status*: COMPLETED
- [x] **P3-T02**: Implement `Ashigaru` spearman FSM with 27-frame telegraph glint and yari thrust.
  - *Files Touched*: `scenes/enemies/ashigaru.tscn`, `scenes/enemies/states/st_thrust.gd` | *Owner*: Opus 5.5 | *Status*: COMPLETED
- [x] **P3-T03**: Wire attack token request/release into enemy attack startup states.
  - *Files Touched*: `scenes/enemies/enemy_base.gd`, `autoload/attack_token_manager.gd` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED
- [x] **P3-T04**: Enable Katana parry to reflect sentry projectiles back into the turret.
  - *Files Touched*: `scenes/enemies/projectile.gd`, `scenes/enemies/sentry.gd` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED
- [x] **P3-T05**: Execute `test_step_e.js` and `test_ai_ashigaru.gd`. Log screenshots to `/qa/shots/phase_3/`.
  - *Files Touched*: `tests/test_ai_ashigaru.gd` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED

---

### PHASE 4: Adversary Roster (Part 2 — Kenshi, Yumi & Oni Brute)
- [x] **P4-T01**: Implement `Kenshi` duelist AI with auto-parry, back-dash evasion, and spinning sweep.
  - *Files Touched*: `scenes/enemies/kenshi.tscn`, `scenes/enemies/states/st_kenshi_duel.gd` | *Owner*: Opus 5.5 | *Status*: COMPLETED
- [x] **P4-T02**: Implement `Yumi` balcony archer AI with 400 px laser aiming and acoustic arrows.
  - *Files Touched*: `scenes/enemies/yumi.tscn`, `scenes/enemies/states/st_yumi_aim.gd` | *Owner*: Opus 5.5 | *Status*: COMPLETED
- [x] **P4-T03**: Implement `Oni Brute` armor immunity, club ground slam, and glass shattering.
  - *Files Touched*: `scenes/enemies/brute.tscn`, `scenes/enemies/states/st_brute_slam.gd` | *Owner*: Opus 5.5 | *Status*: COMPLETED
- [x] **P4-T04**: Run automated AI unit suite and log enemy duel screenshots to `/qa/shots/phase_4/`.
  - *Files Touched*: `tests/test_ai_brute.gd` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED

---

### PHASE 5: Vertical Level Pipeline & Zero Soft-Locks (Levels 1–9)
- [x] **P5-T01**: Upgrade `LevelValidator` with bidirectional return path simulation and jump apex limits.
  - *Files Touched*: `scenes/level/level_validator.gd`, `tests/test_validator.gd` | *Owner*: Opus 5.5 | *Status*: COMPLETED
- [x] **P5-T02**: Fix Level 3 stacked corridors soft-lock by adding overhead release ladder `H`.
  - *Files Touched*: `levels/level_03.txt`, `scenes/interactables/ladder.gd` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED
- [x] **P5-T03**: Author and validate vertical maps for Levels 1, 2, and 4 (Wake, Acoustic Bay, Glass Foundry).
  - *Files Touched*: `levels/level_01.txt`, `level_02.txt`, `level_04.txt` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED
- [x] **P5-T04**: Author and validate vertical maps for Levels 5, 6, and 7 (Resonance Deep, Vents, Great Seal).
  - *Files Touched*: `levels/level_05.txt`, `level_06.txt`, `level_07.txt` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED
- [x] **P5-T05**: Author and validate vertical maps for Levels 8 and 9 (Redoubt Perimeter, Shogun Citadel).
  - *Files Touched*: `levels/level_08.txt`, `level_09.txt` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED
- [x] **P5-T06**: Upgrade `camera_rig.gd` with 48 px look-ahead and dynamic combat zoom (1.8x to 1.45x).
  - *Files Touched*: `scenes/fx/camera_rig.gd` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED
- [x] **P5-T07**: Run `test_validator.gd`. Confirm 0 errors; capture evidence to `/qa/shots/phase_5/`.
  - *Files Touched*: `tests/test_validator.gd` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED

---

### PHASE 6: Escape-Room Puzzle Layer & Cryptography
- [x] **P6-T01**: Implement centralized `PuzzleController` managing multi-node puzzle triggers.
  - *Files Touched*: `scenes/interactables/puzzle_controller.gd` | *Owner*: Opus 5.5 | *Status*: COMPLETED
- [x] **P6-T02**: Implement `EchoGlyph` (tier-selective reveal) and `ResonancePanel` (frequency matching).
  - *Files Touched*: `scenes/interactables/echo_glyph.gd`, `resonance_panel.gd` | *Owner*: Opus 5.5 | *Status*: COMPLETED
- [x] **P6-T03**: Implement `HarmonicLantern` sequence (striking 1-2-3 in 8.0s unlocks blast gate).
  - *Files Touched*: `scenes/interactables/harmonic_lantern.gd` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED
- [x] **P6-T04**: Implement `SealLock` multi-node airlock gates requiring dual keys or simultaneous plates.
  - *Files Touched*: `scenes/interactables/seal_lock.gd` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED
- [x] **P6-T05**: Wire `H` key to emit emergency directional acoustic hint beacon towards `E`.
  - *Files Touched*: `scenes/player/hint_beacon.gd` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED
- [x] **P6-T06**: Execute puzzle unit suite. Capture evidence to `/qa/shots/phase_6/`.
  - *Files Touched*: `tests/test_puzzle_resonance.gd` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED

---

### PHASE 7: Visual Overhaul, Scarf Physics & Tactical HUD
- [x] **P7-T01**: Redraw Cipher-0 samurai vector rig (54 px height) with articulated limbs and scabbard.
  - *Files Touched*: `scenes/player/player_visual.gd` | *Owner*: Opus 5.5 | *Status*: COMPLETED
- [x] **P7-T02**: Implement Verlet physics scarf trailing velocity, wind, and inertia behind the hero.
  - *Files Touched*: `scenes/player/visuals/scarf_physics.gd` | *Owner*: Opus 5.5 | *Status*: COMPLETED
- [x] **P7-T03**: Redraw enemy silhouettes (Ashigaru, Kenshi, Yumi, Brute) with distinctive shape contours.
  - *Files Touched*: `scenes/enemies/visuals/*_visual.gd` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED
- [x] **P7-T04**: Implement procedural curved white `Line2D` slash trails with directional sparks.
  - *Files Touched*: `scenes/fx/slash_arc.gd`, `shaders/slash_arc.gdshader` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED
- [x] **P7-T05**: Overhaul `hud.tscn` to match target reference: weapon badge, segmented health, score.
  - *Files Touched*: `scenes/ui/hud.gd`, `scenes/ui/hud.tscn` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED
- [x] **P7-T06**: Implement 3-plane parallax background builder (shoji screens, gantries, pillars).
  - *Files Touched*: `scenes/world/background_builder.gd` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED
- [x] **P7-T07**: Execute `test_step_c.js` and `test_step_d.js`. Log evidence to `/qa/shots/phase_7/`.
  - *Files Touched*: `tests/e2e/test_step_d.js`, `tests/e2e/test_phase_7.js` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED

---

### PHASE 8: Shogun Mech Climax Boss & Audio Polish
- [x] **P8-T01**: Implement Shogun Mech Phase 1 (Naginata sweeps) and Phase 2 (Acoustic shockwaves).
  - *Files Touched*: `scenes/enemies/boss_shogun.tscn`, `st_shogun_phase1.gd` | *Owner*: Opus 5.5 | *Status*: COMPLETED
- [x] **P8-T02**: Implement Shogun Mech Phase 3 (Sonic dash, berserk flurry, electrified floor).
  - *Files Touched*: `scenes/enemies/states/st_shogun_phase3.gd` | *Owner*: Opus 5.5 | *Status*: COMPLETED
- [x] **P8-T03**: Implement bottom-center 480 px boss vitality and poise meter (`BossBar`).
  - *Files Touched*: `scenes/ui/boss_health_bar.gd` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED
- [x] **P8-T04**: Implement dynamic taiko percussion cross-fader in `music_layers.gd` triggered on alert.
  - *Files Touched*: `audio/music_layers.gd` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED
- [x] **P8-T05**: Synthesize metallic combat clangs, blade swooshes, and parry deflects in `sfx_library.gd`.
  - *Files Touched*: `audio/sfx_library.gd` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED
- [x] **P8-T06**: Execute `test_boss_shogun.gd`. Capture boss battle evidence to `/qa/shots/phase_8/`.
  - *Files Touched*: `tests/test_boss_shogun.gd` | *Owner*: Sonnet 5.5 | *Status*: COMPLETED

---

### PHASE 9: Final Hardening, Web Soak Pass & Release Gate
- [ ] **P9-T01**: Automate end-to-end traversal of Levels 1 through 9; verify medal awards.
  - *Files Touched*: `tests/e2e/test_campaign_full.js` | *Owner*: Opus 5.5 | *Status*: PENDING
- [ ] **P9-T02**: Execute 60-second continuous multi-level gameplay soak test across continuous combat.
  - *Files Touched*: `tests/e2e/test_soak.js` | *Owner*: Sonnet 5.5 | *Status*: PENDING
- [ ] **P9-T03**: Benchmark 60 FPS performance on integrated graphics; validate Low Quality mode.
  - *Files Touched*: `scenes/ui/settings_menu.gd` | *Owner*: Sonnet 5.5 | *Status*: PENDING
- [ ] **P9-T04**: Package and verify production WebAssembly build; validate COOP/COEP isolation headers.
  - *Files Touched*: `export_presets.cfg`, `tools/serve.js` | *Owner*: Sonnet 5.5 | *Status*: PENDING
- [ ] **P9-T05**: Compile master QA evidence report in `qa/QA_REPORT.md` and finalize `CHANGELOG.md`.
  - *Files Touched*: `qa/QA_REPORT.md`, `CHANGELOG.md` | *Owner*: Sonnet 5.5 | *Status*: PENDING
