# SIGNAL LOST — Architecture Decision Records (ADR) & Design Log

This document records the architectural and design decisions implemented for SIGNAL LOST.

---

### ADR-001: Component-Based Combat Architecture over Monolithic Callbacks
- **Context**: V1 player and enemy scripts handled damage, health, and state transitions through hardcoded duck-typed string callbacks.
- **Decision**: Adopt a modular component model (`HealthComponent`, `PoiseComponent`, `HitboxComponent`, `HurtboxComponent`, `CombatController`).
- **Status**: **ACCEPTED** (Verified).

---

### ADR-002: In-Engine Procedural Audio Synthesis over External Asset Bundles
- **Context**: External audio assets bloat bundle size and introduce asset streaming overhead.
- **Decision**: Synthesize 100% of sound effects and dynamic music algorithmically in-engine via `SfxLibrary` and `audio/synth.gd` on boot (< 450 ms).
- **Status**: **ACCEPTED** (Verified).

---

### ADR-003: Custom Directed A* Platform Graph over Built-In NavigationRegion2D
- **Context**: Godot 4's built-in `NavigationRegion2D` is unsuited for vertical 2D platforming jump reach limitations.
- **Decision**: Generate discrete directed graphs using `AStar2D` with jump trajectory validation.
- **Status**: **ACCEPTED** (Verified).

---

### ADR-004: Strict Tri-Color Vector Aesthetics over Pixel Art Bitmaps
- **Context**: High-contrast noir aesthetic requirement.
- **Decision**: Razor White `#FFFFFF`, Pitch Black `#000000`, Danger Red `#E00000`, with unshaded highlights.
- **Status**: **ACCEPTED** (Verified).

---

### ADR-005: Elimination of Trapped-in-a-Wall Bug Class (Spawn Room Geometry & Softlock Prevention)
- **Context**: Players could spawn inside confined terrain pockets or drop into inescapable trenches where vertical jump clearance was blocked or walls exceeded maximum jump height (2.7 tiles).
- **Decision**:
  1. Enforce strict spawn room geometry: $\ge 12$ tiles wide, $\ge 6$ tiles high, open route with $\ge 3$ tiles vertical clearance above player.
  2. Implement automated flood-fill jump reach graph validation in `tests/level_validator.gd` that catches any pocket where $w < 12$ and walls on both sides $\ge 3$ tiles without climb ladders/platforms.
  3. Add in-game anti-softlock timer in `player.gd`: if grounded and motionless for $\ge 20$ seconds while unalerted, HUD prompts `"PRESS [R] TO RETURN TO CHECKPOINT"`.
  4. Add hold-[R] (0.8s) immediate respawn action in `pause_menu.gd`.
- **Status**: **ACCEPTED** (Verified across 9/9 levels in `LEVEL_VALIDATION.md`).

---

### ADR-006: Hostile-Clear Progression Gate & Centralized EnemyRegistry
- **Context**: Levels could previously be completed by sprinting past all enemies directly to the exit, bypassing the stealth-action gameplay loop.
- **Decision**:
  1. Create `EnemyRegistry` autoload tracking living vs. total enemies across all death causes (melee, parry reflection, takedown, shuriken, hazards).
  2. Lock Exit Terminal until all enemies in the sector are eliminated (`is_cleared == true`). Attempting to interact while enemies remain flashes red, plays locked SFX, and displays `"SIGNAL LOCKED - X HOSTILES REMAIN"`.
  3. On eliminating the final hostile, trigger a dramatic "SIGNAL RESTORED" moment with acoustic pulse wave and slow-mo (`Engine.time_scale = 0.35`).
  4. HUD features a persistent top-center `"HOSTILES X/Y"` counter with pulse animation on kill, and a screen-edge directional red compass tick clamped to canvas boundaries when $\le 2$ hostiles remain or $> 60$s without a kill.
  5. Fallback recovery: if an enemy falls out of bounds or is trapped off-grid for $> 10$ seconds, `EnemyRegistry` auto-defeats it as a hazard fall.
- **Status**: **ACCEPTED** (Verified in `test_clear_gate.gd` and `test_puzzle_live.gd`).

---

### ADR-007: Expanded Enemy Roster & Telegraphed Counterplay System
- **Context**: The game required a rich, sound-reactive enemy roster with distinct silhouettes, readable tells, and skill-testing counterplay.
- **Decision**: Implement 9 distinct hostile archetypes + dynamic Elite Modifiers:
  - **Shield Bearer**: Pavise tower shield blocks frontal light strikes; vulnerable from behind; guard-broken by heavy attack (K) or parry.
  - **Bomber**: Lobs arc-trajectory timed bombs that shatter glass and deal AoE damage; bombs can be deflected mid-air by parry back at enemies.
  - **Drone**: Airborne hover patrol without gravity; charges 0.6s red laser sightline; 1 shuriken kill; laser beam frame-tight parry deflectable.
  - **Shadow Assassin**: Cloaked at 0.08 alpha with faint shimmer; revealed by acoustic pulse waves; executes telegraphed blink strike behind player, parryable into stagger.
  - **Chain Reaper**: Throws 200px kusarigama chain hook to drag player; parry snaps chain and inflicts 2.0s stagger.
  - **Jammer Tower**: Fortified electronic warfare structure emitting 240px pulse-jamming aura; 3-hit destroyable; registered in `EnemyRegistry`.
  - **Banshee (Wraith)**: Floats through obstacles; initiates 1.2s inhalation telegraph; silenceable with quick strike before scream; scream alerts all enemies in sector.
  - **Mirror Duelist (Mini-boss 1, Level 4)**: 8 HP; mirrors player stances (Katana / Kusarigama); uses defensive parry; broken by heavy attack or acoustic pulse stun.
  - **Oni Enforcer (Mini-boss 2, Level 8)**: 12 HP; spiked Kanabo club ground slams creating acoustic shockwaves; triggers Phase 2 Rage at $\le 50\%$ HP (flame horns, 1.5x speed, halved cooldowns).
  - **Elite Modifiers**: `ARMORED` (+100% poise, cyan aura), `ENRAGED` (+40% speed on hit, orange aura), `HUNTER` (+100% hearing range, amber aura).
- **Status**: **ACCEPTED** (Verified in `test_enemies_live.gd` and `docs/ENEMY_VERIFICATION.md`).

---

### ADR-008: Dynamic Sector Generation & Strict Tilemap Level Validation
- **Context**: Level designs required automated reachability, geometry clearance, and puzzle completeness guarantees.
- **Decision**: Centralize level parsing and algorithmic reachability in `LevelValidator` (A* traversal, item placement rules, softlock prevention).
- **Status**: **ACCEPTED** (Verified: 34/34 tests pass, 9/9 levels valid).

---

### ADR-009: Real Sprite Asset Pipeline & Dynamic Silhouette Rim Contour
- **Context**: Real hand-drawn sprite sheets for Hero (white ninja samurai), Enemies (red samurai silhouettes), and Traps (dark atlas with crimson danger tells) needed integration without breaking existing noir lighting, physics, or procedural rigs.
- **Decision**:
  - Developed `tools/slice_sprites.py` with bounding-box extraction, auto-trimming, dark background stripping with smooth anti-aliased alpha ramps, generating 110 individual frames and `assets/sprites/sprite_manifest.json`.
  - Built `resources/sprites/*.tres` `SpriteFrames` native resources via `tools/build_sprite_frames.gd`.
  - Developed `shaders/hero_silhouette.gdshader` to project a 1px subtle rim contour around the white ninja, ensuring pristine readability in pitch-black environments.
  - Upgraded `PlayerVisual` and all enemy visual scripts (`KenshiVisual`, `AshigaruVisual`, `BruteVisual`, `SentryVisual`) to toggle between `AnimatedSprite2D` with speed-scaled locomotion and fallback procedural shapes.
- **Status**: **ACCEPTED** (Verified in `docs/SPRITE_MAP.md`, `qa/shots/hero_sprite_idle.png`, and `tests/run_tests.gd`).

---

### ADR-010: Hero Combat Feel Overhaul & Reactive AI Vertical Traversal
- **Context**: Combat required fluid offensive options, ripostes, and vertical agility; enemy AI needed to navigate multi-tier platforms dynamically, flinch on hits, break posture, evade, and update progression gates instantly.
- **Decision**:
  - **Hero Moves**:
    - **Dash Slash**: Invulnerable dash with 1 DMG piercing hitbox, 1.2s cooldown, visual slash arc (`CombatState.DASH_SLASH`).
    - **Plunge Strike**: In-air dive (`vy = 520 px/s`), ground smash shockwave, 2 DMG, 64px AoE stun, smash impact particles (`CombatState.PLUNGING`).
    - **Rising Slash**: Upward launcher (`vy = -340 px/s`), 2 DMG, 35 poise damage, vertical knockback impulse.
    - **Counter Strike (Riposte)**: 0.5s counter window following parry deflect, 3 DMG lethal riposte, 60 poise damage, slow-mo flash (`HitStop.freeze(0.15s)`).
    - **Kunai Toss**: F subweapon, aerodynamic projectile ($v = 600 \text{ px/s}$), 40px silent acoustic radius, 1.5s stun on impact.
  - **HUD Segmented Health Bar**: Added custom-drawn segmented HP bar in `scenes/ui/hud.gd` with damage flash and outline rendering.
  - **Enemy AI & Reactions**:
    - Floating segmented health and poise bars revealed upon taking damage (`scenes/ui/floating_enemy_bar.gd`).
    - Flinch and knockback on hit; posture break and stun animation on poise depletion to 0.
    - Statistical 35% evasion backstep (`try_evade()`).
    - Low-HP retreat (<25%) for standard enemies and aggressive rage mode for Brute enemies (`is_enraged = true`).
    - Parabolic vertical ledge jumping (`PlatformMover.calculate_jump_velocity`) allowing enemies on lower catwalks to leap to upper platforms in <0.5s.
    - Upward escape leap when attacked.
    - Instant `EnemyRegistry` accounting at moment of death, decoupled from the 1.0s lingering death animation and corpse fade-out.
- **Status**: **ACCEPTED** (Verified 7/7 PASS in `tests/test_enemy_reactions.gd`, `docs/ENEMY_REACTION_VERIFICATION.md`, and `qa/shots/`).

---

### ADR-011: Data-Driven Hazard Architecture & Dual-Target Environmental Lethality
- **Context**: Traps needed to serve as dual-edged environmental hazards affecting both hero and enemies, provide readable danger telegraphs, integrate acoustic disarming, and allow enemies to avoid or blunder into them.
- **Decision**:
  - Created `TrapData` typed Resource (`scripts/resources/trap_data.gd`) and centralized `TrapRegistry` autoload.
  - Implemented base `TrapBase` state machine (`IDLE`, `TELEGRAPH`, `ACTIVE`, `RESET`, `DISARMED`) with glowing red telegraph lines and pulse animations.
  - Dual-target damage delivery: hurtboxes for player and hitboxes for enemies with immediate `EnemyRegistry` death tracking.
  - Parrying interaction: Projectile traps (Arrow Trap, Spear Launcher) can be parried within 6-frame window to reflect 180° back at enemies.
  - Acoustic disarm mechanic: Sonar pulses (Whisper, Normal, Scream) matched to trap frequency disarm traps for 3.0s to 5.0s.
  - Enemy AI trap awareness: Patrol enemies detect active traps within 64px and reverse direction; chasing enemies have 25% blunder chance and 75% evasion jump chance.
  - Signature traps placed across all 9 sectors with level validator placement safety rules (no traps on spawn, exit, or inside solid terrain).
- **Status**: **ACCEPTED** (Verified 12/12 criteria PASS in `tests/test_traps.gd`, `qa/shots/trap_*.png`, and `tests/level_validator.gd`).

---

### ADR-012: Difficulty Tier Matrix & 60 FPS Performance Guarantee
- **Context**: The game required balanced skill scaling (casual stealth vs. punishing hardcore) and strict 60 FPS performance at 1080p with multiple active animated entities, traps, and shaders.
- **Decision**:
  - Implemented 3 Difficulty Tiers in `GameState` (`Difficulty.SHINOBI`, `Difficulty.RONIN`, `Difficulty.ONI`):
    - HP: 5 (Shinobi) / 4 (Ronin) / 3 (Oni)
    - Parry Deflect Window: 6 frames (Shinobi) / 4 frames (Ronin) / 3 frames (Oni)
    - Enemy Evade Rate: 25% (Shinobi) / 40% (Ronin) / 55% (Oni)
    - Trap Lethality: Standard / +1 DMG / +2 DMG (Instant kill crush)
  - Profiled frame times with `tests/measure_performance.gd`: 12 enemies, 10 traps, active particles, and post-fx at 1920x1080 ran at **144.8 FPS (avg 6.91 ms per frame)**, far surpassing the 16.67 ms (60 FPS) requirement.
- **Status**: **ACCEPTED** (Verified in `docs/BALANCE_LOG.md` and `docs/PERFORMANCE_REPORT.md`).
