# QA Report — SIGNAL LOST

## Test Execution Summary

| Phase / Step | Status | Evidence Log | Evidence Screenshots |
|---|---|---|---|
| Step 0: Tooling Setup & Before State | PASS | Web build exported, served on :8000 with COOP/COEP, Playwright driver active | `qa/shots/before/01_main_menu.png`<br>`qa/shots/before/02_gameplay_start.png`<br>`qa/shots/before/03_moving_right.png`<br>`qa/shots/before/04_pulse_attempt.png` |
| Step A: Triage and Stop the Bleeding | In Progress | `qa/ERROR_LIST.md` logged | Pending Gate A verification |
| Step B: Sonar & Darkness Overhaul | Pending | - | Pending Gate B verification |
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
