# SIGNAL LOST - Comprehensive Playtest & Verification Checklist

**Game Title:** SIGNAL LOST  
**Engine:** Godot 4.7.2.stable.official (Compatibility / GLSL ES 3.0)  
**Status:** ALL PHASES VERIFIED (0 Failures across 34 Automated Test Suites & Level Validator)  
**Date:** 2026-10-17  

---

## 1. Quick Start & Execution

### Running Headless Automated Test Suites
```powershell
# Run the complete automated test suite (34 test files)
godot --headless --path . -s res://tests/run_tests.gd

# Run the live combat verification suite
godot --headless --path . -s res://tests/test_combat_live.gd

# Run the enemy reaction & AI traversal suite
godot --headless --path . -s res://tests/test_enemy_reactions.gd

# Run the trap mechanics & dual-damage hazard suite
godot --headless --path . -s res://tests/test_traps.gd

# Run the live puzzle verification suite
godot --headless --path . -s res://tests/test_puzzle_live.gd

# Run the automated level validator (all 9 sectors)
godot --headless --path . -s res://tests/level_validator.gd

# Run the 60 FPS performance benchmark at 1920x1080
godot --headless --path . -s res://tests/measure_performance.gd
```

### Running the Live Game
```powershell
# Launch the main game
godot --path . res://scenes/main/main.tscn
```

---

## 2. Complete Controls & Input Mapping

| Action | Primary Key (Keyboard) | Secondary Key | Mouse | Gamepad (Xbox / Standard) | Function / Tactical Effect |
|---|---|---|---|---|---|
| **Move Left** | `A` | `Left Arrow` | — | `D-Pad Left` / `Left Stick Left` | Walk / Run left |
| **Move Right** | `D` | `Right Arrow` | — | `D-Pad Right` / `Left Stick Right` | Walk / Run right |
| **Jump** | `W` | `Up Arrow` | — | `A Button` / `Bottom Face` | Jump (apex 2.7 tiles, variable height) |
| **Crouch / Sneak** | `S` | `Down Arrow` | — | `D-Pad Down` / `Left Stick Down` | Crouch, sneak (0 px noise emitted), drop down one-ways |
| **Dash** | `Shift` | — | — | `Right Trigger` / `Left Bumper` | High-speed horizontal evasion dash |
| **Light Attack / Combo** | `J` | — | `Left Mouse Button` | `X Button` / `West Face` | Katana 3-hit combo, Naginata sweep, Kunai stab |
| **Heavy Attack** | `K` (Tap/Release) | — | — | `Y Button` / `North Face` | Heavy poise-breaking strike (deals 2 poise dmg) |
| **Dash Slash** | `Shift` + `J` | — | `Shift` + `LMB` | `LT` + `X Button` | Invulnerable piercing dash attack (1 DMG, 1.2s CD) |
| **Plunge Strike** | Air: `S` + `J` | — | Air: `S` + `LMB` | Air: `Down` + `X` | Fast aerial dive, 64px ground slam stun wave (2 DMG) |
| **Rising Slash** | `W` + `J` | — | `W` + `LMB` | `Up` + `X Button` | Upward anti-air launcher slash (2 DMG, 35 poise dmg) |
| **Parry / Guard** | `L` | — | `Right Mouse Button` | `Left Trigger` / `B Button` | 6-frame parry window, deflects energy projectiles & trap arrows |
| **Counter Strike (Riposte)**| Parry Deflect + `J`| — | Deflect + `LMB` | Deflect + `X Button`| High-damage lethal riposte (3 DMG, 60 poise dmg) |
| **Cycle Weapon** | `Q` | — | — | `Right Bumper` | Cycles Katana -> Naginata -> Kunai |
| **Subweapon (Shuriken / Kunai)** | `F` | — | — | `D-Pad Up` | Throws distraction star or silent piercing kunai |
| **Decoy Beacon** | `G` | — | — | `D-Pad Right` | Deploys acoustic decoy beacon |
| **Sonar Pulse / Disarm** | `Space` (Hold) | — | — | `Right Stick Click` | Charge Whisper/Normal/Scream; disarms tuned traps |
| **Hint Beacon** | `H` | — | — | `Select / Back` | Emits directional acoustic arrow pointing to Exit |
| **Pause / Menu** | `Escape` | `P` | — | `Start` | Opens pause menu / closes overlays |

---

## 3. Core Mechanics Verification Checklist

### 3.1 Movement & Traversal (Bug A Resolved)
- [x] **Spawn Clearance:** All 9 levels provide $\ge 3$ tiles overhead clearance (Level 1: 8 tiles, Level 2: 9 tiles). No solid blocks trap the player.
- [x] **Horizontal Clearance:** Spawn areas provide $\ge 6$ contiguous open horizontal tiles (Level 1 & 2: 38 tiles).
- [x] **Jump Physics:** Maximum jump apex calibrated to 2.7 tiles. Coyote time (0.1s) and jump buffer (0.1s) confirmed responsive.
- [x] **Sneak & Footsteps:** Sneaking (`S`) emits exactly 0 px noise; walking emits 40 px radius ($L = 0.5$); sprinting emits 80 px radius ($L = 1.0$).
- [x] **Ladders & One-Ways:** Contiguous `H` tiles form climbable ladders; pressing `Down + Jump` drops through one-way `=` platforms.

### 3.2 Combat System (Bug B Resolved)
- [x] **Katana 3-Hit Combo:** Strikes 1 -> 2 -> 3 progress cleanly without state machine animation overrides.
- [x] **Heavy Poise Break:** Heavy strike breaks enemy poise and staggers Brute and Shogun Mech.
- [x] **6-Frame Parry:** Parrying within the active 6-frame window deflects incoming Sentry energy bolts, reflecting them back to destroy the shooter.
- [x] **Weapon Cycling:** Pressing `Q` dynamically swaps between Katana (40 px reach), Naginata (52 px reach), and Kunai (24 px rapid strike). Player rig and HUD badge update immediately.
- [x] **Shuriken Subweapon:** Thrown 4-point star renders with visible unshaded sprite, collides with terrain, and emits a 120 px acoustic distraction lure.
- [x] **Stealth Takedown:** Striking unaware enemies ($awareness < 0.35$) from rear 60° cone executes an instant lethal assassination.
- [x] **Hit-Stop & Visual Juice:** Hits trigger 2–4 frame physics freeze, directional hit sparks, and camera trauma.

### 3.3 Sound & Pulse Puzzle Systems
- [x] **Tier-Selective EchoGlyphs:** Whisper reveals Cyan runes, Normal reveals White runes, Scream reveals Red runes. Mismatched tiers display scrambled gibberish.
- [x] **Resonance Panels:** Match pulse frequency to activate paired blast doors; mismatched frequencies trigger 3.0s lockouts.
- [x] **Harmonic Lanterns:** Striking lanterns in sequential 1 -> 2 -> 3 pitch order within 8.0s unlocks blast gates. Out-of-order strikes trigger sequence resets.
- [x] **Keycards & Doors:** Color-paired keycard pickups register in `GameState` and open paired electronic security doors.
- [x] **Memory Fragments:** 3 fragments placed in every sector; collected fragments persist to `SaveData` bitmasks.
- [x] **Exit Terminal:** Interacting with `E` triggers sector victory evaluation, awards Ghost/Quiet/Loud medals, and unlocks subsequent sectors.

### 3.4 Visuals & Atmospheric Parallax (Bug C Resolved)
- [x] **3-Plane Parallax Architecture:** FarLayer ($z = -30$, scroll $0.25$), MidLayer ($z = -20$, scroll $0.55$), and NearLayer ($z = -10$, scroll $0.80$) render continuous feudal-industrial depth across the entire screen.
- [x] **Feudal-Cyberpunk Vector Silhouettes:** Shoji screen lattices, tower cranes, colossal stone monoliths, steel cross-truss gantries, and distant pagoda skylines.
- [x] **Animated Kinetic Props:** Rotating wall ventilation fans (`FanProp`), billowing steam vents with periodic hiss bursts (`SteamVent`), and swaying catenary cables (`CableProp`).
- [x] **Dynamic Lighting & Shadows:** Hanging lanterns feature organic flickering `PointLight2D` (radius 160 px) casting PCF5 2D shadows from solid walls.
- [x] **Atmospheric Dust Motes:** `DustParticles` drift gently through the facility air volume.
- [x] **Post-Processing Pipeline:** Film grain, screen vignette, and chromatic aberration bursts on scream pulses.

### 3.5 UI, Progression & Menus (Bug D Resolved)
- [x] **Main Menu Bleed-Through Fixed:** Opening Mission Select or Settings completely hides main menu buttons and prevents input bleed-through.
- [x] **Medal Icon Standardization:** Ghost medal is a solid circle with radiant acoustic halo, Quiet is a half-circle, Loud is a hollow circle, and unplayed is `--`.
- [x] **Tutorial HUD Anchoring:** `HintSign` draws in-world holographic beacons and routes tutorial prompts to `HUD.show_tutorial_prompt()` on the CanvasLayer, eliminating platform clipping.
- [x] **Level Select Grid:** Displays level cards with unlocked status, fragment counts ($x/3$), and best medals.
- [x] **Tactical HUD:** Displays active weapon badge (`[Q] KATANA`), segmented health blocks (`HP: [■][■][■]`), shuriken ammo, and battery gauge.

### 3.6 Campaign Progression & Boss Encounter (Bug E Resolved)
- [x] **Sectors 1 to 8:** All sectors fully built, tested, and verified with 0 soft-locks and 100% exit reachability.
- [x] **Sector 9 (Shogun Citadel):** Climax 3-phase boss encounter with Shogun Mech (18 HP segments, 200 Poise):
  - Phase 1: Twin Naginata sweeps and poise defense.
  - Phase 2: Arena-wide acoustic shockwaves and Ashigaru drone summons.
  - Phase 3: Blackout sonic dashes, electrified floor hazards, and berserk 5-hit Overdrive Ronin flurry.

### 3.7 Traps & Hazard System (Steps 4 & 5)
- [x] **10 Trap Archetypes:** Floor Spikes, Ceiling Spikes, Swinging Blade, Wall Blade, Arrow Trap, Spear Launcher, Falling Rock, Rolling Boulder, Guillotine, and Fire Trap.
- [x] **Data-Driven `TrapData`:** Explicit damage, poise damage, cooldown, noise footprint, and frequency parameters across all traps.
- [x] **Readable Danger Telegraphs:** Glowing crimson pulse and vector tell lines ($\ge 0.5\text{s}$) preceding activation.
- [x] **Projectile Parry Deflection:** 6-frame parry window intercepts incoming trap arrows, reversing their velocity 180° back at hostile targets.
- [x] **Dual Environmental Lethality:** Traps deliver full damage to both player and enemies; trap kills credit to `EnemyRegistry` immediately.
- [x] **Enemy Trap AI Awareness:** Patrolling guards detect traps within 64px and turn around; chasing guards have 25% blunder chance and 75% evasion jump chance.
- [x] **Acoustic Pulse Disarming:** Tuning acoustic pulses (Whisper, Normal, Scream) to match a trap's frequency disables it for 3.0s to 5.0s.
- [x] **Level Integration Safety:** All traps placed across all 9 sectors adhere to Level Validator Section 6.5 safety rules (no traps on spawn or exit).

### 3.8 Difficulty Scaling & Performance
- [x] **3 Difficulty Modes:** Shinobi (5 HP, 6f parry, 25% enemy evade), Ronin (4 HP, 4f parry, 40% enemy evade, +1 trap dmg), Oni (3 HP, 3f parry, 55% enemy evade, lethal trap crush).
- [x] **Performance Guarantee:** 144.8 FPS measured at 1920x1080 with 12 animated enemies + 10 traps + particles + shaders (target $\ge 60\text{ FPS}$, avg frame time 6.91 ms $\le 16.67\text{ ms}$).

---

## 4. Verification Evidence & Artifact References

| Verification Test / Artifact | Output / Result | Reference Document / Image |
|---|---|---|
| `tests/run_tests.gd` | **ALL 34 TESTS PASSED (0 FAILURES)** | [`docs/FINAL_TEST_OUTPUT.md`](file:///c:/vibe-game/docs/FINAL_TEST_OUTPUT.md) |
| `tests/level_validator.gd` | **9/9 LEVELS PASSED (0 FAILURES)** | [`docs/LEVEL_VALIDATION.md`](file:///c:/vibe-game/docs/LEVEL_VALIDATION.md) |
| `tests/test_combat_live.gd` | **7/7 COMBAT MECHANICS PASS** | [`docs/COMBAT_VERIFICATION.md`](file:///c:/vibe-game/docs/COMBAT_VERIFICATION.md) |
| `tests/test_enemy_reactions.gd` | **7/7 ENEMY REACTION CRITERIA PASS** | [`docs/ENEMY_REACTION_VERIFICATION.md`](file:///c:/vibe-game/docs/ENEMY_REACTION_VERIFICATION.md) |
| `tests/test_traps.gd` | **12/12 TRAP MECHANICS PASS** | Headless trap verification runner |
| `tests/measure_performance.gd` | **144.8 FPS at 1080p (6.91 ms avg)** | [`docs/PERFORMANCE_REPORT.md`](file:///c:/vibe-game/docs/PERFORMANCE_REPORT.md) |
| Hero Idle & Run Sprite | White ninja samurai sprite animation | `qa/shots/hero_sprite_idle.png` |
| Hero Dash Slash | Invulnerable piercing forward strike | `qa/shots/hero_dash_slash.png` |
| Hero Plunge Strike | Airborne ground slam shockwave | `qa/shots/hero_plunge_strike.png` |
| Hero Rising Slash | Upward launcher slash | `qa/shots/hero_rising_slash.png` |
| Hero Counter Strike | Parry deflect riposte slow-mo | `qa/shots/hero_counter_strike.png` |
| Enemy Hit Flinch & Hurt | Knockback & hurt state | `qa/shots/enemy_hit_flinch.png` |
| Enemy Poise Break | Stagger stun posture break | `qa/shots/enemy_poise_break.png` |
| Enemy Vertical Jump | Upper catwalk platform jump (0.48s) | `qa/shots/enemy_vertical_jump.png` |
| Enemy Brute Enraged | Low HP berserk red aura & roar | `qa/shots/enemy_brute_enraged.png` |
| Trap: Floor Spikes | Proximity red shimmer & spike thrust | `qa/shots/trap_floor_spikes.png` |
| Trap: Ceiling Spikes | Overhead detection & impaling thrust | `qa/shots/trap_ceiling_spikes.png` |
| Trap: Swinging Blade | Continuous pendulum arc hazard | `qa/shots/trap_swinging_blade.png` |
| Trap: Wall Blade | Wall pop-out horizontal blade | `qa/shots/trap_wall_blade.png` |
| Trap: Arrow Trap | Wall arrow launcher (parry deflectable) | `qa/shots/trap_arrow_trap.png` |
| Trap: Falling Rock | Ceiling crush & residual debris | `qa/shots/trap_falling_rock.png` |
| Trap: Rolling Boulder | Sloped continuous rolling obstacle | `qa/shots/trap_rolling_boulder.png` |
| Trap: Guillotine | Vertical heavy decapitation dropper | `qa/shots/trap_guillotine.png` |
| Trap: Fire Trap | Floor flame plume & burn damage | `qa/shots/trap_fire_trap.png` |
| Trap Killing Enemy | Dual-damage hazard eliminating hostile | `qa/shots/trap_killing_enemy.png` |
| Combat Arena HUD | Segmented HP bar, floating bars | `qa/shots/combat_arena_hud_view.png` |
| Traceability Matrix | All features audited, fixed, and verified | [`docs/AUDIT.md`](file:///c:/vibe-game/docs/AUDIT.md) |
| Architectural Decisions | All 12 ADR records documented | [`docs/DECISIONS.md`](file:///c:/vibe-game/docs/DECISIONS.md) |
| Sprite Manifest & Map | 110 sliced frames & 17 SpriteFrames | [`docs/SPRITE_MAP.md`](file:///c:/vibe-game/docs/SPRITE_MAP.md) |
