# SIGNAL LOST — User Interface & User Experience Specification (V2)

- **Purpose**: Comprehensive technical and visual design specification for the tactical samurai HUD, in-world floating indicators, menu hierarchies, boss gauges, contextual prompts, and accessibility features.
- **Audience**: UI/UX Designers, Front-End Gameplay Engineers, QA Testers.
- **Status**: Approved.
- **Last Updated**: 2026-10-12.
- **Depends On**: [00_CURRENT_STATE_AUDIT.md](file:///c:/vibe-game/docs/00_CURRENT_STATE_AUDIT.md), [ART_DIRECTION.md](file:///c:/vibe-game/docs/ART_DIRECTION.md), [GAME_CONFIG_REFERENCE.md](file:///c:/vibe-game/docs/GAME_CONFIG_REFERENCE.md).

---

## 1. Tactical In-Game HUD Layout (1920×1080 Viewport)

The HUD layout directly follows the target art direction from `reference_expected.png`, anchoring all status indicators to screen perimeters to keep the central combat and platforming canvas 100% unobstructed:

```
  ┌─────────────────────────────────────────────────────────────────┐
  │ [TOP-LEFT]                                                      │
  │ • LEVEL 03: IRON TIER                                           │
  │ • FRAGMENTS: [■][■][□] 2/3                                      │
  │ • CIPHER SCORE: 14,250                                          │
  │                                                                 │
  │                     [CENTRAL GAMEPLAY CANVAS]                   │
  │                   • Floating Awareness Bars (1px)               │
  │                   • Concentric Sonar Charge Rings               │
  │                   • In-World Noise Origin Reticles              │
  │                                                                 │
  │ [BOTTOM-LEFT]                           [BOTTOM-CENTER]         │
  │ • WEAPON: [KATANA BADGE] (Q)            • [BOSS BAR / PROGRESS] │
  │ • HEALTH: [■][■][■][□][□] (3/5)                                 │
  │ • SHURIKEN: ◆ ◆ ◆ (F)                                           │
  │ • BATTERY: [==========-----] 65/100                             │
  └─────────────────────────────────────────────────────────────────┘
```

---

## 2. Granular HUD Component Specifications

### 2.1 Top-Left: Mission & Progression Cluster
- **Level Name Label (`LevelLabel`)**:
  - Font: `Rajdhani-SemiBold.ttf`, 24 pt, Color `#FFFFFF`.
  - Format: `SECTOR 03 — IRON TIER`. Fades in for 4.0s on sector start, then settles into minimal font size (18 pt).
- **Fragment Counter (`FragmentCounter`)**:
  - 3 diamond glyphs (`[◆][◆][◇]`). Uncollected fragments show as hollow white outlines; collected fragments fill with solid `#FFFFFF` and pulse with a gentle bloom animation on pickup.
- **Cipher Score / Currency Counter**:
  - Minimalist numeric display tracking tactical stealth score: $+1,000$ per fragment, $+500$ per stealth assassination, $-200$ per detection.

### 2.2 Bottom-Left: Tactical Combat & Vitality Cluster
- **Active Weapon Badge (`WeaponBadge`)**:
  - 48×48 px square with a 1.5 px white border.
  - Displays vector icon of the active weapon: Katana blade, Naginata spear, or Twin Kunai.
  - Hotkey prompt `[Q]` rendered in bottom-right corner (12 pt font).
- **Segmented Health Bar (`HealthBar`)**:
  - Displays discrete rectangular health blocks (width 28 px, height 12 px, gap 4 px).
  - Normal state: Solid `#FFFFFF` fill with 1.5 px white outline.
  - Damage taken: Struck segment flashes `#E00000` for 0.15s, then disintegrates with particle sparks.
  - Invulnerability state: Remaining segments cycle alpha ($0.3 \leftrightarrow 1.0$) during the 1.2s post-hit i-frame window.
- **Sub-Weapon Shuriken Pips (`PipRow`)**:
  - 3 small diamond icons (`◆ ◆ ◆`) representing available shuriken/decoy charges.
  - Depleting a charge dims the diamond to 20% opacity.
- **Battery Gauge (`BatteryBar`)**:
  - 220×14 px horizontal bar anchored to the bottom edge.
  - Base: Pure black with a 1.5 px white outline.
  - Fill: Solid red `#E00000` indicating acoustic power.
  - Ghost Cost Preview: While holding `Space` to charge a pulse, a translucent pale-red overlay expands across the bar, showing the exact energy that will be deducted upon release.

### 2.3 Bottom-Center: Boss Vitality & Stance Gauge (`BossBar`)
- Active exclusively during boss encounters (e.g., Shogun Mech in Sector 9).
- **Boss Health Bar**: 480×16 px centered bar with segmented markers at 66% and 33% (indicating Phase 2 and Phase 3 transitions). Fill: Deep blood red `#E00000`.
- **Boss Poise Gauge**: Thin 480×4 px bar directly beneath the health bar. Fill: Razor white `#FFFFFF`. When poise depletes to 0, the bar flashes bright white and displays `[STAGGERED — STRIKE NOW]`.

---

## 3. In-World Floating HUD Elements (`SenseLayer`)

Rendered on an unshaded `CanvasLayer` (`follow_viewport_enabled = true`) so they remain visible in pitch darkness without requiring sonar illumination:
1. **Awareness Bars (`AwarenessBar`)**:
   - 1 px thin horizontal meter (24 px wide) positioned 18 px above revealed enemies.
   - Fills from left to right as enemy hears noise ($0.0 \to 1.0$).
   - Colors: White (0.0–0.5, Suspicious), Yellow/Grey Hatch (0.5–0.9, Investigating), Pure Red `#E00000` (1.0, Alert/Chase).
2. **Noise Origin Reticles (`WorldReticle`)**:
   - Expanding hollow circular ring rendered at the exact world coordinates of any noise event.
   - Expands outward at $700 \text{ px/s}$ and fades out over 0.8s, visually communicating to the player what enemies are hearing.
3. **Concentric Charge Rings (`ChargeRings`)**:
   - Rendered around the hero body while charging a pulse.
   - Ring 1 (Whisper): Solid white circle ($r=72 \text{ px}$).
   - Ring 2 (Normal): Dashed white circle ($r=200 \text{ px}$).
   - Ring 3 (Scream): Pulsing serrated red circle ($r=560 \text{ px}$) with vibrating edge jitter.

---

## 4. Contextual Guidance & Prompts

1. **Contextual Controls Prompt**:
   - Appears at level start or upon entering a new puzzle room: `[A]/[D] MOVE  •  [SPACE] PULSE  •  [J] ATTACK`.
   - Smoothly fades to 0% alpha 1.0s after the player inputs their first move.
2. **Emergency Stuck Prompt**:
   - If the player remains stationary in a dark room without emitting a pulse or interacting with objects for **15.0 seconds**:
   - A subtle pulsing prompt appears bottom-center: `PRESS [H] FOR ACOUSTIC EXIT BEACON`.

---

## 5. Menus & Progression Screens

### 5.1 Pause Menu (`scenes/ui/pause_menu.tscn`)
- Pauses the `SceneTree` (`process_mode = PROCESS_MODE_ALWAYS`).
- Engages dynamic low-pass audio muffling on the `Master` bus (cutoff 800 Hz).
- Background: 70% dark semi-transparent black overlay.
- Options: `RESUME`, `RESTART LEVEL`, `CODEX / LORE`, `SETTINGS`, `EXIT TO MAIN MENU`.

### 5.2 Codex & Fragment Lore Viewer (`scenes/ui/codex_menu.tscn`)
- Grid list of all 9 sectors.
- Selecting a sector displays acquired Signal Fragments with full lore transcription, terminal logs, and weapon blueprints.

### 5.3 Level Complete Screen (`scenes/ui/level_complete.tscn`)
- Opens upon touching Exit Terminal `E` following the 0.8s "SIGNAL RESTORED" sequence.
- **Run Statistics Grid**:
  - Time Elapsed (`03:24.12`).
  - Pulses Emitted by Tier (Whisper: 4, Normal: 6, Scream: 1).
  - Times Detected: 0.
  - Fragments Collected: 3 / 3.
- **Medal Award Banner**:
  - **Ghost Medal** (0 Normal/Scream pulses, 0 detections): Gleaming white diamond crest.
  - **Quiet Medal** (0 Scream pulses, $\le 1$ detection): Silver circular seal.
  - **Loud Medal** (Completed by any means): Bronze crossed blades badge.

---

## 6. Accessibility & Customization Specifications

- **Color-Blind Accessibility**: Toggles the shader uniform `hatch = true`. All red danger indicators and enemy silhouettes are converted to white borders with 45° diagonal hatch patterns.
- **Screen Shake Slider**: Adjustable from 0% (disabled) to 150% (intense). Default: 100%.
- **Chromatic Aberration Toggle**: Can be disabled to prevent visual strain.
- **UI Scaling**: 100% vector-based layouts rendered in Godot `canvas_items` mode, ensuring crisp pixel-perfect typography from 1080p up to 4K displays.
