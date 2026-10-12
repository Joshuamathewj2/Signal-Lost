# SIGNAL LOST — Art Direction & Visual Aesthetics Specification (V2)

- **Purpose**: Authoritative visual design specification establishing palette rules, silhouette model sheets, scarf physics, environment prop lists, lighting standards, VFX guidelines, and the Current vs Target visual gap analysis.
- **Audience**: Technical Artists, 2D Animators, Visual Designers, AI Coding Agents.
- **Status**: Approved.
- **Last Updated**: 2026-10-12.
- **Depends On**: [00_CURRENT_STATE_AUDIT.md](file:///c:/vibe-game/docs/00_CURRENT_STATE_AUDIT.md), [GDD.md](file:///c:/vibe-game/docs/GDD.md).

---

## 1. Visual Gap Analysis: Current vs Target

Based on direct examination of the V1 baseline state (`reference_current.png`) and the V2 target production look (`reference_expected.png`):

| Visual Aspect | Current Game (V1 Baseline) | Target Look (V2 Direction) | Concrete Engineering Gap & Solution |
|---|---|---|---|
| **Character Scale** | Tiny boxy robot (14×18 px collision, ~24 px visual height). Lost on screen. | Large, heroic white samurai silhouette (54 px height at 1920×1080) with readable katana and scarf. | Scale player character 2.25× up. Redraw with articulated polygonal limbs, scabbard, and flowing scarf. |
| **Enemy Shapes** | Generic red rectangular blobs and simple boxes. Indistinguishable silhouettes. | Distinct feudal-cybernetic silhouettes: Ashigaru (spear), Kenshi (sword), Yumi (hooded archer), Brute (kanabo club). | Build custom vector silhouettes with signature weapon stances and identifiable headpieces (jingasa, hood, spikes). |
| **Camera & Framing** | Small level floating inside an immense, empty black window void with 2.0x static zoom. | Dynamic camera (1.8x base, 1.45x combat) filling 100% of the screen with multi-story vertical architecture. | Add dynamic look-ahead (48 px) and dynamic combat zoom; remove dead space; fit 2–3 vertical tiers. |
| **Environmental Backdrop** | Pitch black void with 1–2 flat floating geometric lines. No sense of architectural space. | Layered atmospheric background silhouettes (translucent shoji screens, industrial gantries, massive stone pillars). | Implement 3-plane Parallax2D system (z −10, −20, −30) with feudal-industrial vector prop generators. |
| **Platform Edges** | Thin, broken, disconnected lines with aliasing. | Crisp, jagged white "torn-paper" platform top edges with subtle top specks and soft edge falloff. | Enhance `edge_line.gdshader` and `edge_builder.gd` with procedural Perlin noise displacement (2.5 px width). |
| **HUD & Interfaces** | Minimalist corner battery line and basic tool box (`[F]`, `[G]`). Tiny text. | Rich samurai HUD: katana/weapon badge, 3-segment health bar, shuriken pips, top-left fragment counter, level progress bar. | Overhaul `hud.tscn` to match target reference layout; style with crisp Rajdhani-SemiBold typography. |
| **Acoustic Wavefronts** | Basic single expanding white ring. | Sharp concentric distance-field sonar rings; incoming arrows render as bright red vector lines inside white rings. | Update `sonar_air.gdshader` to draw secondary harmonic ripple rings; projectile shaders render in high-contrast red. |

---

## 2. Palette Rules: The Tri-Color Discipline

SIGNAL LOST enforces an uncompromising tri-color visual aesthetic:

```
  ┌─────────────────────────────────────────────────────────────────┐
  │ 1. PURE BLACK (#000000)                                         │
  │ • Ambient world darkness, unrevealed voids, solid geometry interiors │
  ├─────────────────────────────────────────────────────────────────┤
  │ 2. RAZOR WHITE (#FFFFFF)                                        │
  │ • Player samurai silhouette, platform top edges, sonar arcs, UI │
  ├─────────────────────────────────────────────────────────────────┤
  │ 3. BLOOD RED (#E00000)                                          │
  │ • Enemy silhouettes, incoming projectiles, hazard spikes, alerts│
  └─────────────────────────────────────────────────────────────────┘
```

- **Secondary Depth Tones (Shading only)**:
  - Far Parallax Silhouettes: `#1A1A1A` (10% luminance).
  - Mid Parallax Silhouettes: `#2B2B2B` (17% luminance).
  - Near Parallax Silhouettes: `#3D3D3D` (24% luminance).
  - Sensed Enemy Acoustic Smudge: `#5A0000` (Dark Crimson, 50% alpha).
- **Color-Blind Accessibility Rule**:
  - When Color-Blind Mode is enabled in Settings, the red danger channel is augmented:
    - Hostile silhouettes render with a **1.5 px solid white border** and a **45° diagonal hatch pattern** fill.
    - Sensed smudges render as grey crosshatching. Zero color hue perception is required to distinguish danger.

---

## 3. Silhouette Specifications (Model Sheets in Words)

### 3.1 Hero: Cipher-0 (The Blind Ronin)
- **Pixel Height**: **54 px** at 1920×1080 resolution.
- **Form Language**: Sharp angles, low center of gravity, agile posture.
- **Head**: Minimalist sleek helm with a single horizontal visor slit; zero decorative facial features.
- **Torso**: Layered segmented armor plating over a slender chassis.
- **Limbs**: Articulated cybernetic legs with tabi-style split-toe feet; arms wrapped in cord ties.
- **Signature Readable Features**:
  1. **The Katana**: Slender curved white blade worn at the left hip in an angled scabbard.
  2. **The Scarf**: A 32 px flowing white scarf attached to the neck that trails dynamic physics behind all movements.

### 3.2 Ashigaru (Spearman Drone)
- **Pixel Height**: **58 px**.
- **Form Language**: Tall, rigid, angular stance.
- **Signature Readable Feature**: Wide conical **Jingasa Helmet** and a 72 px two-handed **Yari Spear** held forward at chest height.

### 3.3 Kenshi (Swordsman Duelist)
- **Pixel Height**: **56 px**.
- **Form Language**: Wide, low, confident samurai stance.
- **Signature Readable Feature**: Single **Shoulder Cape (Sode)** fluttering behind and a Katana held in high **Jodan Stance** above the head.

### 3.4 Yumi (Balcony Archer)
- **Pixel Height**: **52 px**.
- **Form Language**: Deeply crouched, predatory perch.
- **Signature Readable Feature**: **Pointed Hooded Cowl** and an asymmetrical 64 px **Cybernetic Longbow** extending high above the head.

### 3.5 Oni Brute (Heavy Mech)
- **Pixel Height**: **82 px** (1.5× hero height).
- **Form Language**: Massive, broad, hunched, intimidating bulk.
- **Signature Readable Feature**: Heavy horned cyber-kabuto helmet, broad spiked shoulder pauldrons, and a thick 60 px spiked **Kanabo Club**.

### 3.6 Sentry (Turret)
- **Pixel Dimensions**: **28 × 28 px**.
- **Form Language**: Geometric hemispherical ceiling/wall turret.
- **Signature Readable Feature**: Glowing central red optical lens with rotating perimeter guard brackets.

---

## 4. Scarf Physics Specification (`VerletScarf`)

The hero's scarf is a signature visual anchor that provides kinetic weight and directional momentum:
- **Structure**: 6 connected point masses (Verlet integration) spaced 5.0 px apart (total length 30 px).
- **Anchor**: Point 0 is locked to the player's neck bone coordinate.
- **Constraints**:
  - Distance between adjacent points constrained to exactly 5.0 px.
  - Gravity applied: $g = 240 \text{ px/s²}$ downward.
  - Wind / Air Drag factor: $0.88$ damping per frame.
  - Inertial Lag: Points lag behind player horizontal movement by a factor of $-0.25 \times v_x$, producing a dramatic billowing trail during sprints and dashes.
- **Rendering**: Drawn via `Line2D` (width tapering from 4.0 px at neck to 1.5 px at tip) tinted `#FFFFFF`.

---

## 5. Environment Style & Procedural Props

Levels combine feudal Japanese architectural motifs with subterranean industrial sci-fi:
- **Shoji Screen Frames**: Procedurally drawn vertical rectangular lattices in background mid-layers (tint `#2B2B2B`).
- **Industrial Gantries & Catwalks**: Open-truss steel beams (`Line2D` cross-bracing) supporting upper floors.
- **Harmonic Bronze Lanterns**: Octagonal lanterns suspended from ceilings by thin chain links; sway physically on sonar wavefront impact.
- **Massive Stone Pillars**: Heavy vertical rectangular monoliths in far background (tint `#1A1A1A`) conveying colossal subterranean depth.
- **Fallen Mechs & Ancient Debris**: Dormant, broken mechanical husks resting in corridor alcoves, providing environmental storytelling.

---

## 6. Lighting, Sonar Reveal & Occlusion Rules

1. **Ambient Lighting**: Fixed at pure `#000000` via `CanvasModulate`. Without active pulses or lights, world luminance is exactly 0.0.
2. **Hero Glow Light**: A tiny local `PointLight2D` (radius 40 px, energy 0.6) centered on the hero with PCF5 shadows enabled. Allows seeing immediate footholds without alerting guards.
3. **Point Light Occlusion**: Every solid wall, closed door, and floor carries a closed `LightOccluder2D` polygon. Lights cast hard, dynamic 2D shadows, preventing light from leaking through walls.
4. **Distance-Field Air Arcs**: Handled by `sonar_air.gdshader` on full-screen ColorRect `SonarAir`. Analytical concentric rings expand at $700 \text{ px/s}$ with smoothstep band falloffs.

---

## 7. VFX Style Guide (The Visual Juice Standards)

- **Slash Trails**: Pure white curved arcs drawn via `Line2D` sampling `shaders/slash_arc.gdshader`. Fade duration: 0.12s.
- **Impact Sparks**: Directional `CPUParticles2D` emitting 8–16 razor-sharp white specks ($v = 200\text{–}350 \text{ px/s}$, lifetime 0.25s).
- **Acoustic Noise Ripples**: Unshaded expanding circles rendered directly on `SenseLayer`, visible in pure darkness to indicate sound origin.
- **Scream Chromatic Aberration**: Full-screen post-processing pulse distorting red/blue channels by 6.0 px over 0.25s on Scream release.
- **Hit-Stop Micro-Freezes**: 0.06s (light hit), 0.10s (heavy hit), 0.12s (parry deflect). Freezes animation and physics for instant impact feel.
