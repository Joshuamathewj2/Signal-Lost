# SIGNAL LOST — Game Configuration & Tunables Reference (V2)

- **Purpose**: Exhaustive master reference registry for every balance tunable, physics constant, combat timing, noise threshold, and sonar parameter in SIGNAL LOST V2.
- **Audience**: Combat Designers, Level Designers, Technical Directors, AI Coding Agents.
- **Status**: Approved.
- **Last Updated**: 2026-10-11.
- **Depends On**: [00_CURRENT_STATE_AUDIT.md](file:///c:/vibe-game/docs/00_CURRENT_STATE_AUDIT.md), [ARCHITECTURE.md](file:///c:/vibe-game/docs/ARCHITECTURE.md).

---

## 1. Parameter Origin Conventions

Every tunable in this document is tagged with its provenance:
- **`[CURRENT]`**: Directly extracted and verified from active V1 source code (`res://resources/` or `autoload/`).
- **`[PROPOSED]`**: Introduced for the V2 samurai combat, vertical navigation, and puzzle expansion.

All values must reside in data-driven Godot resources (`res://resources/config/default_config.tres`, `pulse_*.tres`, `enemy_*.tres`, `attack_*.tres`). Hardcoding raw numbers in scripts is strictly prohibited.

---

## 2. Hero Locomotion & Platforming Tunables

| Parameter Name | Default Value | Unit | Valid Range | Subsystem | Status | Design Justification |
|---|---|---|---|---|---|---|
| `run_speed` | `180.0` | px/s | 120.0 – 240.0 | `PlayerMotor` | `[CURRENT]` | Gives swift lateral agility while keeping footstep noise cadence manageable. |
| `sneak_speed` | `70.0` | px/s | 50.0 – 100.0 | `PlayerMotor` | `[CURRENT]` | Deliberate, silent movement; slow enough to build tension near patrols. |
| `ground_accel` | `1400.0` | px/s² | 800.0 – 2000.0 | `PlayerMotor` | `[CURRENT]` | Snappy responsive acceleration to full run speed in ~0.13 seconds. |
| `ground_friction` | `1800.0` | px/s² | 1000.0 – 2500.0 | `PlayerMotor` | `[CURRENT]` | Crisp braking without slippery deceleration drift. |
| `air_accel` | `900.0` | px/s² | 500.0 – 1400.0 | `PlayerMotor` | `[CURRENT]` | Allows precise mid-air steering adjustments around vertical obstacles. |
| `gravity` | `1800.0` | px/s² | 1200.0 – 2400.0 | `PlayerMotor` | `[CURRENT]` | Fast, weighty arcade gravity preventing floaty platforming. |
| `fall_gravity_mult` | `1.35` | mult | 1.0 – 2.0 | `PlayerMotor` | `[CURRENT]` | Higher downward acceleration gives a satisfying snappy jump arc. |
| `jump_velocity` | `-560.0` | px/s | -450.0 – -650.0 | `PlayerMotor` | `[CURRENT]` | Jump apex is exactly 87 px (2.7 tiles), clearing 2-tile steps reliably. |
| `jump_cut_mult` | `0.45` | mult | 0.2 – 0.7 | `PlayerMotor` | `[CURRENT]` | Releasing jump while rising truncates upward velocity for short hops. |
| `max_fall_speed` | `900.0` | px/s | 600.0 – 1200.0 | `PlayerMotor` | `[CURRENT]` | Prevents terminal velocity from tunneling through thin floor collisions. |
| `coyote_time` | `0.10` | s | 0.05 – 0.20 | `PlayerMotor` | `[CURRENT]` | Forgiving ledge jump window (6 frames at 60 FPS) preventing missed jumps. |
| `jump_buffer` | `0.12` | s | 0.05 – 0.25 | `PlayerMotor` | `[CURRENT]` | Buffers pre-landing jump inputs (7 frames) for seamless bunny-hopping. |
| `drop_through_time` | `0.20` | s | 0.10 – 0.35 | `PlayerMotor` | `[CURRENT]` | Time catwalk collision mask bit is cleared during `sneak + jump`. |
| `max_horizontal_gap` | `3.5` | tiles | 2.0 – 4.0 | Level Design | `[CURRENT]` | Design rule: Any platform gap $> 3$ tiles requires a run-up or is impassable. |

---

## 3. Combat & Kinetic Frame Data Tunables

| Parameter Name | Default Value | Unit | Valid Range | Subsystem | Status | Design Justification |
|---|---|---|---|---|---|---|
| `health_segments_base` | `3` | segments | 1 – 5 | `HealthComponent` | `[PROPOSED]` | Replaces 1-hit death; allows surviving 2 errors while penalizing recklessness. |
| `health_segments_max` | `5` | segments | 3 – 5 | `HealthComponent` | `[PROPOSED]` | Expandable via secret Signal Fragment caches found in Levels 3 and 7. |
| `hero_poise_max` | `100.0` | poise | 50.0 – 150.0 | `PoiseComponent` | `[PROPOSED]` | Balance buffer; depleting this causes Guard Break. |
| `hero_poise_regen` | `25.0` | poise/s | 10.0 – 50.0 | `PoiseComponent` | `[PROPOSED]` | Regens balance after 1.5s without taking block/guard impact. |
| `dash_duration` | `0.25` | s | 0.15 – 0.35 | `CombatController` | `[PROPOSED]` | Forward evasion burst ($v = 400 \text{ px/s}$). |
| `dash_i_frames` | `12` | frames | 8 – 16 | `CombatController` | `[PROPOSED]` | 200 ms of pure damage immunity during the active roll. |
| `dash_cooldown` | `0.50` | s | 0.30 – 1.00 | `CombatController` | `[PROPOSED]` | Prevents infinite spamming of invulnerable rolls. |
| `parry_window_frames` | `6` | frames | 4 – 8 | `ParrySystem` | `[PROPOSED]` | Strict 100 ms deflect window rewarding precision timing (*Sekiro* feel). |
| `parry_i_frames` | `16` | frames | 10 – 20 | `ParrySystem` | `[PROPOSED]` | 266 ms invulnerability window awarded upon successful deflect. |
| `combo_buffer_window` | `0.35` | s | 0.20 – 0.50 | `CombatController` | `[PROPOSED]` | Buffer window to chain light Katana strikes 1 → 2 → 3. |
| `guard_break_stagger` | `0.60` | s | 0.40 – 1.00 | `PoiseComponent` | `[PROPOSED]` | Stun duration applied when blocking an attack at zero poise. |
| `hitstop_light` | `0.06` | s | 0.03 – 0.10 | `HitStop` | `[PROPOSED]` | Micro-freeze applied on standard light Katana / Kunai strikes. |
| `hitstop_heavy` | `0.10` | s | 0.08 – 0.15 | `HitStop` | `[PROPOSED]` | Heavy freeze applied on Naginata thrusts or Katana combo finishers. |
| `hitstop_parry` | `0.12` | s | 0.08 – 0.18 | `HitStop` | `[PROPOSED]` | Dramatic freeze applied upon successful blade deflection. |
| `attack_token_limit` | `2` | tokens | 1 – 3 | `AttackTokenMgr` | `[PROPOSED]` | Concurrency cap: maximum 2 enemies can attack simultaneously. |

---

## 4. Sonar & Echolocation Tunables

| Parameter Name | Default Value | Unit | Valid Range | Subsystem | Status | Design Justification |
|---|---|---|---|---|---|---|
| `sound_speed` | `700.0` | px/s | 500.0 – 900.0 | `NoiseBus` | `[CURRENT]` | Wavefront expansion velocity; balances visual speed and reaction time. |
| `max_bubbles` | `6` | count | 4 – 8 | `SonarSystem` | `[CURRENT]` | Hardware budget: 6 active lights $\le$ GL Compatibility 8-light limit. |
| `echo_memory_energy` | `0.12` | mult | 0.05 – 0.25 | `PulseBubble` | `[CURRENT]` | Faint 12% lingering brightness for mental spatial orientation. |
| `echo_memory_duration`| `2.0` | s | 1.0 – 3.5 | `PulseBubble` | `[CURRENT]` | Duration the ghost silhouette remains visible after primary fade. |
| **Whisper Reveal Radius** | `72.0` | px | 50.0 – 100.0 | `PulseProfile` | `[CURRENT]` | Short ~2.25 tile reveal; intimate scouting tool. |
| **Whisper Noise Mult** | `0.60` | mult | 0.40 – 0.80 | `PulseProfile` | `[CURRENT]` | Effective noise radius is 43.2 px (1.3 tiles); genuinely safe near guards. |
| **Whisper Energy Cost** | `6.0` | energy | 4.0 – 12.0 | `PulseProfile` | `[CURRENT]` | Cheap energy expenditure allowing frequent scouting taps. |
| **Whisper Cooldown** | `0.20` | s | 0.10 – 0.40 | `PulseProfile` | `[CURRENT]` | Rapid recovery for nimble stealth exploration. |
| **Normal Reveal Radius** | `200.0` | px | 150.0 – 250.0 | `PulseProfile` | `[CURRENT]` | Standard room reveal radius (~6.25 tiles). |
| **Normal Noise Mult** | `1.00` | mult | 0.80 – 1.20 | `PulseProfile` | `[CURRENT]` | Noise radius exactly equals reveal radius (200 px). 1:1 exposure. |
| **Normal Energy Cost** | `22.0` | energy | 15.0 – 30.0 | `PulseProfile` | `[CURRENT]` | Moderate cost; requires pauses to regenerate. |
| **Normal Cooldown** | `0.60` | s | 0.40 – 1.00 | `PulseProfile` | `[CURRENT]` | Brief delay preventing reckless spamming. |
| **Scream Reveal Radius** | `560.0` | px | 450.0 – 700.0 | `PulseProfile` | `[CURRENT]` | Massive multi-floor reveal (~17.5 tiles); illuminates entire sectors. |
| **Scream Noise Mult** | `1.30` | mult | 1.10 – 1.60 | `PulseProfile` | `[CURRENT]` | Noise radius is 728 px (+30% larger than reveal); alerts entire sectors. |
| **Scream Energy Cost** | `55.0` | energy | 40.0 – 70.0 | `PulseProfile` | `[CURRENT]` | Consumes over half of maximum battery capacity. |
| **Scream Cooldown** | `3.50` | s | 2.50 – 5.00 | `PulseProfile` | `[CURRENT]` | Lengthy recovery enforcing tactical vulnerability. |
| `battery_max` | `100.0` | energy | 80.0 – 150.0 | `Battery` | `[CURRENT]` | Normalized energy pool. |
| `battery_regen_idle` | `8.0` | energy/s | 5.0 – 15.0 | `Battery` | `[CURRENT]` | Passive regeneration when stationary and not charging. |
| `battery_regen_moving`| `3.0` | energy/s | 1.0 – 6.0 | `Battery` | `[CURRENT]` | Slower regeneration while running or sneaking. |
| `battery_regen_delay` | `0.80` | s | 0.40 – 1.50 | `Battery` | `[CURRENT]` | Delay after emitting a pulse before regeneration begins. |

---

## 5. Noise Physics & Propagation Tunables

| Event Type | Noise Radius | Loudness | Wall Penalty | Propagation Velocity | Subsystem | Status |
|---|---|---|---|---|---|---|
| `FOOTSTEP` | `40.0 px` | `0.5` | `0.75 / wall` | `700.0 px/s` | `NoiseBus` | `[CURRENT]` |
| `LAND` (Hard Landing) | `96.0 px` | `1.0` | `0.75 / wall` | `700.0 px/s` | `NoiseBus` | `[CURRENT]` |
| `PULSE_WHISPER` | `43.2 px` | `1.0` | `0.75 / wall` | `700.0 px/s` | `NoiseBus` | `[CURRENT]` |
| `PULSE_NORMAL` | `200.0 px` | `2.0` | `0.75 / wall` | `700.0 px/s` | `NoiseBus` | `[CURRENT]` |
| `PULSE_SCREAM` | `728.0 px` | `3.0` | `0.75 / wall` | `700.0 px/s` | `NoiseBus` | `[CURRENT]` |
| `SLASH_KATANA_1` | `180.0 px` | `1.5` | `0.75 / wall` | `700.0 px/s` | `NoiseBus` | `[PROPOSED]` |
| `SLASH_KATANA_2` | `200.0 px` | `1.8` | `0.75 / wall` | `700.0 px/s` | `NoiseBus` | `[PROPOSED]` |
| `SLASH_KATANA_3` | `280.0 px` | `2.5` | `0.75 / wall` | `700.0 px/s` | `NoiseBus` | `[PROPOSED]` |
| `THRUST_NAGINATA` | `320.0 px` | `2.8` | `0.75 / wall` | `700.0 px/s` | `NoiseBus` | `[PROPOSED]` |
| `STRIKE_KUNAI` | `90.0 px` | `0.8` | `0.75 / wall` | `700.0 px/s` | `NoiseBus` | `[PROPOSED]` |
| `PARRY_CLASH` | `260.0 px` | `2.2` | `0.75 / wall` | `700.0 px/s` | `NoiseBus` | `[PROPOSED]` |
| `ASSASSINATION` | `60.0 px` | `0.6` | `0.75 / wall` | `700.0 px/s` | `NoiseBus` | `[PROPOSED]` |
| `GLASS_SHATTER` | `360.0 px` | `3.0` | `0.75 / wall` | `700.0 px/s` | `NoiseBus` | `[CURRENT]` |
| `LANTERN_CLINK` | `96.0 px` | `1.0` | `0.75 / wall` | `700.0 px/s` | `NoiseBus` | `[CURRENT]` |
| `PLATE_CLICK` | `64.0 px` | `1.0` | `0.75 / wall` | `700.0 px/s` | `NoiseBus` | `[CURRENT]` |
| `HINT_BEACON` | `120.0 px` | `1.2` | `0.75 / wall` | `700.0 px/s` | `NoiseBus` | `[PROPOSED]` |

---

## 6. Enemy Stats & Perception Thresholds

| Enemy Type | HP | Poise | Walk / Run Spd | Hearing Sens | Threshold | Sight Cone / Dist | Tell Window | Status |
|---|---|---|---|---|---|---|---|---|
| **Ashigaru (Spear)** | `2` | `40.0` | `50 / 120 px/s` | `1.0x` | `1.0` | `70° / 200 px` | `0.45 s (27f)` | `[PROPOSED]` |
| **Kenshi (Sword)** | `3` | `60.0` | `70 / 160 px/s` | `1.0x` | `1.0` | `80° / 220 px` | `0.35 s (21f)` | `[PROPOSED]` |
| **Yumi (Archer)** | `1` | `20.0` | `40 / 100 px/s` | `1.2x` | `0.8` | `40° / 400 px` | `0.70 s (42f)` | `[PROPOSED]` |
| **Oni Brute (Heavy)**| `6` | `120.0`| `40 / 110 px/s` | `2.5x (vib)` | `0.5` | `0° / 0 px (Blind)`| `0.60 s (36f)` | `[PROPOSED]` |
| **Sentry (Turret)** | `1` | `10.0` | `0 / 0 px/s` | `1.0x` | `3.0` | `40° / 320 px` | `0.60 s (36f)` | `[CURRENT]` |
| **Shogun Mech (Boss)**| `18`| `200.0`| `60 / 150 px/s` | `1.5x` | `0.5` | `120° / 450 px`| `0.50 s (30f)` | `[PROPOSED]` |

---

## 7. Camera & Game Feel Tunables

| Parameter Name | Default Value | Unit | Subsystem | Status | Design Justification |
|---|---|---|---|---|---|
| `camera_zoom_base` | `1.80` | mult | `CameraRig` | `[PROPOSED]` | Framed so hero silhouette is prominent while showing 2-3 vertical floors. |
| `camera_zoom_combat`| `1.45` | mult | `CameraRig` | `[PROPOSED]` | Zooms out dynamically during multi-enemy combat for tactical awareness. |
| `camera_lookahead` | `48.0` | px | `CameraRig` | `[PROPOSED]` | Offsets camera along player facing direction to reveal path ahead. |
| `shake_whisper` | `0.0` | px | `CameraRig` | `[CURRENT]` | Subtle; zero screen disturbance on whisper. |
| `shake_normal` | `2.0` | px | `CameraRig` | `[CURRENT]` | Mild 2 px vibration confirming acoustic release. |
| `shake_scream` | `9.0` | px | `CameraRig` | `[CURRENT]` | Heavy violent rumble emphasizing shockwave release. |
| `zoom_punch_scream`| `+6%` | mult | `CameraRig` | `[CURRENT]` | Quick focal punch (0.15s in, 0.5s out) creating physical impact. |
| `hint_beacon_cooldown`| `5.0`| s | `Player` | `[PROPOSED]` | Cooldown for `H` key hint beacon to prevent continuous noise radar. |
