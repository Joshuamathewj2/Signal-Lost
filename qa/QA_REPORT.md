# QA Report — SIGNAL LOST

## Test Execution Summary

| Phase / Step | Status | Evidence Log | Evidence Screenshots |
|---|---|---|---|
| Step 0: Tooling Setup & Before State | PASS | Web build exported, served on :8000 with COOP/COEP, Playwright driver active | `qa/shots/before/01_main_menu.png`<br>`qa/shots/before/02_gameplay_start.png`<br>`qa/shots/before/03_moving_right.png`<br>`qa/shots/before/04_pulse_attempt.png` |
| Step A: Triage and Stop the Bleeding | PASS | 30s movement completed with 0 errors (`tests/e2e/test_gate_a.js`) | `qa/shots/gate_a/01_gate_a_menu.png`<br>`qa/shots/gate_a/02_gate_a_level_start.png`<br>`qa/shots/gate_a/03_gate_a_walking_right.png`<br>`qa/shots/gate_a/04_gate_a_walking_left.png`<br>`qa/shots/gate_a/05_gate_a_jumping.png`<br>`qa/shots/gate_a/06_gate_a_crouch_sneak.png`<br>`qa/shots/gate_a/07_gate_a_after_30s.png` |
| Step B: Sonar & Darkness Overhaul | PASS | 3 pulse tiers verified at t=0.1s, 0.5s, 2.0s + Space key pulse with 0 errors (`tests/e2e/test_gate_b.js`) | `qa/shots/gate_b/whisper_01.png`<br>`qa/shots/gate_b/whisper_02.png`<br>`qa/shots/gate_b/whisper_03.png`<br>`qa/shots/gate_b/normal_01.png`<br>`qa/shots/gate_b/normal_02.png`<br>`qa/shots/gate_b/normal_03.png`<br>`qa/shots/gate_b/scream_01.png`<br>`qa/shots/gate_b/scream_02.png`<br>`qa/shots/gate_b/scream_03.png`<br>`qa/shots/gate_b/keyboard_space_pulse.png` |
| Step C: Visual Style Polish | PASS | Vector chassis, dynamic eye color state, shockwave ripples & CA burst verified with 0 errors (`tests/e2e/test_step_c.js`) | `qa/shots/step_c/01_player_vector_idle.png`<br>`qa/shots/step_c/02_player_eye_charging_cyan.png`<br>`qa/shots/step_c/03_normal_pulse_reveal.png`<br>`qa/shots/step_c/04_scream_shake_and_ca.png`<br>`qa/shots/step_c/05_interactables_revealed.png` |
| Step D: HUD and Menus Redesign | PASS | Full menu flows, scaled HUD, battery preview, awareness bar verified with 0 errors (`tests/e2e/test_step_d.js`) | `qa/shots/step_d/01_main_menu.png`<br>`qa/shots/step_d/02_level_select.png`<br>`qa/shots/step_d/03_hud_gameplay.png`<br>`qa/shots/step_d/04_battery_preview_charging.png`<br>`qa/shots/step_d/05_pause_menu.png`<br>`qa/shots/step_d/06_settings_menu.png`<br>`qa/shots/step_d/07_level_complete.png`<br>`qa/shots/step_d/08_enemy_awareness_bar.png` |
| Step E: Gameplay Dynamics & AI | Pending | - | - |
| Step F: Performance & Stability | Pending | - | - |

---

## Step 0: Initial State ("Before") Findings

1. **Main Menu**: Successfully loads and renders cleanly (`01_main_menu.png`).
2. **Gameplay Canvas**: Shows a washed out grey foggy background across the viewport (`02_gameplay_start.png`).
3. **Player Movement & Noise**: Moving triggers `event.origin` property errors due to mismatched field names in `NoiseEvent` vs `ripple_rings.gd`.
4. **Pulse Controls**: Space key was mapped to jump instead of pulse charging, and pulse rendering produced no visible light/wavefront arc.

---

## Step A: Triage and Fixes (GATE A: PASSED)

### Issues Resolved:
1. **NoiseEvent & Ripple Crash**: Standardized `NoiseEvent` properties (`position`, `radius`, `loudness`, `source_type`) with backward-compatible aliases (`origin`, `type`). Rewrote `ripple_rings.gd` with safe pre-allocated pool to prevent null-property access on movement.
2. **Foggy Grey Background**: Removed default Godot `#4d4d4d` background by setting `environment/defaults/default_clear_color=Color(0, 0, 0, 1)` in `project.godot`. Modified `shaders/post_fx.gdshader` to gate film grain by luminance so `#000000` remains pitch black.
3. **Input Mappings**: Reassigned `pulse` to Space / Left Mouse Button / K. Reassigned `jump` to W / Up Arrow / Gamepad A.
4. **Web Export & Packaging**: Configured `include_filter="*.txt"` in `export_presets.cfg` to bundle all level files (`level_01.txt` ... `level_08.txt`) into `index.pck`. Fixed Web bytecode strict type casting (`as Player`, `as LevelRoot`, `as EnemyBase`) to use robust Node2D references.
5. **Signal Connection Safety**: Guarded `battery_bar.gd` signal connections with `is_connected` to prevent duplicate connection errors on level restarts.
6. **Automated Test Infrastructure**: Implemented `DebugBridge` autoload with queue-based JS communication and end-to-end Playwright harness in `tests/e2e/test_gate_a.js`.

### Gate A Verdict:
- **Condition**: 30 seconds of continuous gameplay movement (walking left, walking right, jumping, crouching/sneaking) with 0 errors.
- **Result**: PASSED with 0 browser errors and 0 in-engine errors. Full evidence logged in `qa/shots/gate_a/`.

---

## Step B: Sonar & Darkness Overhaul (GATE B: PASSED)

### Issues Resolved:
1. **Pulse Registration & Web Bytecode Casting**: All pulse signal listeners and pool operations used strict custom class type hints (`as PulseCharger`, `PulseBubble`). In Web export bytecode, custom class casts evaluate to `null`, completely preventing pulses from being fired or registered in `PulseRegistry`. Removed strict class casts in favor of duck-typed references across `sonar_system.gd`, `charge_rings.gd`, `camera_rig.gd`, `post_fx.gd`, and `hud.gd`.
2. **Player Lifecycle Stale Node Connection**: In `level_root.gd`, `SonarSystem._connect_player()` queried `get_tree().get_first_node_in_group(&"player")` immediately upon level reload, which returned the stale queue-freed player rather than the newly spawned instance. Added `connect_player(p_node)` and passed the freshly spawned player reference directly from `EntitySpawner`.
3. **Radial Reveal Texture Falloff**: In `reveal_texture_factory.gd`, pixels were generated with `Color(1.0, 1.0, 1.0, v)` which kept RGB at 1.0 everywhere in the quad. Fixed texture generation to `Color(v, v, v, v)` ensuring proper radial attenuation in both RGB and Alpha channels for the GL Compatibility renderer.
4. **Solid Geometry Illumination**: In `level_builder.gd`, polygon color was set to `Color.BLACK` under `flat_reveal.gdshader`, preventing them from reflecting light. Updated polygon base to `Color.WHITE` with blueprint tint `Color(0.12, 0.14, 0.18, 1.0)` so solids brightly illuminate within light cones and remain pure pitch-black in shadow.
5. **3-Tier Profiles & Wavefront Propagation**: Calibrated Whisper ($r=150$px, $t=1.5$s), Normal ($r=350$px, $t=3.0$s), and Scream ($r=700$px, $t=5.0$s). Verified concentric distance-field arcs and trailing ripples in `shaders/sonar_air.gdshader`.

### Gate B Evidence Matrix:

| Pulse Tier | t = 0.1s (Expanding Arc) | t = 0.5s (Full Illumination & Shadows) | t = 2.0s (Fade / Decay) |
|---|---|---|---|
| **Whisper** ($r=150$px) | `qa/shots/gate_b/whisper_01.png` | `qa/shots/gate_b/whisper_02.png` | `qa/shots/gate_b/whisper_03.png` |
| **Normal** ($r=350$px) | `qa/shots/gate_b/normal_01.png` | `qa/shots/gate_b/normal_02.png` | `qa/shots/gate_b/normal_03.png` |
| **Scream** ($r=700$px) | `qa/shots/gate_b/scream_01.png` | `qa/shots/gate_b/scream_02.png` | `qa/shots/gate_b/scream_03.png` |
| **Spacebar (Native Input)** | - | `qa/shots/gate_b/keyboard_space_pulse.png` | - |

### Gate B Verdict:
- **Condition**: All 3 tiers tested across 3 timestamps + native keyboard Space charging and release. Wavefront rings visible, occlusion shadows cast behind solid walls, fading memory persistence, 0 browser errors, 0 engine errors.
- **Result**: PASSED with 0 browser errors and 0 in-engine errors. Full visual evidence captured in `qa/shots/gate_b/`.

---

## Step C: Visual Style Polish (PASSED)

### Issues Resolved:
1. **Player Vector Chassis & Dynamic Eye Dot**: Updated player rendering with clean vector silhouette and dynamic single eye dot. The eye dot transitions dynamically: white (neutral/idle), cyan (charging pulse), and red (detected/alert).
2. **Post-Processing Shockwave & Chromatic Aberration**: Verified shockwave ring ripples and CA burst on Scream pulses.
3. **Automated Verification**: Verified with `tests/e2e/test_step_c.js` with 0 browser errors and 0 engine errors. Screenshots saved in `qa/shots/step_c/`.

---

## Step D: HUD and Menus Redesign (PASSED)

### Issues Resolved:
1. **HUD Redesign**: Scaled up antenna fragment counter (28px Rajdhani font), 220x14px battery bar with solid red fill and pale charge cost preview overlay, ability slots with key badges (`F`, `G`), diamond charge pips, and minimalist level progress bar (260x3px).
2. **Main Menu**: High-contrast minimalist aesthetic with sonar wipe circle revealing "SIGNAL LOST" typography, white outlined buttons with red hover/focus styling.
3. **Mission Select**: 4x2 Mission Select grid with locked/unlocked states and keyboard navigation.
4. **Pause Menu Persistence**: Preserved `PauseMenu` during level transitions and verified overlay pause flow.
5. **Settings Menu**: Calibrated volume sliders, screen shake, film grain, CA, and colorblind toggles with Rajdhani font.
6. **Level Complete Screen**: "SIGNAL RESTORED" title, stats grid (Time, Pulses, Loudest, Detected, Fragments), GHOST medal with sonar wipe reveal.
7. **Awareness Bar**: Fixed positioning (-46px above enemy head/antenna), unshaded canvas material, and reveal visibility.
8. **Automated Verification**: Ran `tests/e2e/test_step_d.js` across menu navigation, pause menu, battery preview, level complete, and enemy awareness bar. PASSED with 0 browser errors and 0 engine errors. Screenshots saved in `qa/shots/step_d/`.


