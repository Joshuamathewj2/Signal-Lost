# SIGNAL LOST — Technical Stack & Engineering Architecture (V2)

- **Purpose**: Authoritative specification of the game engine, compiler runtime, language rules, render pipelines, export targets, test automation harnesses, and architectural decisions for SIGNAL LOST V2.
- **Audience**: Technical Directors, Engine Programmers, Tooling Engineers, AI Coding Agents.
- **Status**: Approved.
- **Last Updated**: 2026-10-11.
- **Depends On**: [00_CURRENT_STATE_AUDIT.md](file:///c:/vibe-game/docs/00_CURRENT_STATE_AUDIT.md), [PRD.md](file:///c:/vibe-game/docs/PRD.md).

---

## 1. Engine, Runtime & Language Specifications

### 1.1 Engine & Renderer
- **Engine Version**: **Godot Engine 4.7.2-stable (official build ed1daf0bf)**. (Compatible with all Godot 4.4+ series standard features).
- **Primary Renderer**: **GL Compatibility (`gl_compatibility`)**.
  - Enforced in `project.godot`: `rendering/renderer/rendering_method="gl_compatibility"` and `.mobile="gl_compatibility"`.
  - **Justification**: Compatibility mode targets OpenGL 3.3 / OpenGL ES 3.0 / WebGL 2.0. It runs identically across high-end desktop hardware, low-power integrated laptops (Intel UHD 620 baseline), and browser WebAssembly sandboxes without Vulkan driver prerequisites.
- **Viewport & Window Scaling**:
  - Base Viewport Resolution: **1920 × 1080**.
  - Stretch Mode: `canvas_items`.
  - Stretch Aspect: `expand`.
  - Default Clear Color: `Color(0.0, 0.0, 0.0, 1.0)` (Pure Pitch Black).

### 1.2 Programming Language: Typed GDScript
- **Standard**: 100% strictly typed GDScript 2.0.
- **Syntax Constraints**:
  - Every variable declaration must carry an explicit static type hint (`var velocity: Vector2 = Vector2.ZERO`).
  - Every function parameter and return type must be explicitly typed (`func take_damage(amount: int) -> bool:`).
  - Use `StringName` (`&"player"`, `&"whisper"`) for dictionary keys, group queries, and signal identifiers to avoid heap allocations.
- **Web Export Casting Safety Rule**:
  - In Godot 4 WebAssembly export bytecode, custom script class casts (e.g., `body as Player` or `node as PulseCharger`) evaluate to `null` due to cross-script class registry stripping in web release templates.
  - **MANDATORY CODING RULE**: Use duck-typing with method/property checks or group verification rather than direct custom class casts:
    ```gdscript
    # FORBIDDEN (Crashes or evaluates to null on Web export):
    var player := body as Player
    player.die(&"caught")

    # MANDATORY (Safe across Desktop and Web):
    if body.is_in_group(&"player") and body.has_method("die"):
        body.die(&"caught")
    ```

---

## 2. Platform Export Targets & Build Pipeline

1. **Web (HTML5 / WebAssembly / WebGL 2.0)**:
   - Primary distribution and CI test target.
   - Built to `build/web/index.html` via `export_presets.cfg` ("Web" preset).
   - Bundles all ASCII levels into `index.pck` via `include_filter="*.txt"`.
   - Requires HTTP Cross-Origin Isolation headers (`Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp`) for `SharedArrayBuffer` threading support. Provided locally by `tools/serve.js` / `tools/serve.py`.
2. **Windows Desktop (x86_64 Standalone)**:
   - Export preset: "Windows Desktop" -> `export/SignalLost.exe`.
3. **Linux / X11 (x86_64 Standalone)**:
   - Export preset: "Linux/X11" -> `export/SignalLost.x86_64`.

---

## 3. Test Automation & Tooling Infrastructure

SIGNAL LOST employs a multi-tier automated test harness allowing zero-friction verification for human developers and autonomous AI agents:

```
  ┌─────────────────────────────────────────────────────────────────┐
  │ 1. HEADLESS UNIT TESTS (Godot SceneTree Harness)               │
  │ godot --headless --path . -s res://tests/run_tests.gd           │
  │ • Executes 17+ isolated suites in < 5.0 seconds                 │
  └────────────────────────────────┬────────────────────────────────┘
                                   │
                                   ▼
  ┌─────────────────────────────────────────────────────────────────┐
  │ 2. E2E BROWSER AUTOMATION (Playwright / Puppeteer MCP)          │
  │ node tests/e2e/test_gate_*.js                                   │
  │ • Spins up Chromium/Edge against http://127.0.0.1:8000          │
  │ • Interacts with canvas, keyboard events, and window.__SL hooks │
  └────────────────────────────────┬────────────────────────────────┘
                                   │
                                   ▼
  ┌─────────────────────────────────────────────────────────────────┐
  │ 3. LIVE DEBUG BRIDGE (autoload/debug_bridge.gd)                │
  │ • window.__SL: Real-time telemetry snapshot JSON                │
  │ • window.__SL_cmd(name, args): Command dispatcher              │
  └─────────────────────────────────────────────────────────────────┘
```

### 3.1 Live Telemetry Contract (`window.__SL`)
The `DebugBridge` autoload serializes a clean snapshot to `window.__SL` every frame:
```json
{
  "ready": true,
  "fps": 60.0,
  "level": 1,
  "battery": 100.0,
  "player": {
    "pos": [320.0, 540.0],
    "vel": [0.0, 0.0],
    "on_floor": true,
    "is_alive": true,
    "health_segments": 3,
    "facing": 1
  },
  "pulses": [
    { "origin": [320.0, 540.0], "radius": 200.0, "age": 0.45, "brightness": 0.85 }
  ],
  "noise_events": [],
  "enemies": [
    { "name": "Ashigaru_1", "kind": "ashigaru", "pos": [580.0, 540.0], "awareness": 0.0, "state": "PATROL" }
  ]
}
```

---

## 4. Audio Architecture: Procedural Synthesis vs External Assets

- **Selected Approach**: **100% Procedural Synthesis in-engine via `SfxLibrary` and `audio/synth.gd`**.
- **Justification**:
  1. **Zero External Asset Overhead**: Eliminates binary `.wav`/`.ogg` assets, reducing web export package size by over 80%.
  2. **Deterministic Waveform Generation**: Audio buffers are rendered deterministically into `AudioStreamWAV` buffers in under 350 ms on application boot.
  3. **Direct Sound-to-Noise Coupling**: Because sounds are generated algorithmically, acoustic properties (envelope length, frequency spectrum, volume) map directly and mathematically to `NoiseEvent` properties on `NoiseBus`.
  4. **Strict Licensing Independence**: Completely immune to copyright strikes or attribution ambiguity; 100% of audio code is original project intellectual property.
- **Optional CC0 Ambient Texture Layer**: If ambient room hums or complex taiko percussion require pre-baked textures, they must strictly originate from CC0 public domain sources, credited in `CREDITS.md`, and compressed to Ogg Vorbis at $\le 96 \text{ kbps}$.

---

## 5. Navigation Architecture Decision: Platform Graph vs NavigationRegion2D

### 5.1 Options Evaluated
1. **Option A: Godot 4 `NavigationRegion2D` with Navigation Links**:
   - *Pros*: Built-in engine feature; polygonal navmesh generation.
   - *Cons*: Inherently designed for top-down 2D pathfinding. Vertical platforming requires hundreds of manually placed two-way `NavigationLink2D` nodes for every jump and drop ledge. Cannot reliably simulate variable jump heights, drop-through catwalks, or mid-air steering. Prone to edge-clumping bugs on vertical geometry.
2. **Option B (RECOMMENDED & ADOPTED): Custom Directed A* Platform Graph (`PlatformGraph`)**:
   - *Pros*:
     - Discrete graph generated directly from ASCII level grids ($V \le 600$ standable nodes).
     - Edges carry explicit physical semantics: `EdgeType.WALK`, `EdgeType.JUMP` (with calculated impulse velocity), `EdgeType.DROP` (with horizontal clearance), and `EdgeType.LIFT`.
     - Sub-millisecond search performance ($< 0.15 \text{ ms}$ on `AStar2D`).
     - Directly integrates with enemy state machines: if a path requires a jump, `PlatformMover` knows the exact velocity vector to apply.
     - Includes built-in stuck-detection heuristics and fallback re-pathing.
   - *Cons*: Requires maintaining custom graph building code (`scenes/level/platform_graph.gd`).
- **Verdict**: **Custom Directed A* Platform Graph is the selected standard**.

---

## 6. Coding Standards & Agent Constraints (V2 Section 13 Rules)

To ensure that both human developers and autonomous AI agents write safe, robust, and maintainable code:

1. **Single Responsibility Files**: Keep every script focused. Never exceed **250 lines of code** per file. If a file grows beyond 250 lines, factor out logic into a dedicated component.
2. **Strict Static Typing**: Every function argument, return value, and class variable must have a static type annotation. Untyped `var x = 10` is strictly forbidden; write `var x: int = 10`.
3. **Duck-Typed Web Safety**: When interacting with external nodes across scenes, use `is_in_group()`, `has_method()`, or duck-typed property checks. Never use strict custom class casts (`as MyClass`) in game logic.
4. **Zero Circular Dependencies**: Scenes and components must communicate upwards via **Signals** and downwards via **Function Calls**. Autoloads must never hold strong references to transient level nodes.
5. **No Hardcoded Constants**: Gameplay parameters must reside in `res://resources/config/` or `default_config.tres`. Never bury raw magic numbers in state scripts.
6. **Regression Gate Enforcement**: Before closing any development session or phase, both the headless unit suite (`godot --headless -s res://tests/run_tests.gd`) and the static syntax check (`--quit-after 120`) must pass with **0 errors**.

---

## 7. Performance Budget & Resource Allocations

To guarantee 60 FPS on integrated graphics hardware:

| Resource / System | Maximum Budget | Fallback Degradation Behavior |
|---|---|---|
| **Active Point Lights (Sonar Bubbles)** | 6 bubbles + 1 hero glow = 7 lights | Drop to 4 bubbles on Low Quality mode. |
| **Active Occluder Polygons** | $\le 150$ merged rectangles per level | Merged by `SolidMerger` during build. |
| **Concurrent Active Enemies** | $\le 12$ enemies per level | Inactive enemies sleep physics beyond 800 px. |
| **Simultaneous CPUParticles2D** | $\le 400$ active particles | Compatibility-safe CPU particles only; no GPU compute. |
| **Line2D Edge Points** | $\le 4,000$ points total | Simplified edge subdivision on Low Quality. |
| **Shader Texture Lookups** | 1 full-screen post-processing pass | Disable film grain and chromatic aberration on Low Quality. |

---

## 8. Technology Decisions Log

| Decision Area | Options Considered | Selected Choice | Technical Rationale |
|---|---|---|---|
| **Game Engine** | Godot 4 vs Unity 2D vs Monogame | **Godot Engine 4.7.2** | Lightweight, open-source (MIT), instant cold boot, headless CI support, native typed GDScript. |
| **Rendering Backend** | Forward+ vs Mobile vs Compatibility | **GL Compatibility** | Guaranteed cross-platform stability; zero WebAssembly/WebGL driver failures; instant export. |
| **Physics Simulation** | RigidBody2D vs CharacterBody2D | **CharacterBody2D** | Full kinematic control over coyote time, variable jump cut, and zero physics jitter. |
| **Pathfinding** | NavigationRegion2D vs Custom A* | **Custom Directed A*** | Accurate 2D platforming semantics (jumps, drops, catwalks); sub-millisecond evaluation. |
| **Audio Pipeline** | Audio Files (.wav/.ogg) vs In-Engine Synth | **Procedural In-Engine Synth** | Zero external assets, deterministic coupling to noise physics, sub-25MB web payload. |
| **Test Automation** | Manual Testing vs Playwright E2E | **Playwright MCP + __SL** | Autonomous AI agent verification; repeatable regression gates; headless browser testing. |
