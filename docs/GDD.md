# SIGNAL LOST — Game Design Document (v1.0)

## 0. Assumptions (stated instead of asking)
1. The two reference screenshots mentioned in the brief were **not attached** to the planning session. §2B text of the brief is treated as the complete, binding art direction.
2. Engine: Godot **4.4 stable** (anything ≥4.3 works; we use `Parallax2D`, which needs 4.3+).
3. Renderer: **Compatibility** (GL) is the default and only target code path (see ARCHITECTURE §2). Everything must also run under Forward+ unchanged.
4. Font: **Rajdhani** (SIL OFL 1.1), Medium + SemiBold weights, bundled in `res://assets/fonts/`.
5. Platform: Windows/Linux desktop, keyboard+mouse and XInput gamepad.
6. Scope: 8 levels, 4 enemy types, Decoy Beacon is the only "stretch" ability that is built (Phase 8) because the HUD layout requires an ability slot. EMP, Echo-memory upgrade and Mimic remain stretch (Phase 10, optional).
7. All numbers below are defaults that live in `res://resources/config/default_config.tres` (a `GameConfigData` resource) or in the `.tres` profiles. The code must never hardcode them.

## 1. Pitch
You are a tiny robot in an abandoned facility. The world is pitch black. You see only by emitting sonar pulses — but every pulse is a sound, and the machines that still patrol the facility hear it. **Seeing reveals your position.**

Genre: 2D side-view stealth platformer / puzzle. Level length 30–120 s for a skilled run. Instant restart.

## 2. Core loop
1. Move in darkness; only a faint 40 px glow around the robot is visible.
2. Charge and release a sonar pulse; a dome of reveal expands from the robot, clipped by walls/floors.
3. Enemies within the pulse's **noise radius** (not reveal radius) hear it when the sound wavefront reaches them and investigate the **origin**.
4. Use the remembered picture (bubbles fade over seconds) to plan, sneak, distract, reach the **Exit Terminal**.
5. Score screen → next level.

## 3. Units & world scale
| Item | Value |
|---|---|
| Tile size | 32 px |
| Base viewport | 1280×720, stretch `canvas_items`, aspect `expand` |
| Camera zoom | 2.0 (visible world ≈ 640×360 px ≈ 20×11 tiles) |
| Robot body | 14×18 px collision capsule (crouched 14×12) |
| Sound/wave speed | 700 px/s (visual wavefront and hearing delay share it) |

## 4. Player
### 4.1 Movement (side-view, `CharacterBody2D`)
| Param | Default | Note |
|---|---|---|
| run_speed | 180 px/s | |
| sneak_speed | 70 px/s | hold `sneak` (crouch pose, silent) |
| ground_accel | 1400 px/s² | |
| ground_friction | 1800 px/s² | |
| air_accel | 900 px/s² | |
| gravity | 1800 px/s² | |
| fall_gravity_mult | 1.35 | when vy > 0 |
| jump_velocity | −560 px/s | apex ≈ 87 px ≈ 2.7 tiles → clears **2-tile** steps |
| jump_cut_mult | 0.45 | releasing jump while rising multiplies vy |
| max_fall_speed | 900 px/s | |
| coyote_time | 0.10 s | |
| jump_buffer | 0.12 s | |
| drop_through_time | 0.20 s | `sneak`+`jump` on a one-way platform |
| max horizontal jump | ≈3.5 tiles → level gaps ≤ **3 tiles** | |

Sneaking cannot jump higher (jump allowed, but sneak is cancelled while airborne).

### 4.2 Movement noise
| Event | Condition | Noise radius | Loudness | Type |
|---|---|---|---|---|
| Footstep | on floor, not sneaking, \|vx\| > 40, every 0.30 s | 40 px | 0.5 | `FOOTSTEP` |
| Hard landing | landing with vy > 520 px/s | 96 px | 1.0 | `LAND` |
| Sneak | any | 0 | 0 | none |

### 4.3 Sonar pulse (the heart)
Hold `pulse` to charge, release to emit. Charge time `t` (s) → normalized `c = clamp(t / charge_full_time, 0, 1)`, `charge_full_time = 1.0 s`.
Tier is **discrete** (keeps medals and enemy rules legible):
- `c < 0.35` (incl. taps) → **Whisper**
- `0.35 ≤ c < 0.85` → **Normal**
- `c ≥ 0.85` → **Scream**

| Profile (`PulseProfile`) | reveal_radius | expand_time | hold_time | fade_time | noise_mult | noise_radius | loudness | energy_cost | cooldown | shake | zoom punch |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Whisper | 72 px | r/700 (≈0.10 s) | 0.6 s | 0.6 s | 0.6 | **43 px** | 1.0 | 6 | 0.20 s | 0 | 0 |
| Normal | 200 px | ≈0.29 s | 1.2 s | 1.6 s | 1.0 | **200 px** | 2.0 | 22 | 0.60 s | 2 px | 0 |
| Scream | 560 px | 0.80 s | 2.0 s | 3.0 s | 1.3 | **728 px** | 3.0 | 55 | 3.50 s | 9 px | +6% |

- Noise radius is always `reveal_radius * noise_mult`. Whisper's noise (43 px ≈ 1.3 tiles) means it is only heard by an enemy practically touching you: **a genuinely safe option**. Scream's noise is 30% larger than what it shows you: **a genuine gamble**.
- If energy is insufficient for the selected tier, the pulse downgrades to the highest affordable tier; if not even Whisper, it fails with a dry "click" (no noise, no reveal). The charge ring shows the downgrade live (ring turns dashed).
- While charging: movement allowed at 60% speed, battery regen paused.
- Echo memory (base game, always on): after fade, a bubble lingers at **12% brightness for 2.0 s** (the "ghost map"), then disappears.
- Max simultaneous bubbles: **6** (oldest recycled first).

### 4.4 Battery
`max 100`, regen **8/s** when |v| < 5 and not charging, **3/s** while moving, regen starts **0.8 s** after the last pulse. Energy 0: cannot pulse; movement unaffected; HUD bar flashes.

### 4.5 Health — decision: **one-hit death + instant restart**
Justification: levels are 30–120 s and checkpointless; one-hit makes every pulse a real decision and keeps state small (no healing systems). Death → 0.08 s hit-stop → 0.6 s disintegration → level reload (total ≤ 1.0 s). `restart` key reloads instantly at any time.

### 4.6 Visibility of the player
The player is "revealed" to enemies whenever the player's position is inside any active bubble (brightness > 0.25) with clear line of sight from the bubble origin (your own pulse always reveals you). Enemies with sight (Listener, Hunter, Sentry) then see you if within their sight range and LOS. Being in pure darkness = invisible.

## 5. Enemies (summary — full FSMs in ENEMY_AI.md)
All share `HearingComponent` (receives `NoiseEvent`). Render: flat red `#E00000` silhouettes, visible only when lit by a bubble or the player glow; when they make sound while unlit they show as a blurred dark-red smudge `#5A0000` @50%.

| Enemy | Speed (walk/run) | Hearing threshold | Hearing mult | Sight | Contact | Tell |
|---|---|---|---|---|---|---|
| Listener (security drone on legs) | 50 / 120 | loudness ≥ 1.0 | 1.0 | 200 px, 70° cone | kills | antenna ripple + "!" flash |
| Sentry (balcony turret) | static, turns 60°/s | loudness ≥ 3.0 (screams, amp vents, glass) | 1.0 | 320 px, 40° cone | n/a (projectiles kill) | charge whine 0.6 s, red laser tick |
| Hunter (fast hound-drone) | 90 / 230 | loudness ≥ 0.5 (hears footsteps) | 1.25 | 240 px, 90° | kills | double-ping red ripple |
| Deaf Brute (heavy mech) | 40 / 110 | ignores SOUND; hears `FOOTSTEP`/`LAND` only (vibration) | 2.5 | none | kills | ground-thud ripples every step |
| Mimic (stretch) | — | — | — | — | — | looks like a fragment |

## 6. Environment & objects (all extend `Interactable`)
| Object | ASCII | Behaviour |
|---|---|---|
| Solid wall/floor | `#` | collides, occludes pulses, white rough edge line on exposed sides |
| One-way platform (catwalk) | `=` | jump up through, drop with `sneak`+`jump`; does NOT occlude |
| Keycard | `K` | pickup; enables `D` doors (level-wide) |
| Locked door | `D` (2 tall) | solid + occludes until player touches it holding a keycard; opens with slide-up |
| Plate door | `R` (2 tall) | opens permanently when any `_` plate is pressed |
| Pressure plate | `_` | pressed by player or enemy; click noise (r 64, loud 1.0) |
| One-way door | `>` / `<` (2 tall) | passable only moving right / left |
| Glass floor | `G` | solid; breaks if hit by a Scream wavefront or a Brute steps on it → shatter noise r 360, loud 3.0 |
| Hanging lantern | `~` (ceiling) | swings when any wavefront passes; clink noise r 96, loud 1.0 (throttled 1/1.5 s) |
| Amp vent intake / outlet | `V` / `v` | noise originating within 96 px of an intake is re-emitted at its paired outlet 0.2 s later with radius `max(r*4, 240)` and loudness +1.5 (lure tool) |
| Mute vent | `M` | pulses emitted within 64 px get noise_mult ×0.3 (reveal unchanged) — safe scouting spot |
| Exit terminal | `E` | touch + hold `interact`-free: on contact, 0.8 s "SIGNAL RESTORED" sequence → level complete |
| Signal fragment | `F` | collectible; score + lore line on the level complete screen |
| Decoy pickup | `C` | +1 decoy charge (Phase 8) |

## 7. Decoy Beacon (built in Phase 8; EMP stays stretch)
`ability_primary` (F): throw a beacon (arc, v = 380 px/s at 45° in facing direction). On landing it waits 0.5 s then emits a **Normal** pulse (reveal + noise) from its position. Charges per level from level header `decoys=N` + `C` pickups. Max 3.

## 8. Win/lose, scoring, medals
- Win: touch Exit Terminal. Lose: contact with an enemy or projectile, or falling out of the map (y > map bottom + 200).
- Tracked per run: time, pulses by tier, loudest tier, times detected (enemy entered CHASE), fragments.
- Medal:
  - **Ghost**: 0 Normal and 0 Scream pulses (decoys allowed) and 0 detections.
  - **Quiet**: 0 Scream pulses, ≤ 1 detection.
  - **Loud**: anything else.
- Saved per level: best time, best medal, fragments found (bitmask).

## 9. Progression (8 levels — maps in LEVEL_DESIGN.md)
| # | Name | Teaches |
|---|---|---|
| 1 | Wake | move, jump, pulse tiers, fragment, exit |
| 2 | Listen | Listener, whisper is safe, normal is heard |
| 3 | Floors | one-way drop-through, keycard + locked door, multi-floor |
| 4 | Crossfire | Sentry + projectiles, glass floor gamble |
| 5 | Heavy | Deaf Brute (sneak), pressure plate, lanterns |
| 6 | Pack | Hunter memory, amp vent lure, mute vent scouting |
| 7 | Gates | one-way doors, mixed enemies |
| 8 | Signal | everything + decoys |
Tutorial = level design only; the only text is 1 short controls hint at level 1 start (fades after first move) and key glyphs on world-space hint signs (`?` panels lit by pulses).

## 10. HUD / UX (full spec in UI_UX.md)
Top-left fragment counter; bottom-left ability icon + key badge + charge pips + red battery bar with pending-cost ghost; bottom-centre level name + progress line; red awareness bars above revealed enemies; world reticles; charge ring (white) + noise ring (red). Black/white/red only.

## 11. Game feel
Hit-stop 0.08 s on death; zoom punch +6% on Scream (0.15 s in, 0.5 s out); shake by tier; chromatic aberration burst on Scream and detection; one white flash frame (alpha 0.35) on first detection; squash/stretch on jump/land; antenna wobble; robot disintegrates into white particles.

## 12. Colour language (exact; theme resource `palette.tres`)
`#000000` bg · `#1A1A1A` far · `#2B2B2B` mid · `#3D3D3D` near · `#FFFFFF` player/edges/UI · `#E00000` danger · `#5A0000` sensed smudge · pulse arc `#FFFFFF` α0.85. No other hues. Colour-blind mode: danger rendered as white outline + 45° hatch fill (shader flag), smudge as grey hatch.
