# SIGNAL LOST

> *You are a tiny robot in an abandoned subterranean facility. The world is pitch black. You see only by emitting sonar pulses, but enemies hear every pulse. Seeing reveals your position.*

A 2D stealth-platformer exploration puzzle game built in **Godot Engine 4.4+** using GL Compatibility renderer and strictly typed GDScript.

---

## 1. Core Mechanics

- **Echolocation & Sonar Waves:** The environment is pitch black. Charge and release acoustic pulses to emit expanding wavefronts that physically illuminate solid terrain, reveal hidden catwalks, and cast hard dynamic shadows.
- **Pulse Tiers & Noise Budget:**
  - **Whisper (Tier 0):** Short 72 px reveal, low noise (43.2 px radius). Completely safe near standard patrols.
  - **Normal (Tier 1):** Medium 200 px reveal, standard noise. Triggers enemy investigation.
  - **Scream (Tier 2):** Massive 560 px reveal, thunderous shockwave (728 px radius). Breaks glass floors and sways lanterns, but alerts all enemies in the sector.
- **Acoustic Enemies:**
  - **Listener:** Floor patrol that tracks sound origin and searches around alert points.
  - **Sentry:** Balcony turret with 40° vision cone, laser targeting, and lethal red projectiles.
  - **Hunter:** Aggressive apex stalker with 3-position sound memory and high sprint speed.
  - **Deaf Brute:** Blind and deaf to airborne pulses, but hears running steps and charges instantly.
- **Interactables & Tools:**
  - **Decoy Beacon (`F` / Button 3):** Thrown acoustic beacon that creates a remote diversion.
  - **Acoustic Vents:** Intake `V` teleports and amplifies sound to outlet `v`. Mute vent `M` damps pulse noise by 70%.
  - **Keycards & Doors:** Color-coded security terminals, pressure plates, and directional one-way gates.
- **Scoring & Medals:**
  - **Ghost:** Zero Normal or Scream pulses, zero detections.
  - **Quiet:** Zero Scream pulses, at most 1 detection.
  - **Loud:** Completed through any means.

---

## 2. Controls

| Action | Keyboard & Mouse | Gamepad |
|---|---|---|
| **Move Left / Right** | `A` / `D` or `Left` / `Right` | Left Stick / D-Pad |
| **Jump** | `Space` / `W` / `Up` | Bottom Action (`A` / Cross) |
| **Sneak (Silent)** | `Shift` (Hold) | Left Trigger / `L2` |
| **Drop Through Platform** | `S` + `Space` / `Down` + `Jump` | Down + Jump |
| **Charge Sonar Pulse** | `K` (Hold) or `Left Mouse Button` | Right Trigger / `R2` |
| **Quick Scream** | `E` (when enabled in Settings) | Right Shoulder / `R1` |
| **Throw Decoy Beacon** | `F` | Left Shoulder / `L1` or `X` |
| **Interact / Terminal** | `E` / `Enter` | Top Action (`Y` / Triangle) |
| **Pause Menu** | `Escape` | `Start` / `Menu` |
| **Restart Level** | `R` | `Select` / `Back` |
| **Debug Overlay** | `F1` (Toggle) / `F2` (Next Page) | — |

---

## 2b. Chapter II — The Undercroft

Pick **CHAPTER II: UNDERCROFT** on the main menu. Six connected rooms, seven new sprite-drawn villains and a finale boss:

- **Break the five seals.** Kill every villain in a room to break its seal (and recover 1 HP). Cleared rooms stay empty.
- **The Sanctum is sealed** until all five are broken; then face **the Leviathan** (three phases: slams and sweeps → floor fractures and energy pillars → shadow clones and sword rain). Break its poise to stagger it; staggered hits deal double damage.
- Red flashing wind-ups mark every attack. A **!** over a villain means the hit is unblockable: dodge it instead of guarding.
- Dying respawns you at the door you entered by. Time, deaths and best time are recorded.

| Villain | Watch for |
|---|---|
| Phantom | dashes in from mid-range after a red tell |
| Warden | shield blocks frontal light hits — strike from behind, or break through with a heavy strike or parry riposte |
| Executioner | cannot be flinched mid-swing; bait the slam, punish the recovery |
| Iron Monk | flail spin hits both sides; lobs the flail at range |
| Blood Archer / Archer | keep their distance; charged arrows are unblockable |
| Acoustic Hunter | hears footsteps — sneak, then strike first |

---

## 3. Project Structure

```
vibe-game/
├── autoload/            # Core singletons (GameState, NoiseBus, GameConfig, SaveData, SceneRouter)
├── docs/                # Design specifications, architecture, and task guides
│   ├── ARCHITECTURE.md  # Engine technical architecture & performance budgets
│   ├── BALANCE_LOG.md   # Level completion times, stealth viability & scream utility
│   ├── BUGS.md          # Bug bash resolution registry
│   ├── LEVEL_DESIGN.md  # Level layouts, legend, and solution guides
│   ├── PERF_REPORT.md   # Integrated GPU benchmarking & degrade order metrics
│   └── TASKS.md         # Production tasks and phase progression
├── export/              # Export binaries (Windows & Linux)
├── levels/              # ASCII text level files (level_01.txt - level_08.txt)
├── resources/           # Typed configuration resources (.tres)
├── scenes/              # Game scenes (player, enemies, interactables, sonar, UI, world)
├── shaders/             # Custom GL Compatibility shaders (flat reveal, air waves, post FX)
└── tests/               # Headless automated verification test suites
```

---

## 4. Building & Running

### Running in Godot
1. Open Godot Engine 4.4+ or 4.7+.
2. Import the project using `project.godot`.
3. Press **F5** or click **Play** to run `res://scenes/main/main.tscn`.

### Headless Verification & Testing
Run all 17 automated test suites from the command line:
```powershell
godot --headless --path . -s res://tests/run_tests.gd
```

Chapter II live tests (each exits 0 on pass):
```powershell
godot --headless --path . res://tests/live/test_villains.tscn
godot --headless --path . res://tests/live/test_chapter2.tscn
```

Run static headless syntax & scene check:
```powershell
godot --headless --path . --quit-after 120
```

### Exporting Standalone Binaries
Using the presets defined in `export_presets.cfg`:
```powershell
# Windows 64-bit standalone
mkdir -p export
godot --headless --export-release "Windows Desktop" export/SignalLost.exe

# Linux 64-bit standalone
godot --headless --export-release "Linux/X11" export/SignalLost.x86_64
```

---

## 5. Credits & Licenses

- **Engine:** Godot Engine 4 (MIT License)
- **Typography:** Rajdhani Font Family by Indian Type Foundry (SIL Open Font License 1.1)
- **Audio:** 100% procedurally synthesized in-engine via `SfxLibrary` (zero external audio dependencies)
- **Design & Code:** Developed according to the *Signal Lost* Technical & Production Specification.
