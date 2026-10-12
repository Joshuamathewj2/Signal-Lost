# SIGNAL LOST — Game Design Document (V2 Specification)

- **Purpose**: Authoritative creative design specification for SIGNAL LOST V2, establishing design pillars, player fantasy, core game loop, combat-sonar mechanics, progression, and narrative tone.
- **Audience**: Game Designers, Producers, Gameplay Programmers, AI Coding Agents.
- **Status**: Approved.
- **Last Updated**: 2026-10-11.
- **Depends On**: [00_CURRENT_STATE_AUDIT.md](file:///c:/vibe-game/docs/00_CURRENT_STATE_AUDIT.md), [README_INDEX.md](file:///c:/vibe-game/docs/README_INDEX.md).

---

## 1. Vision Statement & Player Fantasy

> *"You are a blind, master cybernetic samurai stranded within a collapsed subterranean megalopolis. The world is drowned in pitch darkness. You perceive reality solely through acoustic pulses and steel echoes. Every blade strike, every footstep, and every sonar call reveals your surroundings—but the hunting machines hear every sound. To see is to be hunted. To strike is to reveal your heart."*

**The Player Fantasy**: The player embodies a lethal, calculating ronin navigating a lethal high-tech labyrinth. You do not stumble blindly through darkness; you command sound as both weapon and sight. You stalk patrol drones from shadows, visualize rooms through razor-sharp acoustic reflections, deflect bullets in absolute dark by sound cues alone, and execute precision strikes before slipping back into silence.

---

## 2. The Five Design Pillars

Every mechanical system, level layout, and tuning variable must directly serve these five pillars.

### Pillar 1: Acoustic Asymmetry (Seeing is Exposure)
- **What We Do**: Visual perception is strictly tied to active acoustic emission. Pitch blackness is total safety; illumination is active vulnerability. We force the player to make constant tactical gambles between clarity and concealment.
- **What We Refuse**: We refuse permanent environmental illumination, continuous mini-maps, x-ray vision overlays, or passive flashlight cones that give unearned visual awareness.

### Pillar 2: High-Lethality Tactical Combat (Deliberate Blades)
- **What We Do**: Combat is swift, weighty, and punishing. Blade clashes produce violent noise that ripples across the sector. Parries reward split-second timing; poise breaks enable decisive finishers. Attacks require deliberate commitment with clear startup and recovery windows.
- **What We Refuse**: We refuse button-mashing brawling, damage-sponge enemies, endless juggle combos, or hit trading where the player mindlessly spams attacks through enemy strikes.

### Pillar 3: Vertical Escape-Room Architecture (Spatial Puzzles)
- **What We Do**: Levels are multi-tier vertical environments filled with interconnected passages, seal locks, resonance panels, and acoustic vents. Progression requires reading the environment, deducing combinations, and manipulating sound to unlock blast doors.
- **What We Refuse**: We refuse flat linear corridors, brainless key-hunt fetch quests, or puzzle dead-ends that permanently soft-lock the player without clear escape or return routes.

### Pillar 4: Pure Aesthetic Legibility (The Tri-Color Canvas)
- **What We Do**: The game renders exclusively in a high-contrast tri-color palette: Pure Black (`#000000`), Razor White (`#FFFFFF`), and Blood Red (`#E00000`). Silhouettes are sharp, bold, and instantly identifiable at a glance across screen distances.
- **What We Refuse**: We refuse muddy textures, visual clutter, ambient grey fog, decorative visual noise that obscures mechanical hitboxes, or colors outside the tri-color spectrum.

### Pillar 5: Fair, Predictable Determinism (Respect the Player)
- **What We Do**: Every enemy attack is distinctly telegraphed visually and acoustically. Enemy hearing follows deterministic raycast physics without random dice rolls. AI respects concurrency limits (maximum 2 simultaneous attackers via attack tokens).
- **What We Refuse**: We refuse off-screen cheap deaths, instant un-telegraphed sniper shots, arbitrary enemy respawns behind the player, or unpredictable physics bugs.

---

## 3. Core Loops

### 3.1 Moment-to-Moment Loop (Seconds)
```
  [DARKNESS] -> Assess audio cues / memory
      │
  [PULSE / STRIKE] -> Reveal local geometry + emit acoustic wavefront
      │
  [EVALUATE] -> Identify enemy positions, sight cones, and platforms
      │
  [EXECUTE] -> Sneak, parry, strike, or evade into safe shadow
```

### 3.2 Room-to-Room Loop (Minutes)
1. Enter an unrevealed sector in pitch darkness.
2. Emit a low-tier **Whisper** to locate footholds and nearby patrol sentries without alerting them.
3. Solve local tactical obstacles: assassinate an isolated guard, lure a brute into breakable glass, or trigger a resonance panel.
4. Unlock vertical access points (catwalk drops, wall-jump shafts, or elevator lifts) to reach higher tiers.

### 3.3 Level-to-Level Loop (3 to 7 Minutes)
1. Infiltrate sector start (`P`).
2. Explore branches to discover hidden **Signal Fragments** (`F`) and weapon upgrade shrines.
3. Decipher the sector's central **Escape-Room Puzzle** (e.g., resonance sequence, seal locks).
4. Confront sector gatekeeper or ambush encounter.
5. Reach the **Exit Terminal** (`E`), triggering the "SIGNAL RESTORED" sequence.
6. Review performance medals (**Ghost**, **Quiet**, **Loud**) and unlock subsequent campaign sectors.

### 3.4 Full-Game Progression Loop (Entire Campaign)
1. **Levels 1–3 (The Awakening)**: Master basic locomotion, Katana slashes, Whisper/Normal pulses, and simple keycard gates.
2. **Levels 4–6 (The Arsenal)**: Unlock the **Naginata** (long-range thrusts, lantern triggers) and **Twin Kunai** (rapid dashes, stealth assassinations). Confront heavy Oni Brutes and Sentry nests.
3. **Levels 7–8 (The Infiltration)**: Overcome complex escape-room seal locks, vent networks, and multi-tier enemy crossfires.
4. **Level 9 (The Core Citadel)**: Multi-stage climatic showdown against the **Shogun Mech**, combining all combat, sonar, and puzzle mechanics into a master test of skill.

---

## 4. The Unique Interlock: Sonar + Noise + Combat

The defining innovation of SIGNAL LOST is the triangular mechanical coupling between **Sight**, **Sound**, and **Violence**:

```
                       [ COMBAT ACTION ]
                      (Slash / Parry / Hit)
                           ▲         │
                          ╱           │ Emits Loud Combat Noise
      Provides Target    ╱             │ (Radius: 180 - 450 px)
      Position & Angle  ╱               ▼
                       ╱           [ NOISE BUS ]
                      │           (Acoustic Physics)
                      │                 │
     Illuminates      │                 │ Alerts Nearby Enemies
     Entities         │                 │ to Investigate
                      │                 ▼
                 [ SONAR REVEAL ] ◄─── [ ENEMY ALERT ]
             (Expanding Wavefront)    (FSM State Transition)
```

1. **Every Combat Action is an Acoustic Beacon**:
   - A light Katana slash emits a 180 px noise ring.
   - A heavy Naginata thrust emits a 320 px noise ring.
   - A successful parry spark emits a sharp 260 px acoustic crack.
   - Engaging one enemy in close combat automatically alerts any guard within earshot unless executed in a sound-damped **Mute Zone**.
2. **Violence as Vision**:
   - In pure darkness, an attacking enemy is invisible until they step into a sonar bubble or attack.
   - When an enemy attacks, their blade gleam and telegraph flash illuminate their silhouette for 0.4s.
   - Striking an enemy creates an explosive burst of sparks that illuminates surrounding walls for 0.6s. A skilled player can fight purely by the light of their own clashing blades.
3. **The Stealth-Combat Spectrum**:
   - Players are never forced into pure non-lethal stealth or mindless action.
   - You may choose to ghost a level without raising a blade (earning the **Ghost Medal**).
   - Alternatively, you can deliberately ring a heavy lantern or emit a **Scream** pulse to gather guards into a tight choke-point, then ambush them with wide Naginata sweeps.

---

## 5. Difficulty Philosophy & Fairness Guarantees

SIGNAL LOST is designed to be tough, tense, and deeply rewarding—akin to *Sekiro: Shadows Die Twice* meets *Mark of the Ninja*—without unfair frustration:
- **Segmented Health**: The hero has **3 Health Segments** (expandable to 5 via secret fragments). One hit does not mean instant death; single mistakes allow recovery, while consecutive mistakes are fatal.
- **Fair Telegraph Minimums**: No hostile attack can ever hit in less than **18 frames (300 ms)** from telegraph start. Heavy attacks telegraph for **30 to 45 frames (500 to 750 ms)**.
- **Attack Token Concurrency**: Regardless of how many enemies surround the hero, a centralized manager grants a maximum of **2 active attack tokens**. The rest circle, feint, or position for ranged support.
- **Generous I-Frames on Reaction**: A properly timed Dash grants **12 invulnerability frames (200 ms)**. A successful Parry grants **16 frames of invulnerability** and instantly staggers the attacker.

---

## 6. Progression & Arsenal Unlocks

| Level | Sector Name | Unlocked Weapon / Tool | Key Ability / Mechanic |
|---|---|---|---|
| **Level 1** | Sub-Level 0: Wake | **Katana (Single Blade)** | Balanced slash combo, Whisper/Normal pulse. |
| **Level 2** | Acoustic Bay | Shuriken Sub-Weapon | Throw shuriken (`F`) to hit distant switches/distract. |
| **Level 3** | Iron Tier | **Naginata (Spear-Blade)** | Long reach, pierce, vertical ceiling switches. |
| **Level 4** | Glass Foundry | Scream Pulse Overdrive | Heavy shockwave, glass shattering, lantern swings. |
| **Level 5** | Resonance Deep | **Twin Kunai (Dual Daggers)** | Ultra-fast strikes, wall-stick, low noise profile. |
| **Level 6** | Ventilation Vault | Decoy Beacon Tool | Thrown acoustic lure emitting remote Normal pulses. |
| **Level 7** | The Great Seal | Grappling Wire Tool | Vertical ascent, ceiling latching, platform skips. |
| **Level 8** | Redoubt Perimeter | Pulse Resonance Overcharge | Resonate glyphs to trigger sector-wide machinery. |
| **Level 9** | Shogun Citadel | All Weapons & Masteries | Multi-stage boss showdown with the Shogun Mech. |

---

## 7. The Escape-Room Puzzle Layer

SIGNAL LOST V2 elevates level progression from simple navigation to atmospheric environmental puzzles:
1. **Echo Glyphs**: Cryptographic runes etched into ancient walls. Flashing different pulse tiers reveals hidden numerical combinations or directional hints.
2. **Resonance Panels**: Acoustic tuning forks built into bulkhead doors. When struck with matching acoustic frequencies (Whisper, Normal, or blade impact), they chime and unlock.
3. **Harmonic Lanterns**: Puzzles requiring players to strike hanging lanterns in a specific order within a countdown window. Each lantern strike chimes across the sector, creating tactical noise tension.
4. **Directional Blast Gates & Key Seals**: Secure airlocks requiring two distinct cryptographic artifacts hidden in separate wings of the facility.

---

## 8. Narrative Framing & World Lore

Told entirely through minimal environmental fragments, terminal logs, and mechanical styling:
- **The Setting**: Facility 09 ("The Silent Well"), an automated subterranean military research complex sealed three centuries after a catastrophic autonomous weapon war.
- **The Hero (Cipher-0)**: A prototype cybernetic ronin unit reactivated after centuries of sleep. Cipher's optical sensors were destroyed during the initial purge, leaving only auditory acoustic processing arrays intact.
- **The Enemy (The Automated Shogunate)**: The facility's automated defense network, which has mutated over centuries of isolation into a strict feudal hierarchy of tireless drone guardians led by the central autonomous AI core: **The Shogun Mech**.

---

## 9. What This Game Is NOT (Anti-Vision)

To keep scope rock-solid and prevent feature creep:
- **NOT an Open-World Metroidvania**: Levels are discrete, handcrafted challenge sectors (Levels 1–9), not a giant sprawling continuous maze requiring 15 hours of backtracking.
- **NOT an RPG with Stat Grinds**: No XP farming, skill trees with +2% damage increments, weapon crafting, or loot drops. Mastery comes from player skill and weapon properties.
- **NOT a Cover Shooter or Run-and-Gun**: You cannot hide behind chest-high walls and shoot assault rifles. You are an acoustic blade master operating in total shadow.
- **NOT a 3D Game**: 100% 2D side-view physics with strictly planar collision geometry.
