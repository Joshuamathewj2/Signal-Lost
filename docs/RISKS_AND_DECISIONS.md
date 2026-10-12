# SIGNAL LOST — Risks Register & Architecture Decision Records (ADR)

- **Purpose**: Authoritative risk register, mitigation strategies, and formal Architecture Decision Records (ADR) governing engineering trade-offs for SIGNAL LOST V2.
- **Audience**: Technical Directors, System Architects, Producers, AI Coding Agents.
- **Status**: Approved.
- **Last Updated**: 2026-10-12.
- **Depends On**: [00_CURRENT_STATE_AUDIT.md](file:///c:/vibe-game/docs/00_CURRENT_STATE_AUDIT.md), [TECH_STACK.md](file:///c:/vibe-game/docs/TECH_STACK.md), [ARCHITECTURE.md](file:///c:/vibe-game/docs/ARCHITECTURE.md).

---

## 1. Technical & Production Risk Register

| Risk ID | Risk Description | Probability | Impact | Mitigation Strategy | Owner |
|---|---|---|---|---|---|
| **RSK-001** | **Refactor Breaking Sonar/Darkness Pipeline**: Extracting combat components might inadvertently alter `CanvasModulate`, light occluders, or radial reveal textures, causing foggy grey screens or broken shadows. | Medium | **CRITICAL** | Isolate `SonarSystem` and `flat_reveal.gdshader` behind regression gates. Every phase must pass `test_gate_b.js` before closing. | Tech Director |
| **RSK-002** | **Web Performance Degradation (Multi-Enemy + Pulses)**: Running 4+ active enemy FSMs, 2D raycasts, and full-screen distance-field air ring shaders simultaneously may drop frame rates below 60 FPS on integrated GPUs. | Medium | **HIGH** | Strict resource budgets (max 6 lights, max 150 occluder rects). Implement Quality Mode LOW (4 bubbles, no shadows, no CA) with automated verification via `test_performance_mode.gd`. | Graphics Lead |
| **RSK-003** | **Enemy Navigation Getting Stuck in Vertical Ledges**: Enemies pursuing player across vertical catwalks and drop shafts may get stuck in infinite jump-impulse loops or overshoot landings. | High | **HIGH** | Build stuck-detection heuristic into `PlatformMover` ($|\Delta \mathbf{p}| < 8 \text{ px}$ over 1.0s aborts path, hops back, and queries nearest valid graph node). Validate via `test_platform_graph.gd`. | AI Lead |
| **RSK-004** | **Combat Feel Tuning & Input Lag on Web**: Web browser event loops and frame pacing can introduce input latency, making 6-frame (100 ms) parry windows feel unresponsive or unfair. | Medium | **HIGH** | Input buffering system (`0.35s` combo buffer, `0.12s` jump buffer). Strict 60 Hz physics tick rate (`physics_ticks_per_second = 60`) decoupled from browser render v-sync. | Combat Lead |
| **RSK-005** | **Scope Creep (Arsenal & Level Bloat)**: Adding 3 weapons, 6 enemies, 9 vertical levels, and escape-room puzzles risks exceeding solo agent capacity or stalling delivery. | High | **MEDIUM** | Strict MoSCoW prioritization in `PRD.md` and feature cut-order list in `IMPLEMENTATION_PLAN.md`. Tasks partitioned to $< 250$ LOC each. | Producer |

---

## 2. Architecture Decision Records (ADR)

### ADR-001: Component-Based Combat Architecture over Monolithic Callbacks
- **Context**: V1 player and enemy scripts handled damage, health, and state transitions through hardcoded duck-typed string callbacks (`body.die(&"caught")`). Adding 3 weapons, parrying, and poise would bloat `player.gd` into an unmaintainable monolith.
- **Decision**: Adopt a modular component model (`HealthComponent`, `PoiseComponent`, `HitboxComponent`, `HurtboxComponent`, `CombatController`).
- **Consequences**:
  - *Positive*: Decoupled, reusable across hero and enemies; easily tested in headless isolation; zero circular scene dependencies.
  - *Negative*: Adds extra node instances to character scene trees (negligible memory impact).
- **Status**: **ACCEPTED**.

---

### ADR-002: In-Engine Procedural Audio Synthesis over External Asset Bundles
- **Context**: Distributing external `.wav` or `.ogg` sound files increases web build size by 20–40 MB and introduces copyright/licensing ambiguity.
- **Decision**: Synthesize 100% of sound effects and dynamic music algorithmically in-engine via `SfxLibrary` and `audio/synth.gd` on boot.
- **Consequences**:
  - *Positive*: Zero external dependencies; Web distribution payload stays under 25 MB; sound parameters map mathematically to `NoiseBus` noise physics.
  - *Negative*: Authoring complex organic sounds requires procedural DSP math; boot time incurs ~350 ms synthesis overhead.
- **Status**: **ACCEPTED**.

---

### ADR-003: Custom Directed A* Platform Graph over Built-In NavigationRegion2D
- **Context**: Godot 4's built-in `NavigationRegion2D` is optimized for top-down polygon navigation and struggles with 2D side-view platformer physics (jumps, drops, catwalk drop-throughs).
- **Decision**: Build a custom discrete directed graph using Godot's `AStar2D` class, generated directly from ASCII level grids.
- **Consequences**:
  - *Positive*: Discrete nodes with explicit motion semantics (`WALK`, `JUMP`, `DROP`); jump edges calculate exact velocity impulses; sub-millisecond search performance ($< 0.15 \text{ ms}$).
  - *Negative*: Requires custom graph building and maintenance code (`scenes/level/platform_graph.gd`).
- **Status**: **ACCEPTED**.

---

### ADR-004: Strict Tri-Color Vector Aesthetics over Pixel Art Bitmaps
- **Context**: Traditional pixel art or high-resolution hand-drawn sprites require large texture atlases and artist bandwidth, complicating procedural animation and dynamic scaling.
- **Decision**: Restrict the visual pipeline to a strict tri-color vector palette (Pure Black `#000000`, Razor White `#FFFFFF`, Blood Red `#E00000`) rendered via shaders and vector polygons.
- **Consequences**:
  - *Positive*: Striking high-contrast visual identity; instant readability across screen distances; zero bitmap texture overhead; infinitely scalable from 720p to 4K.
  - *Negative*: Requires careful silhouette and shader craftsmanship to avoid feeling sterile.
- **Status**: **ACCEPTED**.

---

### ADR-005: 3-Segment Health & Poise Stagger over Binary 1-Hit Death
- **Context**: Instant 1-hit death in V1 frustrated players during complex navigation and precluded defensive combat recovery or dueling depth.
- **Decision**: Implement a segmented health system (3 base segments) paired with a poise/stagger balance meter for both the hero and enemies.
- **Consequences**:
  - *Positive*: Forgiving enough to permit minor errors while maintaining high tension; enables rich combat mechanics (parries, guard breaks, stealth finishers).
  - *Negative*: Requires health and poise UI gauges and invulnerability frame handling.
- **Status**: **ACCEPTED**.

---

### ADR-006: Duck-Typed Web Export References over Strict Custom Class Casts
- **Context**: In Godot 4 Web export bytecode, casting nodes to custom script classes (`as Player`, `as PulseCharger`) evaluates to `null`, causing silent failures and crashes in browser builds.
- **Decision**: Prohibit custom script class casting across scene boundaries; enforce duck-typing via `is_in_group()`, `has_method()`, or property inspection.
- **Consequences**:
  - *Positive*: 100% stable execution across desktop, mobile, and WebAssembly browser targets.
  - *Negative*: Requires disciplined adherence by coding agents, as the Godot editor will not warn against typed casts at design time.
- **Status**: **ACCEPTED**.
