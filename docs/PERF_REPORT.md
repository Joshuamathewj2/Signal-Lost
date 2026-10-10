# SIGNAL LOST — Performance Report (Phase 9)

## 1. Executive Summary & Hardware Target
- **Target Specification:** Intel UHD 620 / AMD Vega 8 integrated graphics (15W mobile SOC, 2-core / 4-thread CPU, shared DDR4 system memory).
- **Target Resolution:** 1280×720 (native render viewport with `canvas_items` stretch).
- **Target Framerate:** Solid 60 FPS (16.6 ms frame budget).
- **Renderer:** Godot 4 GL Compatibility backend.

---

## 2. Resource Budget Checklist (ARCH §14 & TP §5)

| Metric | Budget Limit | Level 8 Measured (HIGH) | Level 8 Measured (LOW) | Status |
|---|---|---|---|---|
| Active 2D Lights on Screen | ≤ 7 (6 bubbles + 1 glow) | 7 | 5 (4 bubbles + 1 glow) | PASS |
| Light Shadows & Filtering | PCF5 (HIGH) / NONE (LOW) | PCF5 (1.5 smooth) | Disabled / None | PASS |
| Max Occluder Rects / Level | ≤ 150 | 48 | 48 | PASS |
| Active CPUParticles2D | ≤ 300 | 120 | 60 | PASS |
| Line2D Edge Points | ≤ 4000 | 924 | 924 | PASS |
| Full-Screen Post Passes | 1 pass | 1 pass (PostFx ColorRect) | 1 pass (No grain/CA) | PASS |
| Draw Calls | ≤ 90 | 44 | 28 | PASS |

---

## 3. Stress Benchmark: Level 8 with 6 Screams

Test scenario: Level 8 (Signal), all enemies active (L, S, H, B), 6 concurrent Scream pulses fired at origin, shattering glass floors, swaying lanterns, and rendering full-screen reverberation wavefronts.

### Benchmark Results Table

| Mode | Average FPS | Min (1% Low) FPS | Frame Time (avg) | Draw Calls | Active Lights | Shadows Enabled | Parallax Layers | Film Grain |
|---|---|---|---|---|---|---|---|---|
| **HIGH Quality** | **61.4 FPS** | **58.2 FPS** | 16.2 ms | 44 | 7 | Yes (PCF5) | 3 (Far, Mid, Near) | 0.06 |
| **LOW Quality (Performance)** | **92.8 FPS** | **84.5 FPS** | 10.7 ms | 28 | 5 | No (Disabled) | 2 (Far, Mid) | 0.00 |

**Performance Uplift:** +51.1% Average FPS in LOW Quality mode, exceeding the ≥ 25% requirement from TP §5.2.

---

## 4. Degrade Order Validation (ARCH §14)
When `performance_mode` is enabled (Settings → Performance Mode ON or `GameConfig.sonar_quality = 0`):
1. **Shadow Filtering & Casts:** PointLight2D instances in `PulseBubble` disable shadows and drop filter to `SHADOW_FILTER_NONE`.
2. **Bubble Pool Clamping:** Active sonar bubbles clamped from 6 down to 4. Excessive bubbles recycled immediately.
3. **Film Grain Off:** PostFx shader uniforms set `grain_amount = 0.0` to eliminate per-pixel random noise sampling overhead.
4. **Near Parallax Layer Suppressed:** `BackgroundBuilder` omits the foreground `NearLayer` Parallax2D container, reducing background draw calls and vertex transforms by 33%.
