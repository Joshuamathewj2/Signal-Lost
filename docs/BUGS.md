# SIGNAL LOST — Bug Bash & Regression Log (Phase 9)

## 1. Bug Registry Summary
All P1 (blocker/crash) and P2 (gameplay critical) defects discovered during phase test plan regressions and gameplay sweeps have been addressed and verified.
Zero open P1/P2 bugs remain.

| ID | Severity | Area | Symptom | Root Cause | Fix / Resolution | Status |
|---|---|---|---|---|---|---|
| BUG-01 | P1 | Navigation / AI | Listeners only walked right on solid ground; reverse walk pathfinding failed | `AStar2D.are_points_connected(a,b)` returns true if an edge exists in *either* direction; skipped reverse directed walk edges | Replaced with `not astar.get_point_connections(from).has(to)` | FIXED |
| BUG-02 | P1 | Level / Doors | Door cells `D` and `R` blocked player navigation permanently after key collection | Door cells were omitted from standable graph during `build()`, preventing `set_door_open()` from re-enabling | Registered door nodes as standable but initially disabled; enabled across 2-tall runs on open | FIXED |
| BUG-03 | P2 | Interactables / Decoy | DecoyBeacon could not locate `SonarSystem` if root structure varied | Missing group tag on `SonarSystem` | Added `add_to_group(&"sonar_system")` in `SonarSystem._ready()` | FIXED |
| BUG-04 | P2 | UI / Hint Signs | Hint signs visible in pitch black without illumination | Default canvas item material was rendered without mask | Replaced with `flat_reveal.gdshader` unshaded material revealed only by active sonar bubbles | FIXED |
| BUG-05 | P2 | Performance / Low Quality | Headless tests triggered null tree access during quality mode switching | `_connect_player()` called `get_tree()` on orphaned node instances | Added `is_inside_tree()` guard and clamped bubble indices to `mini(4, pool.size())` | FIXED |
| BUG-06 | P3 | Audio / Bus Layout | Engine modified `default_bus_layout.tres` UID during tests | Godot 4.4+ auto-generates UID tags on resave | Reverted uncommitted metadata modifications to preserve git cleanliness | FIXED |

---

## 2. Test Plan (TP) Full Regression Verification

### TP Phase 0 — Foundation & Config
- [x] GL Compatibility renderer confirmed in `project.godot`.
- [x] 1280×720 canvas_items / expand stretch confirmed.
- [x] Input map: 11 actions (move_left, move_right, jump, sneak, pulse, ability_primary, etc.) verified with keyboard + gamepad.
- [x] Resources: all 11 `.tres` data files load cleanly with accurate profiles (`test_resources.gd`).

### TP Phase 1 — Player Controller & Movement
- [x] Acceleration 1400 px/s², top speed 180 px/s, friction 1800 px/s².
- [x] Sneak mode caps speed at 70 px/s, height 12 px, produces 0 footsteps.
- [x] Jump arc clears 2-tile high steps; fails on 3-tile steps (`test_platform_graph.gd`).
- [x] Coyote time (0.10s) and jump buffering (0.12s) verified.
- [x] Catwalk drop-through (`Down + Jump`) functioning smoothly.
- [x] Concentric charge rings expand from Whisper to Normal to Scream (`test_pulse_tiers.gd`).

### TP Phase 2 — Sonar & Visuals
- [x] Complete pitch black ambient world (`CanvasModulate` #000000).
- [x] Expanding wavefronts with hard light occlusion behind solid geometry.
- [x] Torn-paper jagged white edge lines with top debris specks.
- [x] Multi-layer parallax background props at z -10, -20, -30.
- [x] Echo memory (12% ghost energy over 2.0s) verified.

### TP Phase 3 — Hearing & Enemy AI
- [x] Listener patrol, antenna ripple, and investigation state machine (`test_hearing.gd`, `test_state_machine.gd`).
- [x] Distance-based attenuation with wall penetration penalty (0.75 / wall).
- [x] Red smudge silhouette rendered when investigating outside lit bubbles.
- [x] Floating 1px unshaded awareness meters and reticles (`test_awareness_reticles.gd`).

### TP Phase 4 — ASCII Level Pipeline
- [x] LevelParser parses ASCII files into `LevelData` with strict error handling (`test_level_parser.gd`).
- [x] SolidMerger merges runs into optimal rect colliders and occluders.
- [x] All 8 levels validated by `LevelValidator` with 0 errors (`test_validator.gd`).

### TP Phase 5 — Enemies & Interactables
- [x] Sentry: 40° tracking cone, laser sight, red lethal projectile firing.
- [x] Hunter: 3-step acoustic memory, 230 px/s sprint speed.
- [x] Deaf Brute: deaf to airborne voice pulses, lethal on contact.
- [x] Doors, keys, pressure plates, one-way gates, glass floors, lanterns, and paired vents functioning per spec.

### TP Phase 6 — Audio & Visual Polish
- [x] Procedural SfxLibrary generates all sounds headlessly in < 250 ms.
- [x] PostFx: film grain, vignette, chromatic aberration, and detection flash.
- [x] Camera shake and zoom punches configured per pulse tier.

### TP Phase 7 — UI & Progression
- [x] HUD battery meter, ghost cost preview, fragment counter, and progress bar (`test_hud.gd`).
- [x] Glitched main menu and pause menu with audio ducking (`test_main_menu.gd`, `test_pause_menu.gd`).
- [x] Settings menu with persistent audio sliders and accessibility toggles (`test_settings.gd`).
- [x] 4×2 mission select grid and completion summary screen with medals (`test_level_select_complete.gd`, `test_medals.gd`).

### TP Phase 8 — Content Progression
- [x] Decoy beacons distract enemies and update HUD pips (`test_decoy.gd`).
- [x] In-world lit-only hint signs deployed (`test_hint_signs.gd`).
- [x] Levels 1–8 campaign verified with full difficulty curve.
- [x] Ghost medal verified viable on all 8 levels.

### TP Phase 9 — Performance & Quality
- [x] Quality Mode LOW drops active bubbles 6 → 4, disables shadows, and omits NearLayer parallax (`test_performance_mode.gd`).
- [x] Performance report demonstrates 61.4 FPS in HIGH and 92.8 FPS in LOW (+51.1% uplift).
