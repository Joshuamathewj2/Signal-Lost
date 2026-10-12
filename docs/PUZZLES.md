# SIGNAL LOST — Escape-Room Puzzles & Lore Specification (V2)

- **Purpose**: Comprehensive technical and design specification for the escape-room puzzle toolbox, `PuzzleController` architecture, level puzzle sheets, atmospheric lore fragments, and automated solution verification bots.
- **Audience**: Puzzle Designers, System Architects, Gameplay Programmers, AI Coding Agents.
- **Status**: Approved.
- **Last Updated**: 2026-10-12.
- **Depends On**: [00_CURRENT_STATE_AUDIT.md](file:///c:/vibe-game/docs/00_CURRENT_STATE_AUDIT.md), [LEVEL_DESIGN_V2.md](file:///c:/vibe-game/docs/LEVEL_DESIGN_V2.md).

---

## 1. The Escape-Room Puzzle Toolbox

SIGNAL LOST V2 layers environmental mystery over stealth platforming. Puzzles are not separate minigames; they are physical entities woven into the world and unlocked through acoustics and combat tools:

| Puzzle Tool | Visual Representation | Interaction Rules | Acoustic / Noise Impact | Failure Penalty |
|---|---|---|---|---|
| **Echo Glyphs** | Ancient wall runes etched in stone. | Invisible until struck by a specific pulse tier: Whisper reveals cyan glyph, Normal reveals white, Scream reveals red. | Zero extra noise; consumes pulse energy. | Wrong tier shows blurred gibberish. |
| **Resonance Panels** | Heavy acoustic tuning bulkheads with vibrating reeds. | Must be struck by a matching acoustic frequency (e.g., Whisper wavefront or Naginata strike). | Emits resonant chime ($r=160 \text{ px}$ noise). | Wrong frequency locks panel for 3.0s. |
| **Seal Locks** | Multi-node magnetic blast gates. | Requires satisfying 2 or 3 remote conditions (e.g., dual keys or simultaneous plate triggers). | Loud hydraulic release ($r=280 \text{ px}$ noise). | Gate remains sealed. |
| **Harmonic Lanterns** | Hanging bronze lanterns tuned to musical pitches. | Must be struck with weapons in precise sequential order within an 8.0s timer. | Each strike rings out ($r=96 \text{ px}$ noise). | Sequence resets; rings alarm chime alerting guards. |
| **Cryptographic Keys** | Floating illuminated micro-cylinders. | Physical collection enables paired blast doors. | Collection plays chime ($r=40 \text{ px}$ noise). | Doors remain impenetrable. |
| **Hidden Passages** | Crumbly false walls / fragile vents. | Revealed by Scream shockwaves or breakable by heavy Naginata thrusts. | Breaking emits shatter ($r=360 \text{ px}$ noise). | Remains solid. |
| **Signal Fragments** | Floating holographic data cubes. | Optional collectibles (0 to 3 per level) holding lore and weapon upgrades. | Pickup emits brief chime. | Missed upgrade points. |
| **Emergency Exit Beacon**| In-world acoustic homing ping. | Press `H` to emit directional acoustic arrow pointing towards Exit Terminal `E`. | Generates $120 \text{ px}$ local noise on `NoiseBus`. Cooldown 5.0s. | Alerts nearby guards. |

---

## 2. Technical Architecture: `PuzzleController` & `Interactable`

### 2.1 Node Hierarchy
```
PuzzleController (Node) [puzzle_controller.gd]
├── Nodes: Array[NodePath] (References to puzzle elements: panels, lanterns, doors)
├── TargetDoor: Door (Blast door to unlock upon completion)
└── Solved: bool = false
```

### 2.2 Reusable State Contract
All puzzle objects extend `Interactable` and implement the following standardized lifecycle:
```gdscript
class_name PuzzleElement
extends Interactable

signal state_changed(element: PuzzleElement, is_active: bool)

@export var required_tier: int = 1 # 0: Whisper, 1: Normal, 2: Scream
@export var sequence_index: int = 0
var is_triggered: bool = false

func on_wavefront(profile: PulseProfile, origin: Vector2) -> void:
    if profile.tier == required_tier and not is_triggered:
        trigger()

func on_hit(hitbox: HitboxComponent) -> void:
    trigger()

func trigger() -> void:
    is_triggered = true
    state_changed.emit(self, true)
```

---

## 3. Level Puzzle Sheets (Levels 1 to 9)

### Level 1: Sub-Level 0 — Wake
- **Puzzle Goal**: Learn to locate the hidden Signal Fragment.
- **Clue Location**: In-world hint sign `?` near spawn reads: `HOLD [SPACE] TO REVEAL SECRETS`.
- **Solution Steps**:
  1. Jump onto first platform.
  2. Emit Whisper pulse; notice faint glowing outline of catwalk above.
  3. Wall-jump up to claim Fragment `F_1`.
- **Failure Penalty**: None (introductory). | **Expected Time**: 1:30.

### Level 2: Acoustic Bay
- **Puzzle Goal**: Retrieve Keycard `K` behind a sleeping Ashigaru patrol.
- **Clue Location**: Echo glyph on ceiling depicts an arrow pointing through a low crawlspace.
- **Solution Steps**:
  1. Hold `Shift` to crouch-sneak under the gantry without generating footstep noise.
  2. Pick up Keycard `K` silently.
  3. Slip back to unlock blast door `D`.
- **Failure Penalty**: Footsteps alert Ashigaru into immediate combat. | **Expected Time**: 2:30.

### Level 3: Iron Tier
- **Puzzle Goal**: Restore vertical ladder access and solve the multi-floor shaft.
- **Clue Location**: Echo glyph on middle wall shows a spear thrust hitting an overhead counterweight.
- **Solution Steps**:
  1. Defeat Kenshi to claim Naginata.
  2. Stand on middle platform; aim heavy Naginata thrust upwards to strike overhead latch.
  3. Counterweight drops ladder `H`, providing permanent vertical return path from bottom to top tier.
- **Failure Penalty**: Latch remains un-hit; player must explore for alternative path. | **Expected Time**: 3:30.

### Level 4: Glass Foundry
- **Puzzle Goal**: Trap the invulnerable Oni Brute on fragile glass.
- **Clue Location**: Terminal log: `STRUCTURAL INTEGRITY OF FOUNDRY GLASS: VULNERABLE TO ACOUSTIC SCREAM.`
- **Solution Steps**:
  1. Lure Oni Brute onto central glass bridge `G`.
  2. Jump back onto solid stone; charge full Scream pulse ($t \ge 1.0s$).
  3. Release Scream: shockwave shatters glass `G`, plunging Brute into deep disposal pit.
- **Failure Penalty**: If player remains on glass during Scream, player falls and dies. | **Expected Time**: 4:00.

### Level 5: Resonance Deep
- **Puzzle Goal**: Harmonize the dual Resonance Panels to open the Vault.
- **Clue Location**: Cyan Echo Glyph on left wall indicates Whisper chime; white glyph indicates Normal chime.
- **Solution Steps**:
  1. Emit Whisper pulse at Panel Alpha on left gantry.
  2. Dash across to Panel Beta within 6.0s and strike it with Kunai.
  3. Vault blast door disengages.
- **Failure Penalty**: Timer expires; panels reset with a loud warning buzz. | **Expected Time**: 4:30.

### Level 6: Ventilation Vault
- **Puzzle Goal**: Redirect acoustic decoy pulse through air ducts to distract the Hunter.
- **Clue Location**: Vent intake `V` has illuminated flow arrows pointing towards far-side outlet `v`.
- **Solution Steps**:
  1. Stand 3 tiles away from Intake `V`.
  2. Throw Decoy Beacon (`F` key) directly into vent opening.
  3. Sound emerges from Outlet `v` on far right, drawing Hunter away from Exit Terminal `E`.
- **Failure Penalty**: Throwing decoy in open room lures Hunter directly to player. | **Expected Time**: 5:00.

### Level 7: The Great Seal
- **Puzzle Goal**: Execute the 3-Harmonic Lantern Sequence.
- **Clue Location**: Echo Glyphs depict 3 musical notes of descending size: Large -> Medium -> Small.
- **Solution Steps**:
  1. Strike Lantern 1 (Pitch High) with Katana slash.
  2. Jump to Lantern 2 (Pitch Mid) and strike with Kunai.
  3. Vault to Lantern 3 (Pitch Low) and strike with Naginata thrust within 8.0s total.
- **Failure Penalty**: Sequence resets; all lanterns swing violently, alerting 2 guards. | **Expected Time**: 5:30.

### Level 8: Redoubt Perimeter
- **Puzzle Goal**: Synchronized dual pressure plate bypass.
- **Clue Location**: Broken circuit line between Plate Alpha and Plate Beta.
- **Solution Steps**:
  1. Lure patrolling Brute to step onto Plate Alpha.
  2. Dash across to Plate Beta and stand on it simultaneously.
  3. Fortress blast gate lowers permanently.
- **Failure Penalty**: Brute leaves plate before player reaches Beta; gate closes. | **Expected Time**: 6:00.

### Level 9: Shogun Citadel
- **Puzzle Goal**: Blackout resonance override during boss Phase 3.
- **Clue Location**: Core terminal flashes: `STRIKE RESONANCE CORES DURING BLADE CLASH.`
- **Solution Steps**:
  1. When Shogun Mech initiates Berserk Flurry, parry 3 consecutive strikes.
  2. Deflection sparks illuminate twin ceiling resonance coils.
  3. Throw Kunai into both coils to disable Mech's shields and expose core.
- **Failure Penalty**: Mech completes flurry, dealing 2 segments damage. | **Expected Time**: 7:00.

---

## 4. Atmospheric Lore Fragments (Found in Terminals & Data Cubes)

Each fragment consists of 2–3 evocative lines delivering environmental narrative and mechanical hints:

- **Fragment 01 (Sub-Level 0)**:
  > *"Optical sensors severed during the 3rd Purge. Only the acoustic nerves remain. The dark is not empty; it is merely waiting for a voice."*
- **Fragment 02 (Acoustic Bay)**:
  > *"The Ashigaru walk on iron heels. They do not look for shadows—they listen for the displacement of air. Walk as the mist does."*
- **Fragment 03 (Iron Tier)**:
  > *"The Naginata was forged for the high catwalks. Where the short blade falls short, the spear touches the ceiling weights."*
- **Fragment 04 (Glass Foundry)**:
  > *"Silicon lattices degrade under harmonic resonance. A true scream does not merely reveal; it shatters what is brittle."*
- **Fragment 05 (Resonance Deep)**:
  > *"Twin reeds, twin frequencies. Sound is a key that must be turned with both hands before the echo fades."*
- **Fragment 06 (Ventilation Vault)**:
  > *"The ventilation ducts were the lungs of the facility. Now they are acoustic trumpets. What enters a whisper exits a roar."*
- **Fragment 07 (The Great Seal)**:
  > *"Three bells hung in the darkness. High, middle, low. The descending scale opens the tomb; the ascending scale brings the hunters."*
- **Fragment 08 (Redoubt Perimeter)**:
  > *"The Shogunate automated its honor when its flesh turned to dust. The machine remembers only the law of the perimeter."*
- **Fragment 09 (The Core Citadel)**:
  > *"In the center sits Cipher-Prime. It sleeps with open auditory receptors. To wake it is to duel the very architecture of the facility."*

---

## 5. Automated Solution-Bot Specification (`SolutionBot.gd`)

To guarantee in continuous automated testing that every level puzzle is 100% solvable:
1. **Headless Graph Traversal**: `SolutionBot` loads `LevelData` and executes a deterministic state-action sequence.
2. **Action Script**: Defines exact inputs per map:
   - Level 2: `[Sneak(3.0s), CollectKey(pos), UnlockDoor(pos)]`.
   - Level 3: `[DefeatKenshi, StrikeLatch(pos), ClimbLadder, Exit]`.
   - Level 5: `[WhisperPanel(pos_a), Dash, StrikePanel(pos_b), Exit]`.
3. **Assertion**: Solution-bot asserts that executing the recorded sequence transitions `GameState.is_level_active` to `false` and fires `level_completed` with `stats.medal == &"ghost"` in $< 500$ simulation ticks.
