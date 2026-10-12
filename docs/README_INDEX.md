# SIGNAL LOST — Master Documentation Index & Glossary

- **Purpose**: Central roadmap, reading order, document directory, and architectural glossary for the SIGNAL LOST V2 documentation suite.
- **Audience**: Game Designers, Technical Directors, AI Coding Agents (Gemini, Claude Sonnet/Opus).
- **Status**: Approved.
- **Last Updated**: 2026-10-11.
- **Depends On**: [00_CURRENT_STATE_AUDIT.md](file:///c:/vibe-game/docs/00_CURRENT_STATE_AUDIT.md).

---

## 1. Documentation Map & Recommended Reading Order

The documentation suite is structured into four reading tiers based on role and task requirements:

```
                  ┌───────────────────────────────┐
                  │ 1. STRATEGIC FOUNDATIONS      │
                  │ README_INDEX -> GDD -> PRD    │
                  └───────────────┬───────────────┘
                                  ▼
                  ┌───────────────────────────────┐
                  │ 2. TECHNICAL ARCHITECTURE     │
                  │ TECH_STACK -> ARCHITECTURE    │
                  │ -> GAME_CONFIG_REFERENCE      │
                  └───────────────┬───────────────┘
                                  ▼
                  ┌───────────────────────────────┐
                  │ 3. SUBSYSTEM SPECIFICATIONS   │
                  │ COMBAT_DESIGN -> ENEMY_AI     │
                  │ -> LEVEL_DESIGN -> PUZZLES    │
                  │ -> ART / ANIM / AUDIO / UI    │
                  └───────────────┬───────────────┘
                                  ▼
                  ┌───────────────────────────────┐
                  │ 4. EXECUTION & VERIFICATION   │
                  │ QA_TEST_PLAN -> AGENT_RULES   │
                  │ -> IMPLEMENTATION_PLAN        │
                  │ -> PHASE PROMPTS (0-9)        │
                  └───────────────────────────────┘
```

### 1.1 Complete Document Registry

| Document | Primary File Link | One-Line Summary |
|---|---|---|
| **Audit** | [00_CURRENT_STATE_AUDIT.md](file:///c:/vibe-game/docs/00_CURRENT_STATE_AUDIT.md) | Verified audit of current Godot 4 codebase, line counts, systems, and technical debt. |
| **Index** | [README_INDEX.md](file:///c:/vibe-game/docs/README_INDEX.md) | Master directory, reading pathways, and universal glossary of mechanics and terms. |
| **GDD** | [GDD.md](file:///c:/vibe-game/docs/GDD.md) | High-level creative vision, pillars, player fantasy, core game loop, and combat/sonar interplay. |
| **PRD** | [PRD.md](file:///c:/vibe-game/docs/PRD.md) | Product scope (MUST/SHOULD/COULD/WON'T), functional requirements (FR-*), and traceability matrix. |
| **Tech Stack** | [TECH_STACK.md](file:///c:/vibe-game/docs/TECH_STACK.md) | Engine (Godot 4.7.2 / 4.4+), GL Compatibility renderer, typed GDScript, and tooling architecture. |
| **Architecture** | [ARCHITECTURE.md](file:///c:/vibe-game/docs/ARCHITECTURE.md) | Component-based modular target architecture, scene hierarchy, autoloads, and migration plan. |
| **Config** | [GAME_CONFIG_REFERENCE.md](file:///c:/vibe-game/docs/GAME_CONFIG_REFERENCE.md) | Exhaustive reference table of every gameplay tunable, default value, unit, and system origin. |
| **Inputs** | [INPUT_MAP.md](file:///c:/vibe-game/docs/INPUT_MAP.md) | Universal mapping across keyboard, mouse, and gamepad with conflict-resolution matrix. |
| **Combat Design** | [COMBAT_DESIGN.md](file:///c:/vibe-game/docs/COMBAT_DESIGN.md) | Samurai combat system: weapons, parry/guard windows, stealth assassinations, and noise costs. |
| **Frame Data** | [COMBAT_FRAME_DATA.md](file:///c:/vibe-game/docs/COMBAT_FRAME_DATA.md) | Frame-by-frame breakdown of startup, active, and recovery timings across all weapons. |
| **Enemy AI** | [ENEMY_AI.md](file:///c:/vibe-game/docs/ENEMY_AI.md) | FSM specifications, perception cones, acoustic memory, navigation, and Shogun Mech boss. |
| **Level Design** | [LEVEL_DESIGN_V2.md](file:///c:/vibe-game/docs/LEVEL_DESIGN_V2.md) | Layout rules, validator specs, and detailed walkthroughs/ASCII maps for Levels 1–9. |
| **Puzzles** | [PUZZLES.md](file:///c:/vibe-game/docs/PUZZLES.md) | Escape-room puzzle toolbox: echo glyphs, resonance panels, seal locks, and lore fragments. |
| **Art Direction** | [ART_DIRECTION.md](file:///c:/vibe-game/docs/ART_DIRECTION.md) | Strict black/white/red aesthetic, silhouette style sheets, VFX guidelines, and visual gap analysis. |
| **Animation** | [ANIMATION_SPEC.md](file:///c:/vibe-game/docs/ANIMATION_SPEC.md) | Frame timings, procedural tween rules, event triggers, and Animation Gallery debug scene. |
| **Audio Spec** | [AUDIO_SPEC.md](file:///c:/vibe-game/docs/AUDIO_SPEC.md) | Procedural synth parameters, dynamic combat music layering, and sound-to-noise coupling. |
| **Credits** | [CREDITS.md](file:///c:/vibe-game/docs/CREDITS.md) | Attribution registry, open-source engine licenses (MIT, SIL OFL 1.1), and project credits. |
| **UI / UX** | [UI_UX_SPEC.md](file:///c:/vibe-game/docs/UI_UX_SPEC.md) | In-game HUD, segmented health, awareness reticles, menus, and accessibility design. |
| **QA Test Plan** | [QA_TEST_PLAN.md](file:///c:/vibe-game/docs/QA_TEST_PLAN.md) | Automated unit tests, Playwright E2E browser tests, regression gates, and bug templates. |
| **Roadmap** | [IMPLEMENTATION_PLAN.md](file:///c:/vibe-game/docs/IMPLEMENTATION_PLAN.md) | Phased delivery schedule (Phase 0–9), session-sized tasks (<250 LOC), and model guidance. |
| **Decisions** | [RISKS_AND_DECISIONS.md](file:///c:/vibe-game/docs/RISKS_AND_DECISIONS.md) | Technical risk register, mitigation strategies, and formal Architecture Decision Records (ADR). |
| **Task Checklist**| [TASKS.md](file:///c:/vibe-game/docs/TASKS.md) | Granular production checklist of all tasks with completion checkboxes and ownership. |
| **Agent Rules** | [AGENT_RULES.md](file:///c:/vibe-game/docs/AGENT_RULES.md) | Strict behavioral protocols, coding standards, safety rules, and commit policies for AI agents. |
| **Prompts** | [docs/prompts/](file:///c:/vibe-game/docs/prompts/) | Ready-to-paste implementation prompts for each development phase (`PHASE_0.md` to `PHASE_9.md`). |

---

## 2. Glossary of Mechanics & Terminology

To bridge the gap between creative game design concepts and technical execution, all specialized terms are defined here:

### 2.1 Combat & Kinetic Terms
- **Poise**: An internal stability meter possessed by the hero and enemies. When an entity takes poise damage exceeding their threshold, their active action is interrupted and they enter a vulnerable **Stagger** state.
- **I-Frames (Invulnerability Frames)**: Distinct animation frames during which the entity cannot take damage or be affected by hostile hitboxes (e.g., during the active roll of a Dash or during a successful Parry).
- **Telegraph**: The visual and acoustic warning window prior to an attack becoming active (e.g., a flashing red gleam, blade glint, or high-pitched weapon drawing sound). Gives the player time to react.
- **Hit-Stop (Micro-Freeze)**: A momentary freeze of character animations and physics (typically 0.05s to 0.12s) applied upon a successful weapon strike. Creates visceral tactile impact and game feel.
- **Attack Token**: A concurrency concurrency management system used by the AI coordinator (`AttackTokenManager`). Limits the number of enemies that can actively attack the player simultaneously (maximum 2 tokens), preventing unfair gang-tackles.
- **Guard Break**: An event triggered when an entity blocks an attack while possessing zero stamina/poise, forcing a lengthy stagger animation and exposing them to a lethal finisher.
- **Stealth Assassination (Finisher)**: A high-damage, single-hit takedown executable only from behind an unaware enemy (awareness < 0.35) while hidden in darkness.

### 2.2 Acoustic & Sonar Terms
- **Acoustic Wavefront**: The physical expanding ring of sound emitted by a sonar pulse, moving through world coordinates at a fixed computational velocity ($c = 700 \text{ px/s}$).
- **Reveal Radius**: The maximum visual distance illuminated by a pulse. World geometry and entities within this radius become visible to the player.
- **Noise Radius**: The spatial distance over which an acoustic event can be registered by enemy hearing sensors. For Whisper, noise radius is smaller than reveal radius; for Scream, noise radius is larger than reveal radius.
- **Acoustic Attenuation**: The reduction of sound intensity caused by distance and physical barriers. Each solid wall between sound source and listener adds an effective distance penalty ($+75\%$).
- **Echo Memory**: A lingering visual afterimage of world geometry and entities that persists at 12% opacity for 2.0s after a sonar bubble fades, allowing mental mapping without continuous noise emission.

### 2.3 Puzzle & Environmental Terms
- **Echo Glyph**: A hidden architectural rune or symbol carved into walls that is invisible to ordinary vision and only glows when hit by a specific sonar tier (e.g., Whisper reveals blue glyph, Scream reveals red glyph).
- **Resonance Panel**: An acoustic puzzle trigger tuned to a specific sound frequency. Emitting the correct pulse tier nearby vibrates the panel, opening locked blast gates or activating lifts.
- **Seal Lock**: A mechanical barrier locked by multiple cryptographic nodes. Requires either matching key items or striking connected sequence lanterns in correct order within a time limit.
- **Exit Hint Beacon**: An emergency acoustic homing beacon triggered by pressing `H`. Emits a faint directional sound ripple towards the exit terminal at the cost of modest local noise.
