# SIGNAL LOST — Master Phased Implementation Plan (V2)

- **Purpose**: Definitive production roadmap and granular task breakdown (Phases 0 through 9) specifying session-sized tasks (<250 lines of code), dependencies, files touched, acceptance criteria, regression tests, model recommendations, and milestone gates.
- **Audience**: Technical Directors, Producers, AI Coding Agents (Gemini, Claude Sonnet/Opus).
- **Status**: Approved.
- **Last Updated**: 2026-10-12.
- **Depends On**: [00_CURRENT_STATE_AUDIT.md](file:///c:/vibe-game/docs/00_CURRENT_STATE_AUDIT.md), [PRD.md](file:///c:/vibe-game/docs/PRD.md), [ARCHITECTURE.md](file:///c:/vibe-game/docs/ARCHITECTURE.md), [QA_TEST_PLAN.md](file:///c:/vibe-game/docs/QA_TEST_PLAN.md).

---

## 1. Production Milestones & Critical Path

```
  ┌─────────────────────────────────────────────────────────────────┐
  │ M0: FOUNDATION & COMBAT PRIMITIVES (Phases 0–1)                 │
  │ Baseline health components, Katana combos, parry deflects.      │
  ├────────────────────────────────┬────────────────────────────────┤
                                   │
                                   ▼
  ┌─────────────────────────────────────────────────────────────────┐
  │ M1: PLAYABLE VERTICAL SLICE (Phases 2–3)                        │
  │ Level 3 playable: Naginata unlock, Ashigaru duels, return shaft.│
  ├────────────────────────────────┬────────────────────────────────┤
                                   │
                                   ▼
  ┌─────────────────────────────────────────────────────────────────┐
  │ M2: FULL ADVERSARY & LEVEL ROSTER (Phases 4–5)                  │
  │ Complete 6-tier enemy roster, Levels 1–9 vertical layouts.      │
  ├────────────────────────────────┬────────────────────────────────┤
                                   │
                                   ▼
  ┌─────────────────────────────────────────────────────────────────┐
  │ M3: ESCAPE-ROOM PUZZLES & AESTHETIC POLISH (Phases 6–7)         │
  │ Resonance panels, echo glyphs, vector samurai rig, scarf.       │
  ├────────────────────────────────┬────────────────────────────────┤
                                   │
                                   ▼
  ┌─────────────────────────────────────────────────────────────────┐
  │ M4: SHOGUN MECH & FINAL RELEASE GATE (Phases 8–9)               │
  │ 3-phase boss encounter, procedural audio, 60 FPS web soak pass. │
  └─────────────────────────────────────────────────────────────────┘
```

- **Critical Path**: Combat Primitives (P1) $\to$ Weapon Integration (P2) $\to$ Adversary FSMs (P3) $\to$ Vertical Levels & Validator (P5) $\to$ Puzzle Tooling (P6) $\to$ Boss Climax (P8) $\to$ Web Release (P9).

---

## 2. Feature Cut-Order List (Scope Buffer)

If schedule or token budget tightens, features must be dropped strictly in this reverse priority order:
1. **Cut 1 (First to drop)**: Codex / Lore Fragment Inspection modal (replace with simple victory text).
2. **Cut 2**: Grappling Wire secondary tool (Level 7 traversal uses wall-kick shafts instead).
3. **Cut 3**: Color-blind diagonal hatch shader pattern (keep high-contrast white outline).
4. **Cut 4**: Ambient Koto arpeggio dynamic music layer (keep two layers: ambient drone + taiko percussion).
5. **NEVER CUT (Core Identity)**: Three primary weapons, parry deflect, sonar pulse reveal, darkness occlusion, 6 enemy archetypes, 9 vertical levels with zero soft-locks.

---

## 3. Granular Phase Breakdown (Phases 0 to 9)

Every task is designed for a **single autonomous agent session** ($\le 250$ lines of code changed).

---

### PHASE 0: Architectural Hygiene & Regression Setup
- **Goal**: Register new singletons, prepare combat resources, configure input actions, and verify existing V1 regression safety.
- **Deliverables**: Updated `project.godot`, `AttackTokenManager` singleton, `combat_config.tres`, base input actions.
- **Regression Gate**: `godot --headless -s res://tests/run_tests.gd` (ALL 17 PASS), `test_gate_a.js` (PASS).

| Task ID | Task Title & Scope | Files Touched | Est. LOC | Model |
|---|---|---|---|---|
| **P0-T01** | **Input Map Expansion**: Add `attack`, `attack_heavy`, `dash`, `block_parry`, `weapon_swap`, `hint` actions with keys and pads to `project.godot`. | `project.godot` | ~40 lines | Sonnet 5.5 |
| **P0-T02** | **AttackTokenManager Autoload**: Create singleton coordinating enemy attack concurrency (max 2 active tokens). | `autoload/attack_token_manager.gd`, `project.godot` | ~75 lines | Opus 5.5 |
| **P0-T03** | **Combat Config Resource**: Create `AttackData` resource script and default combat tunables in `resources/config/combat_config.tres`. | `scripts/resources/attack_data.gd`, `resources/config/combat_config.tres` | ~90 lines | Sonnet 5.5 |
| **P0-T04** | **Regression Verification**: Run all 17 unit tests and `test_gate_a.js`. Log baseline screenshots to `/qa/shots/phase_0/`. | `tests/e2e/test_gate_a.js` | ~15 lines | Sonnet 5.5 |

---

### PHASE 1: Combat Primitives & Health Refactor
- **Goal**: Replace instant 1-hit death with 3-segment health, implement poise/stagger, and wire basic Katana combo slashes.
- **Deliverables**: Reusable `HealthComponent`, `PoiseComponent`, `HitboxComponent`, `HurtboxComponent`, Katana 3-hit combo.
- **Regression Gate**: Unit tests pass; hero movement and pulse charging remain 100% intact.

| Task ID | Task Title & Scope | Files Touched | Est. LOC | Model |
|---|---|---|---|---|
| **P1-T01** | **HealthComponent Extraction**: Create reusable component managing integer segments, i-frames, and death signals. | `scenes/combat/health_component.gd`, `tests/test_health_system.gd` | ~110 lines | Opus 5.5 |
| **P1-T02** | **PoiseComponent & Stagger**: Create poise meter tracking balance (100.0 max), poise damage, and stagger triggers. | `scenes/combat/poise_component.gd`, `tests/test_combat_guard.gd` | ~95 lines | Opus 5.5 |
| **P1-T03** | **Hitbox & Hurtbox Components**: Standardize 2D area triggers for dealing and receiving typed attack damage. | `scenes/combat/hitbox_component.gd`, `scenes/combat/hurtbox_component.gd` | ~85 lines | Sonnet 5.5 |
| **P1-T04** | **CombatController & Katana Slashes**: Implement `CombatController` on player handling `J` combo slashes and noise emission. | `scenes/player/combat_controller.gd`, `scenes/player/player.gd` | ~140 lines | Opus 5.5 |
| **P1-T05** | **Parry & Deflect System**: Implement 6-frame deflect window on `block_parry` with 40 poise damage and spark triggers. | `scenes/player/combat/parry_system.gd`, `tests/test_combat_parry.gd` | ~120 lines | Opus 5.5 |
| **P1-T06** | **Hero Dash & I-Frames**: Implement 15-frame dash roll on `L` with 12 i-frames and 0.50s cooldown. | `scenes/player/combat/dash_system.gd`, `scenes/player/player_motor.gd` | ~80 lines | Sonnet 5.5 |
| **P1-T07** | **Phase 1 Verification**: Execute `test_combat_combo.gd` and capture combat evidence to `/qa/shots/phase_1/`. | `tests/test_combat_combo.gd` | ~60 lines | Sonnet 5.5 |

---

### PHASE 2: Weapon Arsenal & Stealth Assassinations
- **Goal**: Implement the Naginata (piercing reach), Twin Kunai (silent flurry), weapon swapping (`Q`), and rear assassinations.
- **Deliverables**: `WeaponNaginata`, `WeaponKunai`, `WeaponSwapManager`, `AssassinationSystem`.
- **Regression Gate**: `test_combat_weapons.gd` (PASS), `test_combat_stealth.gd` (PASS).

| Task ID | Task Title & Scope | Files Touched | Est. LOC | Model |
|---|---|---|---|---|
| **P2-T01** | **Weapon Swap Manager**: Implement `weapon_swap` logic cycling Katana $\to$ Naginata $\to$ Kunai. | `scenes/player/combat/weapon_swap.gd` | ~90 lines | Sonnet 5.5 |
| **P2-T02** | **Naginata Spear Implementation**: Implement 52 px reach thrusts, group piercing, and high-altitude lantern hits. | `scenes/player/combat/weapon_naginata.gd` | ~130 lines | Opus 5.5 |
| **P2-T03** | **Twin Kunai Flurry Implementation**: Implement rapid 4-hit flurry (low noise, 20 px reach) and wall-cling slice. | `scenes/player/combat/weapon_kunai.gd` | ~140 lines | Opus 5.5 |
| **P2-T04** | **Stealth Assassination System**: Detect rear unaware targets ($\le 28 \text{ px}$); execute lethal 0.40s takedown. | `scenes/player/combat/assassination.gd`, `tests/test_combat_stealth.gd` | ~120 lines | Opus 5.5 |
| **P2-T05** | **Sub-Weapon Shuriken**: Implement thrown physical shuriken on `ability_primary` (`F`) for remote distractions. | `scenes/player/subweapons/shuriken.gd` | ~85 lines | Sonnet 5.5 |
| **P2-T06** | **Phase 2 Verification**: Run `test_combat_weapons.gd`. Capture evidence to `/qa/shots/phase_2/`. | `tests/test_combat_weapons.gd` | ~40 lines | Sonnet 5.5 |

---

### PHASE 3: Adversary Roster (Part 1 — Ashigaru & Sentry)
- **Goal**: Integrate `HealthComponent` and `HurtboxComponent` into enemy base; implement Ashigaru spearman and enhance Sentry turret.
- **Deliverables**: `Ashigaru` enemy scene, updated `Sentry`, attack token integration.
- **Regression Gate**: `test_ai_ashigaru.gd` (PASS), `test_step_e.js` (PASS).

| Task ID | Task Title & Scope | Files Touched | Est. LOC | Model |
|---|---|---|---|---|
| **P3-T01** | **EnemyBase Combat Integration**: Wire `HealthComponent`, `PoiseComponent`, and `HurtboxComponent` into `enemy_base.gd`. | `scenes/enemies/enemy_base.gd` | ~110 lines | Opus 5.5 |
| **P3-T02** | **Ashigaru FSM & States**: Implement `st_thrust.gd` and `st_patrol.gd` with 27-frame telegraph glint. | `scenes/enemies/ashigaru.tscn`, `scenes/enemies/states/st_thrust.gd` | ~150 lines | Opus 5.5 |
| **P3-T03** | **Attack Token Integration**: Wire `request_token()` and `release_token()` into enemy attack startup. | `scenes/enemies/enemy_base.gd`, `autoload/attack_token_manager.gd` | ~70 lines | Sonnet 5.5 |
| **P3-T04** | **Sentry Deflect Interaction**: Enable Katana parry to reflect sentry projectiles back into the turret. | `scenes/enemies/projectile.gd`, `scenes/enemies/sentry.gd` | ~85 lines | Sonnet 5.5 |
| **P3-T05** | **Phase 3 Verification**: Execute `test_step_e.js` and `test_ai_ashigaru.gd`. Log screenshots to `/qa/shots/phase_3/`. | `tests/test_ai_ashigaru.gd` | ~50 lines | Sonnet 5.5 |

---

### PHASE 4: Adversary Roster (Part 2 — Kenshi, Yumi & Oni Brute)
- **Goal**: Implement Kenshi duelist (parry/dodge), Yumi archer (laser sight, acoustic arrows), and Oni Brute (heavy mech).
- **Deliverables**: `Kenshi`, `Yumi`, `OniBrute` enemy scenes and AI states.
- **Regression Gate**: `test_ai_kenshi.gd`, `test_ai_yumi.gd`, `test_ai_brute.gd` (ALL PASS).

| Task ID | Task Title & Scope | Files Touched | Est. LOC | Model |
|---|---|---|---|---|
| **P4-T01** | **Kenshi Duelist AI**: Implement auto-parry, back-dash evasion, and spinning unblockable sweep. | `scenes/enemies/kenshi.tscn`, `scenes/enemies/states/st_kenshi_duel.gd` | ~160 lines | Opus 5.5 |
| **P4-T02** | **Yumi Balcony Archer AI**: Implement 400 px laser aiming, acoustic arrows (520 px/s), and retreat flip. | `scenes/enemies/yumi.tscn`, `scenes/enemies/states/st_yumi_aim.gd` | ~140 lines | Opus 5.5 |
| **P4-T03** | **Oni Brute Armor & Slam**: Implement Katana slash immunity, kanabo club slam, and glass floor shattering. | `scenes/enemies/brute.tscn`, `scenes/enemies/states/st_brute_slam.gd` | ~150 lines | Opus 5.5 |
| **P4-T04** | **Phase 4 Verification**: Run automated AI unit suite and capture enemy duels to `/qa/shots/phase_4/`. | `tests/test_ai_brute.gd` | ~60 lines | Sonnet 5.5 |

---

### PHASE 5: Vertical Level Pipeline & Zero Soft-Locks (Levels 1–9)
- **Goal**: Ingest full 9-level campaign; eliminate Level 3 stacked-corridor soft-lock; enforce return path verification.
- **Deliverables**: `levels/level_01.txt` through `level_09.txt`, updated `level_validator.gd`, return ladder entities.
- **Regression Gate**: `test_validator.gd` (100% reachability across Levels 1–9 with 0 errors).

| Task ID | Task Title & Scope | Files Touched | Est. LOC | Model |
|---|---|---|---|---|
| **P5-T01** | **LevelValidator Reachability Upgrade**: Add bidirectional return path simulation and jump apex limits. | `scenes/level/level_validator.gd`, `tests/test_validator.gd` | ~140 lines | Opus 5.5 |
| **P5-T02** | **Level 3 Architecture Refactor**: Fix three stacked corridors soft-lock by adding overhead release ladder `H`. | `levels/level_03.txt`, `scenes/interactables/ladder.gd` | ~80 lines | Sonnet 5.5 |
| **P5-T03** | **Levels 1, 2, 4 Layouts**: Author and validate vertical maps for Wake, Acoustic Bay, and Glass Foundry. | `levels/level_01.txt`, `level_02.txt`, `level_04.txt` | ~100 lines | Sonnet 5.5 |
| **P5-T04** | **Levels 5, 6, 7 Layouts**: Author and validate maps for Resonance Deep, Ventilation Vault, and The Great Seal. | `levels/level_05.txt`, `level_06.txt`, `level_07.txt` | ~110 lines | Sonnet 5.5 |
| **P5-T05** | **Levels 8, 9 Layouts**: Author and validate maps for Redoubt Perimeter and Shogun Citadel. | `levels/level_08.txt`, `level_09.txt` | ~100 lines | Sonnet 5.5 |
| **P5-T06** | **Dynamic Camera Framing**: Update `camera_rig.gd` with 48 px look-ahead and dynamic combat zoom (1.8x to 1.45x). | `scenes/fx/camera_rig.gd` | ~90 lines | Sonnet 5.5 |
| **P5-T07** | **Phase 5 Verification**: Run `test_validator.gd`. Confirm 0 errors; capture evidence to `/qa/shots/phase_5/`. | `tests/test_validator.gd` | ~30 lines | Sonnet 5.5 |

---

### PHASE 6: Escape-Room Puzzle Layer & Cryptography
- **Goal**: Implement Echo Glyphs, Resonance Panels, Harmonic Lanterns, Seal Locks, and emergency Hint Beacon (`H`).
- **Deliverables**: `PuzzleController`, `EchoGlyph`, `ResonancePanel`, `HarmonicLantern`, `SealLock`, `HintBeacon`.
- **Regression Gate**: `test_puzzle_glyphs.gd`, `test_puzzle_resonance.gd` (ALL PASS).

| Task ID | Task Title & Scope | Files Touched | Est. LOC | Model |
|---|---|---|---|---|
| **P6-T01** | **PuzzleController Architecture**: Implement centralized puzzle coordinator tracking completion states. | `scenes/interactables/puzzle_controller.gd` | ~95 lines | Opus 5.5 |
| **P6-T02** | **Echo Glyphs & Resonance Panels**: Implement pulse-tier selective reveal and acoustic frequency matching. | `scenes/interactables/echo_glyph.gd`, `resonance_panel.gd` | ~130 lines | Opus 5.5 |
| **P6-T03** | **Harmonic Lantern Sequences**: Implement musical pitch sequencing (striking 1-2-3 in 8.0s unlocks gate). | `scenes/interactables/harmonic_lantern.gd` | ~120 lines | Sonnet 5.5 |
| **P6-T04** | **Seal Locks & Dual Artifacts**: Implement airlock requiring dual keys or simultaneous plate triggers. | `scenes/interactables/seal_lock.gd` | ~90 lines | Sonnet 5.5 |
| **P6-T05** | **Emergency Exit Hint Beacon**: Wire `H` key to emit directional acoustic ripple towards `E` ($r=120 \text{ px}$ noise). | `scenes/player/hint_beacon.gd` | ~85 lines | Sonnet 5.5 |
| **P6-T06** | **Phase 6 Verification**: Execute puzzle unit suite. Capture evidence to `/qa/shots/phase_6/`. | `tests/test_puzzle_resonance.gd` | ~45 lines | Sonnet 5.5 |

---

### PHASE 7: Visual Overhaul, Scarf Physics & Tactical HUD
- **Goal**: Upgrade hero to articulated samurai vector silhouette with Verlet scarf, redraw enemy silhouettes, and overhaul HUD.
- **Deliverables**: `player_visual.gd`, `scarf_physics.gd`, enemy visual sheets, tactical samurai HUD.
- **Regression Gate**: `test_step_c.js` (PASS), `test_step_d.js` (PASS).

| Task ID | Task Title & Scope | Files Touched | Est. LOC | Model |
|---|---|---|---|---|
| **P7-T01** | **Samurai Vector Rig**: Redraw Cipher-0 chassis (54 px height) with articulated limbs and katana scabbard. | `scenes/player/player_visual.gd` | ~160 lines | Opus 5.5 |
| **P7-T02** | **Verlet Scarf Physics**: Implement 6-node trailing scarf with gravity, drag, and velocity inertia. | `scenes/player/visuals/scarf_physics.gd` | ~110 lines | Opus 5.5 |
| **P7-T03** | **Enemy Silhouette Overhaul**: Redraw Ashigaru, Kenshi, Yumi, and Brute with distinctive shape contours. | `scenes/enemies/visuals/*_visual.gd` | ~180 lines | Sonnet 5.5 |
| **P7-T04** | **Procedural Slash Arcs**: Build curved `Line2D` slash trails matching swing direction and fade times. | `scenes/fx/slash_arc.gd`, `shaders/slash_arc.gdshader` | ~95 lines | Sonnet 5.5 |
| **P7-T05** | **Tactical Samurai HUD**: Implement top-left score/fragments, bottom-left weapon badge, and segmented health. | `scenes/ui/hud.gd`, `scenes/ui/hud.tscn` | ~150 lines | Sonnet 5.5 |
| **P7-T06** | **Shoji Parallax Backgrounds**: Deploy 3-plane feudal-industrial parallax props (shoji, gantries, pillars). | `scenes/world/background_builder.gd` | ~120 lines | Sonnet 5.5 |
| **P7-T07** | **Phase 7 Verification**: Execute `test_step_c.js` and `test_step_d.js`. Log evidence to `/qa/shots/phase_7/`. | `tests/e2e/test_step_d.js` | ~25 lines | Sonnet 5.5 |

---

### PHASE 8: Shogun Mech Climax Boss & Audio Polish
- **Goal**: Implement the 3-phase Shogun Mech boss fight in Sector 9 and deploy dynamic multi-layer combat music.
- **Deliverables**: `boss_shogun.tscn`, `BossBar`, `music_layers.gd` cross-fader, complete synthesized SFX.
- **Regression Gate**: `test_boss_shogun.gd` (PASS), `test_music_layers.gd` (PASS).

| Task ID | Task Title & Scope | Files Touched | Est. LOC | Model |
|---|---|---|---|---|
| **P8-T01** | **Shogun Mech Phase 1 & 2**: Implement twin naginata sweeps, overhead cleaves, and acoustic shockwaves. | `scenes/enemies/boss_shogun.tscn`, `st_shogun_phase1.gd` | ~180 lines | Opus 5.5 |
| **P8-T02** | **Shogun Mech Phase 3 & Arena**: Implement blackout sonic dash, berserk 5-hit flurry, and electrified floor. | `scenes/enemies/states/st_shogun_phase3.gd` | ~160 lines | Opus 5.5 |
| **P8-T03** | **Boss Vitality HUD**: Implement bottom-center 480 px health and poise bar with phase transition markers. | `scenes/ui/boss_health_bar.gd` | ~95 lines | Sonnet 5.5 |
| **P8-T04** | **Dynamic Music Taiko Cross-Fader**: Cross-fade ambient drone to 138 BPM taiko percussion on alert. | `audio/music_layers.gd` | ~110 lines | Sonnet 5.5 |
| **P8-T05** | **Procedural Combat SFX Library**: Synthesize metallic clangs, blade swooshes, and parry deflects. | `audio/sfx_library.gd` | ~130 lines | Sonnet 5.5 |
| **P8-T06** | **Phase 8 Verification**: Execute `test_boss_shogun.gd`. Capture boss battle evidence to `/qa/shots/phase_8/`. | `tests/test_boss_shogun.gd` | ~50 lines | Sonnet 5.5 |

---

### PHASE 9: Final Hardening, Web Soak Pass & Release Gate
- **Goal**: Full campaign playthrough verification, 60-second stability soak, Web export validation, and production packaging.
- **Deliverables**: Clean production Web build (`build/web/`), zero console errors, 100% test pass.
- **Regression Gate**: `test_soak.js` (PASS 60s soak), `test_gate_c.js` (PASS), zero engine warnings.

| Task ID | Task Title & Scope | Files Touched | Est. LOC | Model |
|---|---|---|---|---|
| **P9-T01** | **Full Campaign Playthrough Pass**: Automate traversal of Levels 1 through 9; verify medal awards. | `tests/e2e/test_campaign_full.js` | ~140 lines | Opus 5.5 |
| **P9-T02** | **Stability & Memory Soak**: Execute 60-second continuous multi-level soak loop with rapid combat. | `tests/e2e/test_soak.js` | ~50 lines | Sonnet 5.5 |
| **P9-T03** | **Performance & Quality Mode**: Verify 60 FPS on integrated graphics baseline; validate Low Quality toggle. | `scenes/ui/settings_menu.gd` | ~45 lines | Sonnet 5.5 |
| **P9-T04** | **Production Web Export Packaging**: Export release build; verify COOP/COEP server and bundle integrity. | `export_presets.cfg`, `tools/serve.js` | ~30 lines | Sonnet 5.5 |
| **P9-T05** | **Master Release Gate & Report**: Compile final QA evidence report in `qa/QA_REPORT.md` and update `CHANGELOG.md`. | `qa/QA_REPORT.md`, `CHANGELOG.md` | ~80 lines | Sonnet 5.5 |
