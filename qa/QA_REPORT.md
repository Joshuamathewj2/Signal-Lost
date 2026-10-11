# QA Report — SIGNAL LOST

## Test Execution Summary

| Phase / Step | Status | Evidence Log | Evidence Screenshots |
|---|---|---|---|
| Step 0: Tooling Setup & Before State | PASS | Web build exported, served on :8000 with COOP/COEP, Playwright driver active | `qa/shots/before/01_main_menu.png`<br>`qa/shots/before/02_gameplay_start.png`<br>`qa/shots/before/03_moving_right.png`<br>`qa/shots/before/04_pulse_attempt.png` |
| Step A: Triage and Stop the Bleeding | PASS | 30s movement completed with 0 errors (`tests/e2e/test_gate_a.js`) | `qa/shots/gate_a/01_gate_a_menu.png`<br>`qa/shots/gate_a/02_gate_a_level_start.png`<br>`qa/shots/gate_a/03_gate_a_walking_right.png`<br>`qa/shots/gate_a/04_gate_a_walking_left.png`<br>`qa/shots/gate_a/05_gate_a_jumping.png`<br>`qa/shots/gate_a/06_gate_a_crouch_sneak.png`<br>`qa/shots/gate_a/07_gate_a_after_30s.png` |
| Step B: Sonar & Darkness Overhaul | In Progress | - | Pending Gate B verification |
| Step C: Visual Style Polish | Pending | - | - |
| Step D: HUD and Menus Redesign | Pending | - | - |
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
