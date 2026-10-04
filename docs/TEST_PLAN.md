# SIGNAL LOST — Test Plan & Quality Assurance (v1.0)

## 1. Overview & Verification Strategy
SIGNAL LOST is built via phased AI vibe-coding. Each task and phase must end in a verifiable, non-broken build. Quality assurance is enforced across three testing tiers:
1. **Automated Static Headless Validation:** Parse error check and type checking on startup.
2. **Automated Unit & Scenario Tests (`res://tests/`):** Pure logic and mathematical verification running headlessly via a custom test harness (`run_tests.gd`).
3. **Manual Interactive Verification:** Step-by-step observable behaviors in dedicated sandbox scenes (`res://sandbox/`) and runtime debug overlays.

---

## 2. Test Execution Commands

### 2.1 Headless Syntax & Error Verification (PC)
Must run without syntax errors, script warnings, or parse exceptions:
```powershell
godot --headless --path . --quit-after 120
```
- **Pass Criteria:** Process exits normally with code 0. Zero occurrences of `SCRIPT ERROR`, `Parse Error`, or invalid resource loading logs in stderr/stdout.

### 2.2 Automated Unit Test Runner (TC)
Executes all test scripts matching `res://tests/test_*.gd`:
```powershell
godot --headless --path . -s res://tests/run_tests.gd
```
- **Pass Criteria:** Terminal prints `PASS test_<name>` for all test suites, concludes with `ALL TESTS PASSED`, and exits with return code 0.

---

## 3. Automated Test Suite Specification

| Test File | Target System | Specific Assertions & Scenarios |
|---|---|---|
| `tests/test_resources.gd` | Data Resources | Loads all 11 `.tres` files. Asserts `PulseProfile` noise radii: Whisper (43.2 px ±0.5), Normal (200 px ±0.5), Scream (728 px ±0.5). Verifies `MathUtil.bubble_brightness` curve values at t=0.05, t=fade_end, and dead. |
| `tests/test_pulse_tiers.gd` | Pulse Tiering & Battery | Verifies charge time mapping: [0, 0.35) -> Tier 0 (Whisper), [0.35, 0.85) -> Tier 1 (Normal), [0.85, 1.0] -> Tier 2 (Scream). Verifies energy downgrade: requesting Scream with 10 energy returns Whisper; requesting with 0 energy triggers `pulse_failed`. |
| `tests/test_hearing.gd` | Hearing Math & Attenuation | Unit tests `HearingComponent.evaluate()`: Whisper at 40 px is heard (strength > 0); Whisper at 50 px is rejected. Normal pulse (radius 200) behind 1 wall (effective dist `120 * 1.75 = 210`) is NOT heard. Footstep noise is rejected by Listener (below threshold 1.0) but accepted by Hunter. |
| `tests/test_state_machine.gd` | State Machine Logic | Verifies state machine lifecycle: `enter()` receives initial payload, `transition_to()` calls previous `exit()`, next `enter()`, and emits `state_changed`. |
| `tests/test_level_parser.gd` | ASCII Level Parsing | Loads and parses `levels/level_test.txt` and `level_01.txt`. Verifies row/column counts, grid consistency, `player_spawn` coordinates, `exit_cell` coordinates, and token counts. |
| `tests/test_platform_graph.gd` | Pathfinding & Navigation | Asserts reachable path from spawn to exit on Level 1. Asserts jump traversal on Level 2 catwalks. Asserts horizontal gap > 3 tiles or vertical step > 2 tiles rejects edge creation. |
| `tests/test_validator.gd` | Level Sanity Checks | Validates all 8 production levels: border integrity, spawn existence, exit existence, token validity, reachability. Tests 3 synthetic failure maps: missing exit, non-rectangular grid, enemy spawn within 5 tiles of player. |
| `tests/test_medals.gd` | Scoring & Medal Calculation | Evaluates run stats: 0 Normal/Scream pulses & 0 detections -> `Ghost`. 0 Screams & <= 1 detection -> `Quiet`. Multiple screams or detections -> `Loud`. |

---

## 4. Manual Verification & Acceptance Checklist per Phase

### Phase 0 — Foundation
- [ ] Open project in Godot 4.4+ editor: Verify no import errors or renderer incompatibilities.
- [ ] Confirm project settings: GL Compatibility renderer is active, viewport is 1280×720, stretch mode is `canvas_items`.
- [ ] Run `main.tscn`: Confirm pure black window opens. Press `F1` to toggle FPS overlay; press `F2` to cycle debug pages.

### Phase 1 — Player Controller & Mechanics
- [ ] Launch `sandbox/sandbox_player.tscn`.
- [ ] **Locomotion:** Robot accelerates smoothly to 180 px/s; stopping has slight friction.
- [ ] **Sneak:** Holding `Shift` lowers height to 12 px, caps speed to 70 px/s, produces zero footstep logs.
- [ ] **Jump Arc:** Robot clears 2-tile high steps; cannot clear 3-tile high steps.
- [ ] **Gaps:** Robot clears a 3-tile wide horizontal gap; fails and falls on a 4-tile gap.
- [ ] **Coyote & Buffer:** Pressing jump within 0.1 s after falling off a platform executes a jump. Pressing jump 0.1 s before touching the floor triggers immediately upon landing.
- [ ] **One-Way Platforms:** Can jump upward through catwalks; pressing `Down + Jump` drops through cleanly.
- [ ] **Pulse Charging:** Holding `K` or Left Mouse button displays expanding concentric rings (white inner reveal, red outer noise). Releasing drains red battery bar and triggers noise event.

### Phase 2 — Sonar & Visual Slice
- [ ] Launch `sandbox/sandbox_sonar.tscn`.
- [ ] **Darkness:** Ambient world is 100% black; only the player's 40 px glow light is visible at rest.
- [ ] **Wavefront & Occlusion:** Emitting a pulse sends a sharp white expanding dome that physically clips and casts hard shadows behind walls and floors.
- [ ] **Edge Treatment:** Solid platform surfaces reveal jagged, torn-paper white outlines with small grass/debris specks along top edges.
- [ ] **Parallax Depth:** 3 distinct grey depth planes (pipes, pillars, machinery) appear inside the illuminated dome and move with subtle parallax.
- [ ] **Echo Memory & Multi-Pulse:** Rapidly firing 6 pulses displays overlapping fading circles. Older circles sink to a faint 12% ghost brightness for 2 seconds before vanishing.
- [ ] **Performance:** Confirm steady 60 FPS on debug overlay with 6 active bubbles.

### Phase 3 — Hearing & Listener
- [ ] Launch `sandbox/sandbox_enemy.tscn`.
- [ ] **Listener Patrol:** Listener walks back and forth along floor segment, pausing 0.6 s at turn points.
- [ ] **Safe Pulse:** Emitting a Whisper pulse outside 43 px does not alter Listener patrol.
- [ ] **Alert & Investigate:** Emitting a Normal pulse within 200 px triggers alert animation, antenna ripple, and transitions Listener to INVESTIGATE toward the pulse origin.
- [ ] **Search & Return:** Upon reaching the noise point, Listener looks left and right for 4.0 s before walking back to patrol.
- [ ] **Smudge Visibility:** When the Listener is outside the illuminated bubble but investigating/alerted, it appears as a blurred dark-red smudge.

### Phase 4 — ASCII Level Pipeline
- [ ] Launch `level_root.tscn` configured with `level_01.txt`.
- [ ] Verify automated level generation: Walls greedily merged into minimal colliders/occluders, edge lines generated, player spawned at `P`.
- [ ] Catwalks correctly instantiated as one-way collision platforms.
- [ ] Listener in Level 2 properly computes paths over platforms and drops down to investigate sounds.

### Phase 5 — Enemies & Interactables
- [ ] **Doors & Keys:** Door `D` blocks player and occludes light; collecting keycard `K` and touching door causes it to slide open smoothly.
- [ ] **Pressure Plate:** Walking onto plate `_` clicks and triggers linked door `R` to open.
- [ ] **One-Way Gate:** Gate `>` allows walking through to the right, but solidly blocks walking to the left.
- [ ] **Glass Floor:** Walking or Whisper pulses leave glass intact; firing a Scream pulse shatters glass with white debris particles and a loud sound event.
- [ ] **Lanterns:** Firing a pulse near ceiling lanterns causes them to physically swing with damped harmonic oscillation and clink audibly.
- [ ] **Vents:** Emitting a sound near intake `V` causes outlet `v` to re-emit an amplified roar 0.2 s later. Standing inside mute vent `M` reduces noise radius by 70%.
- [ ] **Sentry Turret:** Sentry rotates smoothly; detects player in its cone or hears loud sounds, displays red tracking laser, and fires red lethal projectiles.
- [ ] **Hunter:** Emitting 3 consecutive pulses at different points causes the Hunter to systematically visit all 3 locations in sequence.
- [ ] **Deaf Brute:** Firing Scream pulses does not alert Brute. Running near the Brute triggers charge; sneaking allows walking past unharmed.
- [ ] **Win / Lose:** Touching enemy or projectile kills player; death triggers screen freeze (0.08 s), particle burst, and instant reload (< 1.0 s). Reaching terminal `E` triggers "SIGNAL RESTORED" sequence and advances level.

### Phase 6 — Audio & Visual Polish
- [ ] **Post-Processing:** Subtle film grain and vignette active; Scream pulse triggers chromatic aberration shockwave; enemy spotting triggers white flash frame.
- [ ] **Camera Polish:** Screen shake scales with pulse tier; Scream triggers camera zoom punch.
- [ ] **Audio Synthesis:** All SFX generated procedurally without missing sound warnings.
- [ ] **Audio Reverb:** Whisper ping has small dry room reverb; Scream ping has cavernous deep decay.
- [ ] **Adaptive Music:** Background ambient drone plays; drum/tension layers smoothly fade in as enemy awareness rises.

### Phase 7 — UI, Menus & Settings
- [ ] **HUD:** Battery bar shows real-time drain and ghost pending cost; fragment count displays top-left; progress bar updates along bottom-center.
- [ ] **Enemy Awareness:** Floating red awareness meters appear exclusively above revealed enemies.
- [ ] **Main Menu & Pause:** Main menu glitch title animation runs smoothly; Escape opens Pause overlay without crashing.
- [ ] **Settings:** Volume sliders modify bus volumes; toggling film grain or chromatic aberration immediately updates shaders; settings persist across game restarts.
- [ ] **Level Complete:** Displays completion time, pulse counts, loudest pulse, and awards Ghost/Quiet/Loud medal correctly.

### Phase 8 — Content Progression
- [ ] Play through all 8 levels consecutively.
- [ ] Verify that every level is beatable and that the Ghost medal (zero Normal/Scream pulses) is achievable on all 8 levels through sneaking and stealth routes.

---

## 5. Performance Benchmarking & Regression Protocol

### 5.1 Performance Targets
- **Target Hardware:** Integrated Graphics (Intel UHD 620 / AMD Vega 8 class).
- **Target Frame Rate:** Stable 60 FPS at 1280×720 and 1920×1080.
- **Resource Limits:**
  - Active 2D Lights on screen: `<= 7`
  - Active CPUParticles2D: `<= 300`
  - Occluder rectangles per level: `<= 150`
  - Draw calls: `<= 90`

### 5.2 Performance Degrade Test (Quality Mode LOW)
In Settings, toggle "Performance Mode" ON:
- Light shadows switch from PCF5 filtering to unfiltered / disabled.
- Film grain shader uniform set to 0.0.
- Maximum active bubble pool reduced from 6 to 4.
- Far background parallax layer disabled.
- Verify FPS increases by >= 25% on low-end test setups.
