# SIGNAL LOST — Master Quality Assurance & Verification Plan (V2)

- **Purpose**: Authoritative test plan specifying automated headless unit tests, Playwright E2E browser regression gates, telemetry hooks, definition of done, bug reporting templates, and evidence archiving rules.
- **Audience**: QA Engineers, Tooling Programmers, System Architects, AI Coding Agents.
- **Status**: Approved.
- **Last Updated**: 2026-10-12.
- **Depends On**: [00_CURRENT_STATE_AUDIT.md](file:///c:/vibe-game/docs/00_CURRENT_STATE_AUDIT.md), [PRD.md](file:///c:/vibe-game/docs/PRD.md), [TECH_STACK.md](file:///c:/vibe-game/docs/TECH_STACK.md).

---

## 1. Quality Assurance Philosophy & The Verification Rule

> **THE IRONCLAD EVIDENCE RULE**:
> *"No phase, task, or feature is complete without high-resolution PNG screenshot evidence and a clean zero-error console log archived under `/qa/shots/<phase>/`. Never report a task as finished based on assumptions; prove it with automated test execution."*

Quality assurance operates on a dual-engine harness:
1. **Headless Engine Unit Tests (`tests/run_tests.gd`)**: Executed via CLI in $< 5.0$ seconds for instant developer feedback.
2. **Browser End-to-End Tests (`tests/e2e/*.js`)**: Executed via Playwright Chromium/Edge against the live WebAssembly export on `http://127.0.0.1:8000`, testing real user inputs, rendering output, and audio-visual synchronization.

---

## 2. Automated Test Case Registry

Every test case below possesses a formal identifier, setup, execution steps, telemetry hooks, and explicit pass criteria.

### 2.1 Core Locomotion & Physics Tests

#### TC-LOCO-001: 30-Second Locomotion & Platforming Sweep (Gate A)
- **Goal**: Verify continuous uninterrupted player movement (run left/right, jump, crouch-sneak) with zero engine crashes or memory leaks.
- **Setup**: Start web build, load Level 1 via `window.__SL_cmd('load_level', {level: 1})`.
- **Steps**:
  1. Hold `D` for 3.0s (sprint right).
  2. Press `W` (jump); assert $v_y < 0$.
  3. Hold `A` for 3.0s (sprint left).
  4. Hold `Shift` + `D` for 2.0s (silent crouch-sneak); sample `window.__SL.noise_events`.
  5. Repeat sequence for 30.0s total elapsed time.
- **Hooks Needed**: `window.__SL.player.pos`, `vel`, `on_floor`, `is_sneaking`.
- **Pass Criteria**: Player traverses $\ge 800 \text{ px}$; zero console errors; `noise_events` count during sneak == 0.
- **Evidence Path**: `/qa/shots/gate_a/07_gate_a_after_30s.png`.

---

### 2.2 Sonar Echolocation & Reveal Tests

#### TC-SONAR-001: 3-Tier Sonar Charging & Wavefront Expansion (Gate B)
- **Goal**: Validate accurate charge timings, reveal radii, and noise propagation across Whisper, Normal, and Scream tiers.
- **Setup**: Load Level 2 in pitch darkness. Teleport player to `(200, 300)`.
- **Steps**:
  1. Hold `Space` for 0.20s; release (Whisper). Assert radius expands to 72 px; noise radius == 43.2 px.
  2. Hold `Space` for 0.50s; release (Normal). Assert radius expands to 200 px; noise radius == 200 px.
  3. Hold `Space` for 1.20s; release (Scream). Assert radius expands to 560 px; noise radius == 728 px; screen shake $\ge 8.0 \text{ px}$.
- **Hooks Needed**: `window.__SL.pulses`, `window.__SL.battery`, `window.__SL_cmd('spawn_pulse', {tier})`.
- **Pass Criteria**: All 3 tiers emit correct radius $\pm 2.0 \text{ px}$; battery deducts 6, 22, and 55 units respectively.
- **Evidence Path**: `/qa/shots/gate_b/whisper_02.png`, `normal_02.png`, `scream_02.png`.

---

### 2.3 Samurai Combat & Parry Tests

#### TC-COMBAT-001: Katana 3-Hit Combo & Noise Coupling
- **Goal**: Verify 3-hit slash chain, combo buffer timings, and corresponding noise emissions on `NoiseBus`.
- **Setup**: Spawn player in combat test room with dummy target at distance 24 px.
- **Steps**:
  1. Press `J` (Slash 1); assert damage == 1, noise emitted == 180 px.
  2. Press `J` at $t = 0.20s$ (Slash 2); assert damage == 1, noise emitted == 200 px.
  3. Press `J` at $t = 0.40s$ (Slash 3); assert damage == 2, poise damage == 30, noise emitted == 280 px.
- **Hooks Needed**: `window.__SL.noise_events`, `window.__SL.player.combat_state`.
- **Pass Criteria**: Dummy target takes exactly 4 segments damage total; 3 discrete noise rings logged to `NoiseBus`.
- **Evidence Path**: `/qa/shots/combat/01_katana_combo_cleave.png`.

#### TC-COMBAT-002: Frame-Tight Parry Deflect & I-Frames
- **Goal**: Assert that tapping `block_parry` within 6 frames of an incoming enemy attack negates damage, inflicts 40 poise damage, and grants 16 i-frames.
- **Setup**: Position player in front of an Ashigaru initiating Spear Thrust.
- **Steps**:
  1. Wait for Ashigaru attack startup frame 24 (3 frames before active strike).
  2. Send `InputEventAction(block_parry, pressed = true)`.
  3. Assert player health remains at 3 segments; player i-frames count == 16.
  4. Assert Ashigaru poise decreases from 40.0 to 0.0 (enters Stagger).
- **Hooks Needed**: `window.__SL.player.health_segments`, `window.__SL.enemies[0].poise`.
- **Pass Criteria**: Zero damage sustained; Ashigaru staggered; metallic deflect SFX and sparks verified.
- **Evidence Path**: `/qa/shots/combat/02_parry_deflect_sparks.png`.

---

### 2.4 Enemy AI & Perception Tests

#### TC-AI-001: Hearing Discrimination & Wall Attenuation
- **Goal**: Assert that enemies ignore safe Whispers, investigate Normal pulses, and experience 75% distance attenuation per occluding wall.
- **Setup**: Position Listener at `(500, 300)`. Position player at `(300, 300)` separated by 1 solid wall.
- **Steps**:
  1. Player emits Whisper ($r=43.2 \text{ px}$); assert Listener remains in `PATROL`.
  2. Player emits Normal pulse ($r=200 \text{ px}$); effective distance with wall is $200 \times 1.75 = 350 \text{ px} > 200 \text{ px}$; assert Listener remains in `PATROL`.
  3. Player moves into direct line-of-sight (0 walls) and emits Normal pulse; assert Listener transitions to `INVESTIGATE`.
- **Hooks Needed**: `window.__SL.enemies[0].state`, `window.__SL.enemies[0].awareness`.
- **Pass Criteria**: Listener state machine matches acoustic physics calculations with zero false positives.
- **Evidence Path**: `/qa/shots/ai/01_hearing_wall_attenuation.png`.

---

### 2.5 Campaign & Level Validation Tests

#### TC-LEVEL-001: Full Level 1 End-to-End Playthrough (Gate C)
- **Goal**: Complete full playthrough of Level 1 from spawn `P` to exit `E`, collecting fragment `F` and achieving Ghost Medal.
- **Setup**: Fresh web boot, load Level 1.
- **Steps**:
  1. Navigate player right using Whisper pulses and catwalk jumps.
  2. Collect Fragment `F`; assert antenna HUD counter updates $0 \to 1$.
  3. Walk onto Exit Terminal `E`; assert "SIGNAL RESTORED" sequence triggers.
  4. Wait 1.0s for Level Complete screen.
- **Hooks Needed**: `window.__SL.is_level_active`, `window.__SL.fragments_collected`.
- **Pass Criteria**: Victory screen displays 0 detections, 0 loud pulses, and awards Ghost Medalcrest.
- **Evidence Path**: `/qa/shots/gate_c/05_level_complete_ghost_medal.png`.

#### TC-LEVEL-002: Automated Reachability Sweep (Zero Soft-Locks)
- **Goal**: Execute `LevelValidator.validate()` across all 9 campaign maps.
- **Setup**: Headless execution: `godot --headless -s res://tests/run_tests.gd`.
- **Pass Criteria**: `test_validator.gd` reports `PASS` across Levels 1–9 with 0 reachability errors and 0 soft-locks.
- **Evidence Path**: `/qa/logs/test_validator_pass.log`.

---

### 2.6 Stability & Soak Tests

#### TC-SOAK-001: 60-Second Multi-Level Gameplay Soak
- **Goal**: Continuously cycle through levels with rapid inputs, attacks, and pulses to stress test memory, physics, and shaders.
- **Setup**: Node Playwright runner `tests/e2e/test_soak.js`.
- **Steps**:
  1. Run 60-second continuous loop alternating between Levels 1 through 5.
  2. Inject continuous movement, jumps, Katana combo slashes, and pulse emissions.
  3. Sample WebGL context status and JS heap every 5 seconds.
- **Pass Criteria**: Zero WebGL context lost errors, zero unhandled promise rejections, zero console errors across 170+ sampled ticks.
- **Evidence Path**: `/qa/shots/soak/02_soak_end.png`.

---

## 3. Definition of Done (DoD)

A task or phase is considered **DONE** if and only if all of the following conditions are met:

1. **Code Standards**: 100% typed GDScript; zero untyped variables; no file exceeds 250 lines of code; zero custom class casts in web-exposed paths.
2. **Headless Unit Pass**: `godot --headless --path . -s res://tests/run_tests.gd` outputs `ALL TESTS PASSED` with code 0.
3. **Engine Static Check**: `godot --headless --path . --quit-after 120` produces zero errors and zero warnings.
4. **Browser E2E Pass**: Corresponding Playwright test script passes with 0 browser console errors and 0 page exceptions.
5. **Evidence Logged**: High-resolution PNG screenshots and text log files are committed under `/qa/shots/<phase>/`.
6. **Changelog Updated**: Detailed bullet entry added to `CHANGELOG.md` under the active milestone.

---

## 4. Defect Tracking & Bug Report Template

When a defect is discovered during manual playtests or automated runs, it must be logged in `docs/BUGS.md` using this standard schema:

```markdown
### [BUG-ID]: Short Descriptive Title
- **Severity**: P1 (Crash/Blocker) | P2 (Gameplay Critical/Soft-Lock) | P3 (Minor Glitch/Visual)
- **Subsystem**: Combat | Sonar | AI | Level | Audio | UI | Web
- **Environment**: Godot 4.7.2 / WebAssembly (Chromium / Edge)
- **Steps to Reproduce**:
  1. Load Sector 03 via `load_level 3`.
  2. Drop through catwalk at col 24 into bottom pit.
  3. Attempt to jump back to upper floor.
- **Expected Behavior**: Hero should be able to climb return ladder to re-ascend.
- **Actual Behavior**: Jump apex is 2.7 tiles; ledge is 3 tiles tall; hero is soft-locked.
- **Root Cause**: Missing return ladder node on standable platform graph.
- **Resolution & Fix**: Added ladder return entity and re-validated map with `LevelValidator`.
- **Verification Evidence**: `/qa/shots/bugs/bug_XX_resolved.png`.
- **Status**: OPEN | IN PROGRESS | FIXED | VERIFIED
```

---

## 5. Manual Playtest Checklist (Feel & Juiciness)

Before signing off on combat or movement changes, a human designer must evaluate these 5 tactile checkpoints:

- [ ] **Jump Apex Snappiness**: Does the jump feel crisp and responsive? Does releasing `jump` early cut upward momentum instantly without floatiness?
- [ ] **Parry Satisfaction**: Does a successful deflect deliver visceral physical impact through the 0.12s hit-stop, metallic ping, and spark burst?
- [ ] **Darkness Readability**: Is the pitch-black ambient world truly pitch black (`#000000`) without grey fogging, while keeping active white edges razor-sharp?
- [ ] **Acoustic Danger Clarity**: Does emitting a Scream pulse genuinely feel like a terrifying gamble that illuminates the room while alerting every guard in the sector?
- [ ] **Audio Balance**: Are footsteps, slashes, and pulse chimes well-balanced without clipping or distortion on standard stereo headphones?
