# SIGNAL LOST — Animation & Procedural Motion Specification (V2)

- **Purpose**: Frame-accurate animation specification, event trigger timelines, state cancellation hierarchies, and debug animation gallery tool design for all hero, adversary, and environmental motion.
- **Audience**: 2D Animators, Technical Artists, Combat Programmers, AI Engineers.
- **Status**: Approved.
- **Last Updated**: 2026-10-12.
- **Depends On**: [COMBAT_DESIGN.md](file:///c:/vibe-game/docs/COMBAT_DESIGN.md), [COMBAT_FRAME_DATA.md](file:///c:/vibe-game/docs/COMBAT_FRAME_DATA.md), [ART_DIRECTION.md](file:///c:/vibe-game/docs/ART_DIRECTION.md).

---

## 1. Animation Philosophy & Implementation Method

In accordance with SIGNAL LOST's minimalist tri-color aesthetic and zero external asset rule, character animations are implemented as **procedural skeletal tween rigs** and **vector polygon morphs** (`AnimationPlayer` driving node transforms and `_draw()` properties):
- **Skeletal Transforms**: Root position, hip sway, chest tilt, limb rotations, and weapon pivots.
- **Frame Rate Standard**: All timelines authored at **60 FPS** (1 tick = 16.67 ms).
- **Sub-Frame Interpolation**: Cubic ease-in/ease-out tweens for organic kinetic weight.
- **Event Animation Callbacks**: Discrete timeline methods fire hitbox toggles, procedural audio synthesis calls, and `NoiseBus` events on exact frames.

---

## 2. Hero Animation Master Table (Cipher-0)

| Animation Name | Duration (Frames / s) | Keys | Loop | Trigger Condition | Cancel Rules | Fired Events (Hitbox, Audio, Noise) |
|---|---|---|---|---|---|---|
| `hero_idle` | 60f (1.00s) | 4 | Yes | On floor, $|v_x| < 5$, no input | Cancel into Run, Jump, Attack, Dash, Pulse | — |
| `hero_run` | 36f (0.60s) | 6 | Yes | On floor, $|v_x| \ge 5$, not sneaking | Cancel into Jump, Sneak, Attack, Dash | Frame 9, 27: Footstep SFX + Noise (40 px) |
| `hero_sneak` | 48f (0.80s) | 4 | Yes | Holding `sneak`, moving on floor | Cancel into Run, Attack, Pulse | Silent (0 noise) |
| `hero_jump_start`| 6f (0.10s) | 3 | No | `jump` just pressed | Cannot be cancelled | Frame 1: Jump SFX |
| `hero_jump_rise` | 18f (0.30s) | 2 | No | Airborne, $v_y < 0$ | Cancel into Air Attack, Air Dash | — |
| `hero_jump_fall` | 24f (0.40s) | 2 | Yes | Airborne, $v_y \ge 0$ | Cancel into Air Attack | — |
| `hero_jump_land` | 8f (0.13s) | 3 | No | Floor contact from fall | Cancel into Run, Dash, Jump | Frame 1: Land SFX + Noise if hard fall |
| `hero_dash` | 15f (0.25s) | 4 | No | `dash` just pressed | Cannot cancel during active roll (f1–12) | Frame 1: I-Frames ON; Frame 13: I-Frames OFF |
| `katana_slash_1` | 21f (0.35s) | 4 | No | `attack` tap 1 | Frame 10+: Buffer slash 2; Cancel by Dash | f6: Hitbox ON + Swoosh SFX + Noise 180 px; f9: Hitbox OFF |
| `katana_slash_2` | 22f (0.37s) | 4 | No | `attack` tap 2 | Frame 9+: Buffer slash 3; Cancel by Dash | f5: Hitbox ON + Cut SFX + Noise 200 px; f8: Hitbox OFF |
| `katana_slash_3` | 33f (0.55s) | 5 | No | `attack` tap 3 | Recovery cancelable by Dash (f25+) | f9: Hitbox ON + Cleave SFX + Noise 280 px; f13: Hitbox OFF |
| `katana_heavy` | 42f (0.70s) | 6 | No | `attack_heavy` pressed | Uncancelable startup | f14: Hitbox ON + Iai SFX + Noise 300 px; f18: Hitbox OFF |
| `naginata_thrust`| 28f (0.47s) | 4 | No | Naginata `attack` tap 1 | Cancelable into sweep on f16+ | f8: Hitbox ON + Pierce SFX + Noise 240 px; f12: Hitbox OFF |
| `naginata_sweep` | 37f (0.62s) | 5 | No | Naginata `attack` tap 2 | Cancelable by Dash on f28+ | f10: Hitbox ON + Sweep SFX + Noise 280 px; f15: Hitbox OFF |
| `kunai_flurry` | 13f (0.22s) | 3 | No | Kunai `attack` tap 1 | Bufferable into flurry 2 | f3: Hitbox ON + Tick SFX + Noise 70 px; f5: Hitbox OFF |
| `parry_deflect` | 19f (0.32s) | 4 | No | Tap `block_parry` within 6f window | Grants 16 i-frames; cancelable into slash | f1: Deflect SFX + Sparks + Noise 260 px |
| `guard_hold` | Loop | 2 | Yes | Holding `block_parry` | Release to return to idle | Absorbs 70% damage |
| `guard_break` | 36f (0.60s) | 4 | No | Guard hit at 0 poise | Locked; cannot cancel | f1: Clang SFX + Stagger posture |
| `assassination` | 24f (0.40s) | 5 | No | Stealth attack behind enemy | Uncancelable cinematic | f12: Kill trigger + Muted SFX + Noise 60 px |
| `hero_hurt` | 14f (0.23s) | 3 | No | Damage taken | Grants 1.2s i-frame flashing | f1: Hit-stop 0.08s + White flash |
| `hero_death` | 36f (0.60s) | 4 | No | Health reaches 0 | Game over sequence | f1: Disintegration burst + Death SFX |

---

## 3. Adversary Animation Table

### 3.1 Ashigaru (Spearman Drone)
- `ashigaru_idle` (60f, loop): Rhythmic breathing hip sway, yari spear held upright.
- `ashigaru_patrol` (48f, loop): Deliberate march, spear pointed forward at 15°.
- `ashigaru_alert` (20f, once): Quick head swivel, antenna ripple, red exclamation flash.
- `ashigaru_thrust` (51f, once): Startup 27f (spear pulls back, red glint) -> Active 4f (rapid spear thrust forward 44 px) -> Recovery 20f. Fired event: Hitbox active on f28–31; Spear SFX + Noise 220 px.
- `ashigaru_stagger` (90f, once): Weapon drops to ground, torso hunched over, red poise circle overhead.
- `ashigaru_death` (30f, once): Upper chassis collapses forward, sparks burst, fades to floor debris.

### 3.2 Kenshi (Swordsman Duelist)
- `kenshi_idle` (50f, loop): High jodan stance, cape fluttering softly.
- `kenshi_quick_slash` (42f, once): Startup 21f -> Active 3f -> Recovery 18f. Quick dash-forward slash.
- `kenshi_spinning_sweep` (61f, once): Startup 32f (red kanji flash) -> Active 5f (360° sweep) -> Recovery 24f. Unblockable attack.
- `kenshi_parry` (24f, once): Blade sweeps upward, deflecting player slash with metallic clang.
- `kenshi_stagger` (90f, once): Falls back on one knee, head bowed.

### 3.3 Yumi (Balcony Archer)
- `yumi_perch` (60f, loop): Low crouched scanning pose on elevated beam.
- `yumi_aim` (42f, once): Bowstring drawn taut, red aiming laser line extends towards target.
- `yumi_fire` (24f, once): Bowstring releases, acoustic arrow launched at 520 px/s. Event: Arrow spawned on f3.
- `yumi_retreat` (30f, once): Drops flash pellet, performs acrobatic back-flip onto rear platform.

### 3.4 Oni Brute (Heavy Mech)
- `brute_wander` (64f, loop): Heavy lumbering walk; each footstep shakes ground (screen shake 1 px).
- `brute_ground_slam` (72f, once): Startup 36f (raises heavy kanabo club with both hands) -> Active 6f (violent ground smash) -> Recovery 30f. Event: Shatters glass floors, shockwave ripple.
- `brute_bull_charge` (Loop, 260 px/s): Low charging sprint; knocks aside obstacles until colliding with solid wall.
- `brute_wall_stun` (120f, once): Recoils from wall collision, club stuck in stone, head shaking violently.

### 3.5 Shogun Mech Boss
- `shogun_twin_sweep` (60f, once): Phase 1 dual-blade scissor cleave across 160° arc.
- `shogun_acoustic_slam` (75f, once): Phase 2 floor punch emitting arena-wide Scream shockwave.
- `shogun_sonic_dash` (30f, once): Phase 3 near-instantaneous cross-room blur strike (telegraph 18f).
- `shogun_stagger` (120f, once): Massive mech drops to knee, chest armor plates open exposing glowing core.

---

## 4. Animation Gallery Debug Scene (`scenes/debug/animation_gallery.tscn`)

A dedicated development tool to inspect and calibrate animations:
- **Layout**:
  - Center Viewport: Actor under test on flat pedestal with grid toggle.
  - Left Panel: Actor selector (`Cipher-0`, `Ashigaru`, `Kenshi`, `Yumi`, `Brute`, `Shogun`).
  - Right Panel: Animation clip list with Play, Pause, Loop, and Speed buttons (0.25x, 0.5x, 1.0x).
- **Interactive Scrubber**:
  - Horizontal timeline bar allowing scrubbing frame-by-frame (Frames 0 to $N$).
  - Current frame indicator ($f / N$) and millisecond readout.
- **Hitbox / Hurtbox Visualizer**:
  - Checkbox toggle rendering active hitboxes in **Cyan Outline** and hurtboxes in **Red Outline**.
  - Frame markers indicating exact startup, active, and recovery boundaries.
