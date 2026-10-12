# SIGNAL LOST — Combat System Design Specification (V2)

- **Purpose**: Authoritative game design specification for the SIGNAL LOST V2 samurai combat engine, detailing weapon mechanics, parrying, stealth assassinations, hit feedback, noise coupling, and fairness rules.
- **Audience**: Combat Designers, Gameplay Programmers, AI Behavior Engineers, Technical Directors.
- **Status**: Approved.
- **Last Updated**: 2026-10-11.
- **Depends On**: [00_CURRENT_STATE_AUDIT.md](file:///c:/vibe-game/docs/00_CURRENT_STATE_AUDIT.md), [GAME_CONFIG_REFERENCE.md](file:///c:/vibe-game/docs/GAME_CONFIG_REFERENCE.md), [INPUT_MAP.md](file:///c:/vibe-game/docs/INPUT_MAP.md).

---

## 1. Combat Design Philosophy: Blades in the Abyss

Combat in SIGNAL LOST is built around three core mechanical tenets:
1. **Deliberate Commitment**: Every blade swing has physical startup, active hit frames, and recovery. Spamming attacks leaves the hero vulnerable to counter-strikes and alerts entire sectors.
2. **Sound as the Ultimate Trade-Off**: Every blade clash, parry spark, and heavy thrust generates a physical `NoiseEvent` on `NoiseBus`. Engaging in combat exposes your position through darkness.
3. **Visceral Tactility**: Every hit must *feel* devastating through synchronized hit-stop micro-freezes, white flash frames, directional sparks, and procedural acoustic ripples.

---

## 2. The Three Primary Weapons

The hero unlocks and switches between three signature weapons via `weapon_swap` (`Q` / `D-Pad Up`):

| Weapon Feature | **Katana (Single Blade)** | **Naginata (Spear-Blade)** | **Twin Kunai (Dual Daggers)** |
|---|---|---|---|
| **Role & Archetype** | Balanced duelist; fluid combos. | Long-reach spacing; piercing thrusts. | Rapid close-quarters; silent strikes. |
| **Reach / Range** | Medium (32 px horizontal). | Long (52 px horizontal, 36 px vertical).| Short (20 px horizontal). |
| **Combo Chain** | 3-hit slash sequence (`J-J-J`). | 2-hit thrust-sweep chain (`J-J`). | 4-hit rapid flurry (`J-J-J-J`). |
| **Heavy Attack** | Overhead downward slash (`I`). | High-poise piercing thrust (`I`). | Twin horizontal cross-slice (`I`). |
| **Noise Profile** | Moderate (180 – 280 px noise). | High (240 – 320 px noise). | Low (70 – 120 px noise). |
| **Poise Damage** | Standard (15 / 15 / 30 poise). | Heavy (35 / 45 poise). | Low (8 / 8 / 12 / 20 poise). |
| **Special Utility** | Can deflect all physical projectiles. | Breaks wooden barriers & high lanterns.| Wall-cling ability; silent takedowns. |
| **Unlock Level** | Level 1 (Default starter). | Level 3 (Iron Tier). | Level 5 (Resonance Deep). |

---

## 3. Defensive Mechanics: Parry, Guard & Evasion

### 3.1 Frame-Tight Parry (Deflect)
- **Input**: Tap `block_parry` (`K` / `LB`).
- **Deflect Window**: Exactly **6 frames (100 ms at 60 FPS)**.
- **Outcome on Success**:
  - Nullifies 100% of incoming physical damage.
  - Inflicts **40.0 Poise Damage** directly to the attacker.
  - Grants **16 Invulnerability Frames (266 ms)** to the hero.
  - Triggers **0.12s Hit-Stop**, a burst of 12 white sparks, and a loud metallic clink (`NoiseEvent.PARRY`, radius 260 px).
  - Can deflect incoming arrows and sentry projectiles back along their trajectory.

### 3.2 Sustained Guard & Guard Break
- **Input**: Hold `block_parry` beyond the 6-frame parry window.
- **Guard Mechanics**:
  - Absorbs 70% of physical damage; 30% chips through to the hero's health segment.
  - Each absorbed strike drains hero poise by the incoming attack's poise value.
  - If hero poise reaches 0.0 while guarding, **Guard Break** occurs:
    - Hero enters a forced **0.60s Stagger** animation.
    - All defenses dropped; incoming hits deal critical damage.

### 3.3 Dynamic Evade (Dash / Roll)
- **Input**: Press `dash` (`L` / `Gamepad B`).
- **Duration**: 0.25 seconds (15 frames) with a forward impulse of 400 px/s.
- **I-Frames**: Grants **12 Invulnerability Frames (200 ms)** starting on Frame 1.
- **Cooldown**: 0.50 seconds. Prevents infinite roll spamming.
- **Noise**: Low sliding friction noise (radius 60 px).

---

## 4. Stealth Assassination (Finisher)

When stalking an enemy in darkness, the hero can execute an instant lethal assassination:
- **Trigger Conditions**:
  1. Hero distance to target $\le 28 \text{ px}$.
  2. Hero is positioned behind the target (within a 60° rear cone).
  3. Target awareness $< 0.35$ (unalerted / not in CHASE).
- **Execution Flow**:
  - Press `attack` (`J` / `RMB`).
  - Hero locks onto enemy neck for **0.40s Finisher** animation.
  - Instantly kills standard enemies (Ashigaru, Kenshi, Yumi) regardless of remaining HP.
  - Inflicts 50% max HP damage to heavy enemies (Oni Brute).
  - Produces a muted flesh-cut sound (Noise radius 60 px, loudness 0.6).

---

## 5. Poise, Stagger & Finisher States

Both the hero and enemies possess a dedicated **Poise Meter** (0.0 to 100.0 max):
1. **Poise Depletion**: Taking repeated weapon strikes, heavy thrusts, or parry deflects drains poise.
2. **Stagger State**: When an enemy's poise reaches 0.0:
   - They freeze their current action and enter a vulnerable **Stagger** state for 1.5 seconds.
   - A bright red circle glyph flashes above their head.
   - Any melee attack delivered during stagger triggers a high-damage **Finisher Slash**, instantly eliminating them.
3. **Poise Regeneration**: If an entity avoids taking poise damage for 2.0 seconds, poise regenerates at **25.0 points/sec**.

---

## 6. Hit-Feedback Checklist (The Juice Standard)

Every successful weapon hit or deflection must execute this exact feedback chain to guarantee satisfying game feel:

- [ ] **Hit-Stop (Micro-Freeze)**: Global engine freeze of 0.06s (light), 0.10s (heavy), or 0.12s (parry).
- [ ] **Camera Shake**: Trauma burst (2.0 to 6.0 px) along the slash trajectory vector.
- [ ] **White Flash Frame**: 1 single frame of pure white silhouette overlay (`#FFFFFF` alpha 0.40) on the struck entity.
- [ ] **Procedural Slash Trail**: Curved white `Line2D` arc matching blade swing angle, fading over 0.12s.
- [ ] **Directional Particle Sparks**: 8–16 sharp white particle specks ejected opposite to the impact angle.
- [ ] **Acoustic Noise Ripple**: Circular unshaded ripple ring expanding from impact origin on `NoiseBus`.
- [ ] **Dynamic Sound Effect**: Synthesized metallic slice or deflect generated via `SfxLibrary`.

---

## 7. Master Combat Noise Table

Every combat action feeds deterministically into `NoiseBus`:

| Combat Action | Primary Sound | Noise Radius | Loudness | Wall Attenuation | Hearing Alert Impact |
|---|---|---|---|---|---|
| **Katana Slash 1** | Blade swoosh | `180.0 px` | `1.5` | `0.75 / wall` | Heard by guards in immediate room. |
| **Katana Slash 2** | Crisp blade cut | `200.0 px` | `1.8` | `0.75 / wall` | Alert radius extends into doorway. |
| **Katana Slash 3 (Finisher)**| Heavy blade cleave | `280.0 px` | `2.5` | `0.75 / wall` | Alerts adjacent corridor guards. |
| **Naginata Heavy Thrust** | Resonant spear snap | `320.0 px` | `2.8` | `0.75 / wall` | Penetrates across multi-floor catwalks. |
| **Twin Kunai Strike** | Soft knife flick | `90.0 px` | `0.8` | `0.75 / wall` | Safe unless guard is in same 3-tile zone. |
| **Successful Parry Deflect**| High metallic ring | `260.0 px` | `2.2` | `0.75 / wall` | Sharp ping triggers enemy investigation. |
| **Stealth Assassination** | Muted flesh cut | `60.0 px` | `0.6` | `0.75 / wall` | Almost silent; safe in dark corners. |
| **Shuriken Impact** | Wall clink | `120.0 px` | `1.2` | `0.75 / wall` | Can be thrown remotely as acoustic lure. |

---

## 8. Combat Fairness Guarantees

To prevent cheap deaths and ensure combat feels honorable and skill-based:
1. **Telegraph Minimum Rule**: No hostile strike may ever hit in less than **18 frames (300 ms)** from telegraph start. Unblockable attacks must telegraph for at least **30 frames (500 ms)** with a flashing red kanji glyph.
2. **Attack Token Limit**: Maximum of **2 enemies** can hold active attack tokens simultaneously. Surrounding enemies maintain defensive spacing.
3. **I-Frame Safety**: Dash grants 12 i-frames; Parry grants 16 i-frames. Taking damage grants **1.2s of invulnerability flashing** to prevent stunlock deaths.
4. **No Off-Screen Attacks**: Enemies outside the active camera viewport cannot initiate attack startups.
