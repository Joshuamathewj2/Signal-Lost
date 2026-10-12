# SIGNAL LOST — Combat Frame Data & Animation Timings (V2)

- **Purpose**: Frame-by-frame timing specification at 60 FPS for all player hero combat moves, weapon attacks, defensive actions, damage multipliers, and visual arc effects.
- **Audience**: Combat Designers, Gameplay Programmers, Animation Engineers, QA Testers.
- **Status**: Approved.
- **Last Updated**: 2026-10-11.
- **Depends On**: [GAME_CONFIG_REFERENCE.md](file:///c:/vibe-game/docs/GAME_CONFIG_REFERENCE.md), [COMBAT_DESIGN.md](file:///c:/vibe-game/docs/COMBAT_DESIGN.md).

---

## 1. Frame Data Timing Standards (60 FPS Baseline)

All timings are calibrated at **60 ticks per second** (1 frame = $16.67 \text{ ms}$):
- **Startup Frames ($S$)**: Window from button press to the frame before the hitbox activates.
- **Active Frames ($A$)**: Window during which the weapon hitbox is actively testing for collisions.
- **Recovery Frames ($R$)**: Window after the hitbox deactivates during which the hero cannot initiate a new action (unless cancelled by a buffered combo input).
- **Total Duration ($T$)**: $S + A + R$.
- **Damage ($D$)**: Segments removed from standard enemy health bars.
- **Poise Damage ($P$)**: Points subtracted from target poise meter (100 base).
- **Knockback ($KB$)**: Instantaneous horizontal velocity impulse applied to target.
- **Noise Radius ($NR$)**: Spatial acoustic circle emitted on `NoiseBus`.
- **Hit-Stop ($HS$)**: Micro-freeze applied on hit to both attacker and target.

---

## 2. Katana (Single Blade) Frame Data

| Move Name | Input | Startup ($S$) | Active ($A$) | Recovery ($R$) | Total ($T$) | Dmg ($D$) | Poise ($P$) | Knockback | Noise ($NR$) | Hit-Stop | Slash Arc Visual Style |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **Slash 1 (Horizontal)** | `J` (1st tap) | 6f (100ms) | 3f (50ms) | 12f (200ms) | 21f (350ms) | 1 seg | 15.0 | 120 px/s | 180 px | 0.06s | Horizontal white arc, 45° sweep, 32 px reach |
| **Slash 2 (Diagonal)** | `J` (2nd tap) | 5f (83ms) | 3f (50ms) | 14f (233ms) | 22f (366ms) | 1 seg | 15.0 | 150 px/s | 200 px | 0.06s | Rising diagonal white arc, 60° sweep, 34 px reach |
| **Slash 3 (Overhead Cleave)** | `J` (3rd tap) | 9f (150ms) | 4f (67ms) | 20f (333ms) | 33f (550ms) | 2 seg | 30.0 | 320 px/s | 280 px | 0.10s | Vertical downward crescent arc, heavy ground spark |
| **Heavy Strike (Iai Cut)** | `I` | 14f (233ms) | 4f (67ms) | 24f (400ms) | 42f (700ms) | 2 seg | 45.0 | 380 px/s | 300 px | 0.12s | Extended white flash line, screen shake 4 px |
| **Dash Slash** | `Dash` + `J` | 4f (67ms) | 4f (67ms) | 16f (267ms) | 24f (400ms) | 1 seg | 20.0 | 180 px/s | 210 px | 0.08s | Low horizontal sweep passing through target |
| **Jump Slash (Air Cleave)** | Air + `J` | 5f (83ms) | 5f (83ms) | 10f (167ms) | 20f (333ms) | 1 seg | 15.0 | 140 px/s | 190 px | 0.06s | 360° circular spinning white rim |

---

## 3. Naginata (Spear-Blade) Frame Data

| Move Name | Input | Startup ($S$) | Active ($A$) | Recovery ($R$) | Total ($T$) | Dmg ($D$) | Poise ($P$) | Knockback | Noise ($NR$) | Hit-Stop | Slash Arc Visual Style |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **Thrust 1 (Long Pierce)** | `J` (1st tap) | 8f (133ms) | 4f (67ms) | 16f (267ms) | 28f (467ms) | 1 seg | 35.0 | 220 px/s | 240 px | 0.08s | Straight needle beam line, 52 px reach, pierces 2 |
| **Sweep 2 (Wide Arc)** | `J` (2nd tap) | 10f (167ms) | 5f (83ms) | 22f (367ms) | 37f (617ms) | 2 seg | 40.0 | 280 px/s | 280 px | 0.10s | Massive 140° elliptical sweep clearing groups |
| **Heavy Impale (Overhead)** | `I` | 16f (267ms) | 5f (83ms) | 26f (433ms) | 47f (783ms) | 3 seg | 60.0 | 450 px/s | 320 px | 0.14s | Overhead vault slam, hits ceiling lanterns |
| **Jump Vault Thrust** | Air + `J` | 7f (117ms) | 6f (100ms) | 14f (233ms) | 27f (450ms) | 2 seg | 35.0 | 200 px/s | 250 px | 0.08s | Downward 45° diagonal dive spear |

---

## 4. Twin Kunai (Dual Daggers) Frame Data

| Move Name | Input | Startup ($S$) | Active ($A$) | Recovery ($R$) | Total ($T$) | Dmg ($D$) | Poise ($P$) | Knockback | Noise ($NR$) | Hit-Stop | Slash Arc Visual Style |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **Flurry 1 (Left Jab)** | `J` (1st tap) | 3f (50ms) | 2f (33ms) | 8f (133ms) | 13f (217ms) | 0.5 seg | 8.0 | 40 px/s | 70 px | 0.04s | Tiny rapid white tick, 20 px reach |
| **Flurry 2 (Right Jab)** | `J` (2nd tap) | 3f (50ms) | 2f (33ms) | 8f (133ms) | 13f (217ms) | 0.5 seg | 8.0 | 40 px/s | 75 px | 0.04s | Mirrored cross tick |
| **Flurry 3 (Double Slash)**| `J` (3rd tap) | 4f (67ms) | 3f (50ms) | 10f (167ms) | 17f (283ms) | 1.0 seg | 12.0 | 80 px/s | 85 px | 0.05s | Dual crossing chevron slashes |
| **Flurry 4 (Cross Finisher)**| `J` (4th tap) | 6f (100ms) | 3f (50ms) | 14f (233ms) | 23f (383ms) | 1.5 seg | 20.0 | 180 px/s | 110 px | 0.08s | Wide 'X' scissor cut |
| **Heavy Cross-Slice** | `I` | 8f (133ms) | 4f (67ms) | 18f (300ms) | 30f (500ms) | 2.0 seg | 30.0 | 220 px/s | 120 px | 0.08s | High-speed forward lunging dual slash |
| **Wall Cling Drop Slice** | Wall + `J` | 4f (67ms) | 4f (67ms) | 12f (200ms) | 20f (333ms) | 1.5 seg | 25.0 | 160 px/s | 90 px | 0.06s | Vertical downward drop slice |

---

## 5. Defensive & Evasion Frame Data

| Action | Input | Startup ($S$) | Active ($A$) | Recovery ($R$) | Total ($T$) | I-Frames | Poise Cost | Noise ($NR$) | Special Properties |
|---|---|---|---|---|---|---|---|---|---|
| **Parry (Deflect)** | Tap `K` / `LB` | 1f (17ms) | 6f (100ms) | 12f (200ms) | 19f (317ms) | 16f (on deflect) | 0.0 | 260 px | 40 poise damage to attacker; 0.12s hitstop |
| **Sustained Guard** | Hold `K` / `LB` | 7f (117ms) | Infinite | 10f (167ms) | Variable | 0f | Equal to hit | 0 px | Absorbs 70% damage; drains poise; breaks at 0 |
| **Dash (Evade Roll)** | `L` / `Pad B` | 1f (17ms) | 12f (200ms) | 3f (50ms) | 16f (267ms) | 12f (Frames 1–12)| 0.0 | 60 px | Velocity 400 px/s; passes through enemies |

---

## 6. Special Finishers & Stealth Actions

| Move Name | Conditions | Animation Duration | Damage ($D$) | Poise ($P$) | Noise ($NR$) | Hit-Stop | Camera & FX Reaction |
|---|---|---|---|---|---|---|---|
| **Stealth Assassination** | Behind enemy, unalerted | 24f (400ms) | Instant Kill ($\infty$) | $\infty$ | 60 px | 0.15s | Faint zoom punch +4%, red blood ribbon, zero alert |
| **Poise Break Finisher** | Staggered enemy ($\le 0$ poise) | 28f (467ms) | 4 seg (Lethal) | $\infty$ | 320 px | 0.18s | Dramatic camera shake 6 px, white flash, red shockwave |
| **Shuriken Throw** | Press `ability_primary` (`F`) | 8f (133ms) total | 0.5 seg | 10.0 | 120 px | 0.03s | Velocity 580 px/s, sticks in wall, acoustic lure |
