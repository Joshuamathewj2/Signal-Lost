# SIGNAL LOST — Level Design & Campaign Specification (V2)

- **Purpose**: Authoritative architectural design guidelines, automated validator specifications, and complete level walkthrough sheets with ASCII grid maps for Levels 1 through 9.
- **Audience**: Level Designers, System Architects, AI Coding Agents.
- **Status**: Approved.
- **Last Updated**: 2026-10-12.
- **Depends On**: [00_CURRENT_STATE_AUDIT.md](file:///c:/vibe-game/docs/00_CURRENT_STATE_AUDIT.md), [GDD.md](file:///c:/vibe-game/docs/GDD.md), [GAME_CONFIG_REFERENCE.md](file:///c:/vibe-game/docs/GAME_CONFIG_REFERENCE.md).

---

## 1. Architectural Metrics & Traversal Rules

All levels are built on a discrete 32×32 px tile grid and must strictly adhere to the physical locomotion capabilities of the hero:

| Traversal Metric | Tile Metric | Pixel Metric | Hard Rule |
|---|---|---|---|
| **Maximum Jump Height** | 2.7 tiles | 87 px apex | The hero clears **2-tile vertical steps**. A 3-tile ledge requires an intermediate platform, wall-kick, or ladder. |
| **Maximum Horizontal Gap** | 3.5 tiles | 112 px | Platform gaps must not exceed **3 empty tiles** without a sprint run-up. |
| **Drop-Through Catwalk** | 1.0 tile | 32 px | One-way platforms (`=`) allow dropping down via `sneak + jump` within 0.20s. |
| **Vertical Drop Limit** | $\le 8$ tiles | 256 px | Drops $> 8$ tiles without intermediate ledges risk disorientation in darkness. |
| **Ceiling Clearance** | 2.0 tiles | 64 px | Corridors must be at least 2 tiles tall for hero clearance (crouched: 1.5 tiles). |
| **Screen Scale** | 3 to 6 screens wide | 1920–3840 px | Levels scale 36 to 48 tiles wide, 20 to 32 tiles tall, filling the screen vertically. |
| **Camera Framing** | 1.8x base zoom | 48 px look-ahead | Viewport displays 2–3 vertical tiers simultaneously; never leaves empty void borders. |

### 1.1 The Golden Return Rule (Zero Soft-Locks)
**Rule**: *Every downward drop into a lower chamber or corridor must possess an associated return path.*
- If the player drops through a one-way catwalk or shaft, there must be a climbable wall-jump shaft, ladder, lift, or unlocked return gate.
- Under no circumstances may collecting a key or dropping down leave the player unable to re-ascend. This explicitly resolves the V1 Level 3 stacked-corridor defect.

---

## 2. Level Validator Specification (`LevelValidator.gd`)

Before any level is compiled into the release build, the automated `LevelValidator` runs offline in CI and on engine startup in debug builds. It asserts the following requirements:

1. **Dimensional Integrity**: Width $W \in [36, 48]$, Height $H \in [18, 32]$. All rows must have identical string length.
2. **Solid Border Closure**: All boundary cells (`(0, r)`, `(W-1, r)`, `(c, 0)`, `(c, H-1)`) must be solid `#`.
3. **Cardinal Entities**: Exactly one Player Spawn `P` and exactly one Exit Terminal `E`.
4. **Spawn Buffer**: No hostile enemy (`L`, `A`, `K`, `Y`, `B`, `S`) may spawn within 5 tiles (Manhattan distance) of `P`.
5. **Vertical Door Alignment**: All doors (`D`, `R`, `>`, `<`) must occur in vertical runs of exactly 2 tiles.
6. **Acoustic Vent Pairing**: Count of vent intakes `V` must exactly equal count of vent outlets `v`.
7. **Simulated Reachability on Directed `PlatformGraph`**:
   - The validator constructs the directed A* graph.
   - It performs a pathfinding simulation from `P` to `E`.
   - Keys (`K`) dynamically unlock paired doors (`D`), and pressure plates (`_`) unlock linked doors (`R`).
   - If no valid path from `P` to `E` exists taking jump apex (2.7 tiles) into account, validation **FAILS** with code 1.
8. **Bidirectional Return Verification**:
   - For every standable sub-region reached by dropping down, the validator verifies that a return path exists to prior key locations.

---

## 3. Campaign Master Roster (Levels 1 to 9)

```
Level 1: Wake ────────► Level 2: Acoustic Bay ────► Level 3: Iron Tier
(Basic Locomotion)       (Ashigaru & Katana)          (Vertical Shafts & Naginata)
       │
       ▼
Level 4: Glass Foundry ─► Level 5: Resonance Deep ──► Level 6: Ventilation Vault
(Scream & Shatter)       (Echo Glyphs & Kunai)        (Vent Acoustics & Decoys)
       │
       ▼
Level 7: The Great Seal ─► Level 8: Redoubt Gate ────► Level 9: Shogun Citadel
(Multi-Node Cryptography)(Mixed Crossfire Combat)     (3-Phase Boss Climax)
```

---

## 4. Detailed Level Specifications

### Level 1: Sub-Level 0 — Wake
- **Purpose & The ONE New Idea**: Introduce darkness, basic locomotion, Whisper/Normal pulse charging, and collecting Signal Fragments.
- **Enemies**: None (Peaceful infiltration).
- **Difficulty**: 1/10 | **Target Time**: 1:30 | **Size**: 38 × 18 tiles.
- **Intended Solution Path**:
  1. Spawn at `P`. Move right in darkness; hold `Space` to emit Whisper pulse, revealing initial catwalks.
  2. Jump across 2-tile gap to reach elevated ledge with Signal Fragment `F`.
  3. Emit Normal pulse to reveal Exit Terminal `E` across a low drop. Touch `E` to complete sector.
- **ASCII Map**:
```text
;name=Wake
;decoys=0
;seed=101
;music=calm
;hint_0=HOLD [SPACE] TO EMIT SONAR
######################################
#....................................#
#....................................#
#....................................#
#........................F...........#
#.....................=======........#
#....................................#
#.................###................#
#.P...?....###....###.............E..#
######################################
```

---

### Level 2: Acoustic Bay
- **Purpose & The ONE New Idea**: Introduce the **Ashigaru Spearman**, Katana slashes, and noise discipline (Whisper is safe; Normal triggers investigation).
- **Enemies**: 2 Ashigaru (`A`).
- **Difficulty**: 2/10 | **Target Time**: 2:30 | **Size**: 40 × 20 tiles.
- **Intended Solution Path**:
  1. Spawn at `P`. Crouch-sneak past upper catwalk while Ashigaru patrols below.
  2. Use Whisper pulses to navigate without alerting the spearman.
  3. Execute stealth assassination from behind or engage in Katana duel using parry deflect.
  4. Collect Keycard `K` to slide open door `D` guarding Exit `E`.
- **ASCII Map**:
```text
;name=Acoustic Bay
;decoys=0
;seed=202
;music=calm
;hint_0=WHISPER IS SILENT. NORMAL IS HEARD.
########################################
#......................................#
#......................................#
#..P...................................#
#=========...........==========........#
#........#...........#........#........#
#........#.....A.....#........#...D.E..#
#........#...........#...K....#...D....#
########################################
```

---

### Level 3: Iron Tier (The Vertical Refactor)
- **Purpose & The ONE New Idea**: **Unlock Naginata**. Multi-tier vertical descent with guaranteed return ladders and wall-jump shafts (fixes V1 soft-lock).
- **Enemies**: 2 Ashigaru (`A`), 1 Kenshi (`K_E`).
- **Difficulty**: 3/10 | **Target Time**: 3:30 | **Size**: 40 × 22 tiles.
- **Intended Solution Path**:
  1. Spawn at `P` on top floor. Drop down through catwalk `=` into central tier.
  2. Defeat Kenshi to unlock the **Naginata** shrine (`W_N`).
  3. Use long Naginata thrust to hit high overhead release latch, dropping a return ladder `H` connecting bottom to top tier.
  4. Collect Keycard `K`, climb return ladder `H`, and unlock blast door `D` leading to Exit `E`.
- **ASCII Map**:
```text
;name=Iron Tier
;decoys=0
;seed=303
;music=calm
########################################
#P...................................E.#
#....................................D.#
#....................................D.#
###############=======##################
#.............#.......#................#
#......A......#..W_N..#.......A........#
#.............#.......#................#
########=======#######=======###########
#......#.....................#.........#
#..K...#.........K_E.........#.........#
#......#.....................#.........#
########################################
```

---

### Level 4: Glass Foundry
- **Purpose & The ONE New Idea**: Introduce the **Scream Pulse**, breakable glass floors (`G`), and the **Oni Brute** (`B`).
- **Enemies**: 1 Oni Brute (`B`), 1 Sentry (`S`).
- **Difficulty**: 4/10 | **Target Time**: 4:00 | **Size**: 42 × 22 tiles.
- **Intended Solution Path**:
  1. Spawn at `P`. Turret `S` pins down upper walkway.
  2. Emit full **Scream pulse** to shatter glass catwalk `G`, dropping the Oni Brute into an isolated lower sub-pit.
  3. Crouch-sneak along lower beams to flank the Sentry from below, deflecting its laser bolt with Katana parry.
  4. Reach Exit `E` across the foundry floor.
- **ASCII Map**:
```text
;name=Glass Foundry
;decoys=0
;seed=404
;music=tense
##########################################
#P......................S..............E.#
#......................###...............#
#......GGGGGGGGGGGGGGGGGG................#
#......#................#................#
#......#.......B........#................#
#......#................#................#
##########################################
```

---

### Level 5: Resonance Deep
- **Purpose & The ONE New Idea**: **Unlock Twin Kunai**. Introduce **Echo Glyphs** and **Resonance Panels** (`R_P`).
- **Enemies**: 2 Ashigaru (`A`), 1 Yumi Archer (`Y`).
- **Difficulty**: 5/10 | **Target Time**: 4:30 | **Size**: 44 × 24 tiles.
- **Intended Solution Path**:
  1. Equip Twin Kunai for silent wall-cling exploration.
  2. Emit Whisper pulse near Echo Glyph to read the acoustic chime frequency.
  3. Strike Resonance Panel `R_P` with Kunai dash to harmonize the bulkhead lock.
  4. Evade Yumi archer arrows using dash i-frames and reach Exit `E`.
- **ASCII Map**:
```text
;name=Resonance Deep
;decoys=1
;seed=505
;music=calm
############################################
#P.................Y.......................#
#.................===......................#
#..........................................#
#......R_P........................D......E.#
#......###........................D........#
#............A............A.......##########
############################################
```

---

### Level 6: Ventilation Vault
- **Purpose & The ONE New Idea**: Acoustic manipulation using paired vents (`V` intake, `v` outlet) and thrown **Decoy Beacons** (`C`).
- **Enemies**: 1 Hunter (`H`), 1 Sentry (`S`).
- **Difficulty**: 6/10 | **Target Time**: 5:00 | **Size**: 44 × 24 tiles.
- **Intended Solution Path**:
  1. Hunter stalker patrols central chamber with sharp acoustic memory.
  2. Throw Decoy Beacon into Vent Intake `V`; sound amplifies and erupts from Outlet `v` on far right balcony.
  3. Hunter charges remote lure, clearing central gantry for the player to slip through to Terminal `E`.
- **ASCII Map**:
```text
;name=Ventilation Vault
;decoys=2
;seed=606
;music=tense
############################################
#P.........V....................v........E.#
#........................................#.#
#..................H.....................#.#
#..........=====================.........#.#
#..........#...................#.........#.#
#..........#.........S.........#.........#.#
############################################
```

---

### Level 7: The Great Seal
- **Purpose & The ONE New Idea**: Multi-room escape-room puzzle with dual **Seal Locks** (`S_L`) and harmonic lanterns (`~`).
- **Enemies**: 2 Kenshi (`K_E`), 1 Yumi (`Y`), 1 Oni Brute (`B`).
- **Difficulty**: 7/10 | **Target Time**: 5:30 | **Size**: 46 × 26 tiles.
- **Intended Solution Path**:
  1. Sector split into West and East wings by a heavy blast seal.
  2. West Wing: Strike 3 harmonic lanterns in descending pitch order within 8.0s to release Seal Lock Alpha.
  3. East Wing: Lure Oni Brute onto pressure plate `_` while dodging Yumi sniper arrows to release Seal Lock Beta.
  4. Both seals disengage, opening grand blast gate to Exit `E`.
- **ASCII Map**:
```text
;name=The Great Seal
;decoys=1
;seed=707
;music=tense
##############################################
#P.........~...~...~.........Y.............E.#
#..........=========........===............D.#
#..........................................D.#
#...S_L_1.............S_L_2................#.#
#...#####.............#####................#.#
#..........K_E.................B....._.....#.#
##############################################
```

---

### Level 8: Redoubt Perimeter
- **Purpose & The ONE New Idea**: Tactical combat arena combining all enemy archetypes in a defensive fortress.
- **Enemies**: 2 Ashigaru (`A`), 1 Kenshi (`K_E`), 1 Yumi (`Y`), 1 Sentry (`S`), 1 Brute (`B`).
- **Difficulty**: 8/10 | **Target Time**: 6:00 | **Size**: 48 × 28 tiles.
- **Intended Solution Path**:
  1. Multi-level fortress requiring weapon swaps: Naginata to pierce Ashigaru lines, Kunai to assassinate Yumi snipers, Katana to deflect Sentry plasma bolts.
  2. Coordinate attack tokens to isolate and eliminate guards in silence before triggering final terminal.
- **ASCII Map**:
```text
;name=Redoubt Perimeter
;decoys=2
;seed=808
;music=tense
################################################
#P....................Y......................E.#
#....................===.....................#.#
#.........S........................S.........#.#
#........###......................###........#.#
#...............A............A...............#.#
#...............#...K_E......#...............#.#
#.......B.......#............#.......B.......#.#
################################################
```

---

### Level 9: Shogun Citadel (The Final Climax)
- **Purpose & The ONE New Idea**: Grand 3-phase arena boss showdown against the **Shogun Mech** (`BOSS`).
- **Enemies**: Shogun Mech Boss (`BOSS`).
- **Difficulty**: 10/10 | **Target Time**: 7:00 | **Size**: 48 × 30 tiles.
- **Intended Solution Path**:
  1. Enter grand throne hall; arena gates lock behind player.
  2. **Phase 1 (100%–66% HP)**: Master parrying twin Naginata sweeps; strike during recovery.
  3. **Phase 2 (66%–33% HP)**: Dodge arena-wide acoustic shockwaves; eliminate summoned Ashigaru adds.
  4. **Phase 3 (33%–0% HP)**: Total blackout duel; track Mech by blade gleams and blade clashing sparks; execute final lethal poise finisher on Terminal `E`.
- **ASCII Map**:
```text
;name=Shogun Citadel
;decoys=3
;seed=909
;music=boss
################################################
#..............................................#
#..............................................#
#P...........................................E.#
#==============================================#
#..............................................#
#....................BOSS......................#
#..............................................#
#.........GGGGGGGGGGGGGGGGGGGGGGGGGG...........#
#.........#........................#...........#
#.........#........................#...........#
################################################
```
