# SIGNAL LOST — Level Design (v1.0)

## 1. Format
File `res://levels/level_XX.txt`, UTF-8, LF. Lines starting with `;` are headers `key=value`. All grid rows must have identical width (≤ 40) and height ≤ 22. Border must be solid `#`. Tile = 32 px. Characters stand on the cell *below* them (an entity char marks the cell its feet occupy).

### Legend
| Char | Meaning | Builder output |
|---|---|---|
| `#` | solid | merged rect: collision (layer 1) + LightOccluder2D + black Polygon2D + exposed-edge lines |
| `=` | one-way platform | StaticBody2D layer 2, one_way_collision, thin top edge line (no occluder) |
| `.` | empty | — |
| `P` | player spawn (exactly 1) | Player |
| `E` | exit terminal (exactly 1) | ExitTerminal |
| `F` | signal fragment (0–3) | Fragment (id = order of appearance) |
| `K` | keycard | Keycard |
| `D` | locked door (vertical run of 2) | Door(mode=KEY) |
| `R` | plate door (vertical run of 2) | Door(mode=PLATE) |
| `_` | pressure plate | PressurePlate |
| `>` `<` | one-way door (vertical run of 2) | OneWayDoor(dir) |
| `G` | glass floor (counts as solid until broken) | GlassFloor (one per cell) |
| `~` | hanging lantern (anchored to ceiling cell above) | Lantern |
| `V` | vent intake | Vent(INTAKE), paired to the i-th `v` in reading order |
| `v` | vent outlet | Vent(OUTLET): re-emits intake noise after 0.2 s with radius `max(r*4, 240)`, loudness +1.5 |
| `M` | mute vent | Vent(MUTE): pulses emitted within 64 px get noise ×0.3 |
| `L` `S` `H` `B` | Listener, Sentry, Hunter, Brute | enemy scenes |
| `|` | invisible patrol bound | consumed by PlatformMover patrol segment calc |
| `C` | decoy pickup | DecoyPickup |
| `?` | hint sign (key glyph shown when lit) | HintSign (text from header `hint_N`) |

Headers: `name`, `decoys` (int), `seed` (int, bg props / edge noise), `music` (calm/tense), `hint_0..n`.

### Auto-generation rules
1. Solids (`#`, plus `G`/doors as separate bodies) → `SolidMerger`: per row, runs of `#`; merge vertically when the run below has identical [start,end]. Each rect → RectangleShape2D + OccluderPolygon2D (closed, cull disabled) + Polygon2D(#000000).
2. Edges: for each `#` cell side whose neighbour is non-solid → segment; collinear segments merged; top segments → rough top line (width 2.5) + specks; others → width 1.5 line.
3. Platform graph: standable cell = non-solid cell whose cell below is `#`, `=`, `G`, or closed door. Edges per ARCHITECTURE §1.
4. Background: `BackgroundBuilder` places silhouette props with `seed`, density ~1 prop / 3 tiles per layer, never in front of foreground (z −10…−30).

## 2. Validation checklist (`level_validator.gd`, run in tests + on load in debug builds)
- [ ] All rows equal width; width ≤ 40, height ≤ 22; border all `#`.
- [ ] Exactly one `P`, exactly one `E`.
- [ ] `P` and every enemy/item cell is non-solid and standable (except `~`, `V`, `v`, `M`, `S`-on-balcony, `F` which may float ≤ 2 cells above a standable cell).
- [ ] Exit reachable from spawn on the platform graph treating `D` doors as open only if a `K` is reachable first, `R` doors open only if a `_` is reachable first, one-way doors directional.
- [ ] Every `D`/`R`/`>`/`<` occupies a vertical run of exactly 2.
- [ ] Count of `V` == count of `v`.
- [ ] No enemy spawn within 5 tiles (Manhattan) of `P`.
- [ ] Fragments reachable (warning, not error).
Failure → push_error with level + cell + rule. **If a map below fails validation, Gemini makes the smallest edit that fixes it and logs it in OPEN_QUESTIONS.md.**

## 3. Difficulty curve
| Lvl | New mechanic | Enemies | Pulse budget hint | Target time | Difficulty (1–10) |
|---|---|---|---|---|---|
| 1 | move/jump/pulse/fragment | 0 | free | 0:30 | 1 |
| 2 | Listener, whisper safety | 1 | whisper | 0:45 | 2 |
| 3 | one-way drops, key + door | 3 L | whisper/normal | 1:15 | 3 |
| 4 | Sentry, projectiles, glass | 1 S, 1 L | no screams | 1:00 | 4 |
| 5 | Brute, plate, lanterns | 1 B | anything (Brute is deaf) | 1:00 | 4 |
| 6 | Hunter, vents | 1 H | lure via vent | 1:15 | 6 |
| 7 | one-way doors, mixed | L, S, B | decoy ×1 | 1:30 | 7 |
| 8 | everything | L, S, H, B | decoy ×2 | 2:00 | 9 |

## 4. Maps

### Level 1 — Wake
Objective: reach the terminal; optional fragment on the catwalk. Teaches movement, step-ups, pulse sizes in a safe room.
```
;name=Level 1
;decoys=0
;seed=101
;music=calm
########################################
#......................................#
#......................................#
#......................................#
#......................................#
#..........................F...........#
#.......................=======........#
#......................................#
#...................###................#
#.P.......###.......###.............E..#
########################################
```
Solution: walk right, hop the 1-high block, jump onto the 2-high block, jump onto the catwalk for F, drop, walk to E. First ever pulse (any) reveals the step; a Scream shows the whole room.

### Level 2 — Listen
Objective: pass a Listener patrolling the floor. Teaches: whisper is safe, Normal is heard; upper catwalks bypass.
```
;name=Level 2
;decoys=0
;seed=202
;music=calm
########################################
#......................................#
#......................................#
#......................................#
#..........F...........................#
#.......===========...=========........#
#......................................#
#...====...............................#
#.P.................L...............E..#
########################################
```
Solution: whisper-step to the low catwalk (cols 4–7), climb to the long catwalk, cross the 3-tile gap, drop near E after the Listener walks left. A Normal pulse on the floor pulls the Listener to you.

### Level 3 — Floors
Objective: get the keycard on the bottom floor, open the door on the middle floor. Teaches drop-through and keys.
```
;name=Level 3
;decoys=0
;seed=303
;music=calm
########################################
#......................................#
#......F...............................#
#......................................#
#.P..................L.................#
################################=======#
#......................................#
#.....D................................#
#.E...D.............L..................#
#############################==========#
#......................................#
#.............................=====....#
#.K................L.................F.#
########################################
```
Solution: sneak past top L, drop through right catwalk to middle, drop again to bottom, whisper-scout, grab K (col 2), return via the small step catwalk and jump up through the middle catwalk, walk left past middle L, open D, reach E.

### Level 4 — Crossfire
Objective: cross under a Sentry balcony. Teaches cover from projectiles and the glass gamble (Scream breaks glass → fragment pit, but alerts the Sentry).
```
;name=Level 4
;decoys=0
;seed=404
;music=tense
########################################
#......................................#
#...............................S......#
#..........................#############
#......................................#
#......................................#
#......................................#
#......................................#
#.........####.........####............#
#......................................#
#.P.....................L.............E#
#############GGGGGG#####################
#############F.....#####################
########################################
```
Solution: whisper only; use overhead blocks as cover (Sentry cone pointed down-left); wait for Listener to turn. Optional: Scream over glass → fall to F, climb out while Sentry fires.

### Level 5 — Heavy
Objective: get past the Deaf Brute and press the plate to open the plate door. Teaches: Brute ignores pulses (Scream freely), but hears running → sneak or jump over / use the catwalk.
```
;name=Level 5
;decoys=0
;seed=505
;music=tense
########################################
#........~.........~...................#
#......................................#
#......................................#
#......................................#
#..............F.......................#
#..........==========...............R..#
#.P..............B......_...........R.E#
########################################
```
Solution: Scream to see everything (Brute doesn't care; lanterns swing beautifully), sneak (silent) onto the catwalk for F, drop behind the Brute while it faces away (land softly — short drop), press `_`, walk to E.

### Level 6 — Pack
Objective: lure the Hunter away with the vent. Teaches vent intake/outlet and mute-vent scouting.
```
;name=Level 6
;decoys=0
;seed=606
;music=tense
########################################
#......................................#
#......................................#
#.P...V...........M....................#
##############################======####
#......................................#
#......................................#
#......................................#
#.F.................v..........H......E#
########################################
```
Solution: Scream next to `M` (noise ×0.3) to scout the lower floor safely; Normal pulse at `V` → amplified roar at `v` (col 20) → Hunter sprints there; run right, drop through cols 30–35, reach E. Optional F needs a second lure.

### Level 7 — Gates
Objective: one-way gates lock commitment; keycard under the Sentry; Brute guards the exit door.
```
;name=Level 7
;decoys=1
;seed=707
;music=tense
########################################
#......................................#
#.................................S....#
#..............................#########
#......................................#
#.......>.................>............#
#.P.....>.........L.......>.......K....#
####################################===#
#......................................#
#.....D................................#
#.E...D..............B.................#
########################################
```
Solution: pass gate 1, decoy to pull the Listener left of gate 2, pass gate 2 (cannot return), take K while the Sentry is quiet, drop at cols 36–38, sneak past the Brute, open D, E.

### Level 8 — Signal
Objective: three floors, all systems.
```
;name=Level 8
;decoys=2
;seed=808
;music=tense
########################################
#.........~..............~.............#
#.P.....M..................S...........#
######GGGG##########################===#
#......................................#
#......................................#
#......................................#
#.F......L............V.......H........#
#===####################################
#......................................#
#..............................R..D....#
#..K.......B........_....v.....R..D..E.#
########################################
```
Solution: scout from M; cross glass with whispers only (Scream drops you onto the Listener); pass the Sentry under its sweep; drop to the middle; decoy right to pull H, sneak left past L; drop cols 1–3; take K; sneak past Brute; plate; door R; door D; E. The V→v lure is a risky alternative (it also pulls H/L down to the bottom floor).

## 5. Placement rules for future levels
- Gaps ≤ 3 tiles, steps ≤ 2 tiles, drops any height (> 4 tiles = hard landing noise).
- Every enemy has a quiet bypass (whisper-only solvable) — required for the Ghost medal.
- Every level shows something beautiful under a Scream (lanterns, parallax, long catwalks).
