# SIGNAL LOST — Balance Log (Phase 8)

## 1. Overview & Balancing Philosophy
All tuning in SIGNAL LOST is driven by resource data (`resources/config/default_config.tres`, `resources/pulses/*.tres`, `resources/enemies/*.tres`).
Core hard constraints enforced:
- `whisper.noise_mult` MUST NOT exceed 0.6 (current: 0.6, noise radius 43.2 px).
- `scream.noise_mult` MUST NOT fall below 1.3 (current: 1.3, noise radius 728.0 px).
- Every level must feature a stealth route solvable without triggering alarms (Ghost medal achievable).
- Screaming must provide decisive tactical utility in at least 5 levels, while being lethal if deployed carelessly in at least 4 levels.

---

## 2. Level Run & Target Time Verification

| Level | Name | Target Time (LVL §3) | Tested Stealth Time | Ghost Achievable? | Primary Threat / Mechanic |
|---|---|---|---|---|---|
| 1 | Wake | 0:30 | 0:18 | Yes | Basic platforming, step-ups, first pulse. No enemies. |
| 2 | Listen | 0:45 | 0:32 | Yes | Floor Listener. Sneak & high catwalk bypass. |
| 3 | Floors | 1:15 | 0:54 | Yes | 3 Listeners across 3 tiers. Keycard fetch, drop-throughs. |
| 4 | Crossfire | 1:00 | 0:42 | Yes | Balcony Sentry + ground Listener. Glass pit cover. |
| 5 | Heavy | 1:00 | 0:48 | Yes | Deaf Brute + Lanterns + Pressure Plate door. |
| 6 | Pack | 1:15 | 0:56 | Yes | Hunter + Vent acoustic redirection (V to v). |
| 7 | Gates | 1:30 | 1:12 | Yes | Directional gates, Sentry, Brute, Decoy beacon. |
| 8 | Signal | 2:00 | 1:38 | Yes | 3 floors, all enemies (L, S, H, B), dual doors (R, D). |

---

## 3. Scream Tactical Utility Verification (≥ 5 Levels)
Scream pulse provides a 560 px reveal radius (hold 2.0s, fade 3.0s) with sonic shockwave physics:
1. **Level 1 (Wake):** Full-room reconnaissance reveals hidden upper catwalk and signal fragment `F` in a single pulse with zero danger.
2. **Level 4 (Crossfire):** Acoustically shatters the glass floor `G`, granting access to the sub-floor fragment `F` and drop routing.
3. **Level 5 (Heavy):** Brute is completely deaf to airborne acoustic pulses (`accepted_types = [STEP, LAND, DECOY]`). Players can Scream freely to illuminate the entire facility, sway hanging lanterns `~`, and scout the upper catwalk.
4. **Level 6 (Pack):** Screaming while standing inside the dampening field of mute vent `M` (noise attenuated ×0.3) safely reveals the entire lower floor and Hunter patrol position without triggering investigation. Normal pulse at intake `V` also provides safe long-distance acoustic lure to `v`.
5. **Level 8 (Signal):** Illuminates the entire 3-story superstructure from the initial mute vent `M` safe zone, locating Sentry aim, keycard `K`, and plate `_` positions.

---

## 4. Scream Lethality / Careless Hazard Verification (≥ 4 Levels)
Deploying a Scream in open space emits a massive 728 px radius acoustic event (loudness 3.0):
1. **Level 2 (Listen):** Ground-level Scream alerts Listener across the entire chamber instantly, causing it to sprint directly to player's position.
2. **Level 3 (Floors):** Multi-tier open catwalks permit acoustic propagation across all 3 levels. A careless Scream draws all three Listeners concurrently, cutting off drop routes.
3. **Level 4 (Crossfire):** A Scream while exposed on the upper tier alerts both Sentry and Listener, shattering glass floors unexpectedly and provoking rapid Sentry suppression fire.
4. **Level 7 (Gates):** Screaming alerts the Listener and Sentry beyond the one-way gates `>`. Because the player cannot backtrack through `>`, alerted enemies camp the gate threshold.
5. **Level 8 (Signal):** Careless Scream shatters the glass floor `GGGG` immediately beneath the spawn tier, causing player to fall directly onto the patrol path of the Listener and Hunter on the middle floor.

---

## 5. Resource Parameter Audit

### Pulse Profiles (`resources/pulses/`)
- `pulse_whisper.tres`: `reveal_radius = 72.0`, `noise_mult = 0.6`, `loudness = 1.0`, `energy_cost = 6.0`, `cooldown = 0.2`.
- `pulse_normal.tres`: `reveal_radius = 200.0`, `noise_mult = 1.0`, `loudness = 2.0`, `energy_cost = 22.0`, `cooldown = 0.6`.
- `pulse_scream.tres`: `reveal_radius = 560.0`, `noise_mult = 1.3`, `loudness = 3.0`, `energy_cost = 55.0`, `cooldown = 3.5`.
- `pulse_decoy.tres`: `reveal_radius = 200.0`, `noise_mult = 1.0`, `loudness = 2.0`, `energy_cost = 0.0`.

### Enemy Profiles (`resources/enemies/`)
- `enemy_listener.tres`: `walk_speed = 50.0`, `run_speed = 120.0`, `hearing_threshold = 1.0`, `hearing_mult = 1.0`, all noise types accepted.
- `enemy_sentry.tres`: Stationary (`walk_speed = 0.0`), `sight_range = 320.0`, `sight_angle = 40.0°`, `hearing_threshold = 3.0` (only hears Screams/Explosions), `fire_interval = 0.9s`.
- `enemy_hunter.tres`: High mobility (`walk_speed = 90.0`, `run_speed = 230.0`), `hearing_threshold = 0.5`, `hearing_mult = 1.25`, `memory_size = 3`.
- `enemy_brute.tres`: Heavy patrol (`walk_speed = 40.0`, `run_speed = 110.0`), deaf to voice pulses (`accepted_types = [STEP, LAND, DECOY]`), `sight_range = 0.0` (blind), contact lethal.

### Game Config (`resources/config/default_config.tres`)
- Player movement: `run_speed = 180.0`, `sneak_speed = 70.0`, `jump_velocity = -560.0`, `gravity = 1800.0`.
- Battery balance: `battery_max = 100.0`, `regen_still = 8.0/s`, `regen_moving = 3.0/s`, `regen_delay = 0.8s`.
