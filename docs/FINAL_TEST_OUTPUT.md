Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[audio] SfxLibrary rendered in 136 ms (< 1500 ms limit)
PASS test_ai_ashigaru.gd
[noise] Noise emitted type=9 at (0.0, 0.0) r=120.0 loud=1.20
PASS test_ai_brute.gd
[noise] Noise emitted type=9 at (0.0, 0.0) r=160.0 loud=1.40
PASS test_ai_kenshi.gd
PASS test_ai_yumi.gd
PASS test_awareness_reticles.gd
[noise] Noise emitted type=9 at (0.0, 0.0) r=560.0 loud=3.00
[noise] Noise emitted type=9 at (0.0, 0.0) r=560.0 loud=3.00
PASS test_boss_shogun.gd

========================================
SIGNAL LOST: CLEAR GATE VERIFICATION SUITE
========================================

TEST 1: Hostile registration and counts...
  [PASS] Registered 3 hostiles; counts=3/3, is_cleared=false

TEST 2: Terminal rejects completion while enemies remain...
[noise] Noise emitted type=5 at (0.0, 0.0) r=96.0 loud=0.80
  [PASS] Terminal rejected activation with 3 hostiles remaining

TEST 3: Counting various death causes...
  [PASS] Takedown and projectile deflection deaths successfully recorded

TEST 4: Elimination of final hostile unlocks terminal...
[noise] Noise emitted type=0 at (0.0, 0.0) r=320.0 loud=2.50
  [PASS] Final hostile eliminated; terminal unlocked with cyan/white beacon

TEST 5: Terminal allows level completion when cleared...
  [PASS] Terminal activated successfully and initiated level completion

TEST 6: Out-of-bounds stuck enemy recovery...
[noise] Noise emitted type=0 at (0.0, 0.0) r=320.0 loud=2.50
  [PASS] Out-of-bounds stuck enemy auto-defeated after 10s
PASS test_clear_gate.gd
[noise] Noise emitted type=9 at (0.0, 0.0) r=180.0 loud=1.50
[noise] Noise emitted type=9 at (0.0, 0.0) r=200.0 loud=1.80
[noise] Noise emitted type=9 at (0.0, 0.0) r=280.0 loud=2.50
[noise] Noise emitted type=1 at (0.0, 0.0) r=60.0 loud=0.40
PASS test_combat_combo.gd
PASS test_combat_guard.gd

========================================
SIGNAL LOST: LIVE COMBAT VERIFICATION SUITE
========================================

TEST 1: Weapon switch changes hitbox reach...
[noise] Noise emitted type=9 at (0.0, 0.0) r=240.0 loud=2.00
  [PASS] Naginata active hitbox reach is 52 px

TEST 2: Katana light attack deals damage...
[noise] Noise emitted type=9 at (0.0, 0.0) r=180.0 loud=1.50
  [PASS] Katana hit reduced enemy HP from 2 to 1

TEST 3: Katana 3-hit combo execution...
[noise] Noise emitted type=9 at (0.0, 0.0) r=180.0 loud=1.50
[noise] Noise emitted type=9 at (0.0, 0.0) r=200.0 loud=1.80
[noise] Noise emitted type=9 at (0.0, 0.0) r=280.0 loud=2.50
  [PASS] Katana 3-hit combo smoothly progressed from strike 1 to 2 to 3

TEST 4: Stealth rear takedown...
[noise] Noise emitted type=9 at (140.0, 100.0) r=60.0 loud=0.60
  [PASS] Stealth rear takedown executed lethal kill on unaware guard

TEST 5: Shuriken distraction...
[noise] Noise emitted type=9 at (0.0, 0.0) r=120.0 loud=1.50
  [PASS] Shuriken impacted terrain and emitted acoustic distraction ripple

TEST 6: 6-frame parry projectile reflection...
[noise] Noise emitted type=9 at (120.0, 100.0) r=260.0 loud=2.20
  [PASS] Parry window intercepted bolt, reflected it back, and destroyed Sentry

Saved report to res://docs/COMBAT_VERIFICATION.md
PASS test_combat_live.gd
[noise] Noise emitted type=9 at (0.0, 0.0) r=260.0 loud=2.20
PASS test_combat_parry.gd
[noise] Noise emitted type=9 at (120.0, 100.0) r=60.0 loud=0.60
PASS test_combat_stealth.gd
PASS test_combat_weapons.gd
[noise] Noise emitted type=7 at (0.0, 0.0) r=200.0 loud=2.00
PASS test_decoy.gd

========================================
SIGNAL LOST: LIVE ENEMY VERIFICATION SUITE
========================================

TEST 1: Shield Bearer defensive mechanics...
[noise] Noise emitted type=5 at (100.0, 100.0) r=120.0 loud=1.20
  [PASS] Shield Bearer blocks frontal light, allows rear bypass, breaks on heavy

TEST 2: Bomber projectile and deflection...
  [PASS] Bomber explosive defused/deflected mid-air by parry

TEST 3: Drone flight and laser charge...
  [PASS] Drone operates airborne hover, charges laser, 1-hit core kill

TEST 4: Shadow Assassin optical cloak and pulse reveal...
  [PASS] Shadow Assassin cloaks at 0.08 alpha, reveals on pulse

TEST 5: Chain Reaper hook and parry snap...
[noise] Noise emitted type=5 at (0.0, 0.0) r=220.0 loud=2.00
  [PASS] Chain Reaper hook snaps on parry, inflicting stagger

TEST 6: Jammer Tower electromagnetic interference...
  [PASS] Jammer Tower disables pulse within 240px, 3-hit structure

TEST 7: Banshee inhalation telegraph and silence...
  [PASS] Banshee enters 1.2s inhalation, silenced by swift hit

TEST 8: Mirror Duelist mini-boss combat...
[noise] Noise emitted type=9 at (0.0, 0.0) r=220.0 loud=2.00
  [PASS] Mirror Duelist raises parry guard, deflects light, broken by heavy

TEST 9: Oni Enforcer ground slam and Phase 2 rage...
[noise] Noise emitted type=0 at (0.0, 0.0) r=480.0 loud=3.00
  [PASS] Oni Enforcer triggers Phase 2 Rage at <= 50% HP (6 HP)

TEST 10: Elite Modifiers dynamic enhancement...
  [PASS] Elite Modifier applied ARMORED enhancements (+100% poise)

Saved report to res://docs/ENEMY_VERIFICATION.md
PASS test_enemies_live.gd

========================================
SIGNAL LOST: ENEMY REACTION VERIFICATION
========================================

TEST 1: Hit causes hurt animation and knockback...
  [PASS] Hit applied 160 px/s knockback impulse and triggered hurt animation

TEST 2: Poise break causes stagger...
  [PASS] Poise depleted to 0; enemy entered staggered stun state

TEST 3: Evade occurs at least once in 20 hits...
  [PASS] Evade triggered 5 times out of 20 attempts (expected >= 1 at 35% rate)

TEST 4: Low-HP enemy retreat and Brute enrage...
[noise] Noise emitted type=8 at (0.0, 0.0) r=320.0 loud=2.50
  [PASS] Standard enemy entered retreat mode; Brute triggered aggressive rage mode

TEST 5: Lower platform to upper platform parabolic jump traversal...
  [PASS] Enemy parabolic jump traversed delta (-80px vert, +80px horiz) in 0.48s (<= 6.0s)

TEST 6: Enemy escapes upward when attacked...
  [PASS] Enemy executed upward escape leap (vy = -440.0 px/s)

TEST 7: EnemyRegistry count updates immediately at death...
[noise] Noise emitted type=0 at (0.0, 0.0) r=320.0 loud=2.50
  [PASS] EnemyRegistry decremented immediately upon death while node remains in tree (lingering corpse)
Saved verification report to res://docs/ENEMY_REACTION_VERIFICATION.md
PASS test_enemy_reactions.gd
PASS test_health_system.gd
PASS test_hearing.gd
PASS test_hint_signs.gd
PASS test_hud.gd
PASS test_level_parser.gd
[router] load_level 2 (res://levels/level_02.txt)
PASS test_level_select_complete.gd
PASS test_main_menu.gd
PASS test_medals.gd
PASS test_pause_menu.gd
PASS test_performance_mode.gd
PASS test_platform_graph.gd
PASS test_pulse_tiers.gd
PASS test_puzzle_glyphs.gd

========================================
SIGNAL LOST: LIVE PUZZLE VERIFICATION SUITE
========================================

TEST 1: Noise calibration (Sneak < Walk < Run < Attack)...
[noise] Noise emitted type=1 at (0.0, 0.0) r=40.0 loud=0.50
[noise] Noise emitted type=1 at (0.0, 0.0) r=80.0 loud=1.00
  [PASS] Sneak is silent (0 px), Walk (40 px), Run (80 px), Whisper pulse sub-threshold (< 1.0 loudness)

TEST 2: EchoGlyphs tier-selective reveal...
  [PASS] Whisper reveals Cyan rune, Normal reveals White, Scream reveals Red, Mismatch yields gibberish

TEST 3: Resonance Panels acoustic matching & lockout...
[noise] Noise emitted type=3 at (0.0, 0.0) r=160.0 loud=1.20
  [PASS] Matching acoustic tier activates panel; mismatch locks panel out for 3.0s

TEST 4: Harmonic Lanterns 1-2-3 sequential strike & blast door unlock...
[noise] Noise emitted type=5 at (0.0, 24.0) r=96.0 loud=0.80
[noise] Noise emitted type=5 at (0.0, 24.0) r=96.0 loud=0.80
[noise] Noise emitted type=5 at (0.0, 24.0) r=96.0 loud=0.80
[noise] Noise emitted type=6 at (0.0, 0.0) r=64.0 loud=0.50
[noise] Noise emitted type=5 at (0.0, 24.0) r=96.0 loud=0.80
[noise] Noise emitted type=5 at (0.0, 24.0) r=96.0 loud=0.80
  [PASS] Striked 1->2->3 within 8.0s unlocks target blast door; out-of-order strike triggers sequence reset

TEST 5: Keycard collection & Electronic Door opening...
[noise] Noise emitted type=5 at (0.0, 0.0) r=0.0 loud=0.00
[noise] Noise emitted type=6 at (0.0, 0.0) r=64.0 loud=0.50
  [PASS] Keycard pickup registers in GameState and enables paired door to open

TEST 6: Memory Fragments collection & SaveData persistence...
  [PASS] Collected 3 fragments, recorded in run stats, persisted to SaveData with bitmask

TEST 7: Exit Terminal sector completion & next sector unlock...
  [PASS] Exit Terminal triggers level completion, evaluates Ghost medal, unlocks next sector
Saved report to res://docs/PUZZLE_VERIFICATION.md
PASS test_puzzle_live.gd
[noise] Noise emitted type=3 at (0.0, 0.0) r=160.0 loud=1.20
[noise] Noise emitted type=5 at (0.0, 24.0) r=96.0 loud=0.80
[noise] Noise emitted type=3 at (0.0, 0.0) r=280.0 loud=1.80
[noise] Noise emitted type=0 at (0.0, 0.0) r=120.0 loud=1.00
PASS test_puzzle_resonance.gd
PASS test_resources.gd
PASS test_settings.gd
PASS test_state_machine.gd

========================================
SIGNAL LOST: MASTER TRAP VERIFICATION SUITE
========================================

TEST 1: Floor Spikes states, dual damage & disarm...
[noise] Noise emitted type=5 at (0.0, 0.0) r=60.0 loud=0.60
[noise] Noise emitted type=3 at (0.0, 0.0) r=40.0 loud=0.50
  [PASS] Floor Spikes state sequence, 2 DMG delivery, and disarm verified
TEST 2: Ceiling Spikes drop & crush damage...
[noise] Noise emitted type=3 at (0.0, 80.0) r=180.0 loud=1.80
  [PASS] Ceiling Spikes 0.6s tell, 3 DMG crush, and winch reset verified
TEST 3: Swinging Blade continuous pendulum...
[noise] Noise emitted type=5 at (0.0, 0.0) r=60.0 loud=0.60
  [PASS] Swinging Blade continuous pendulum motion and active arc verified
TEST 4: Wall Blade extend, strike & retract...
[noise] Noise emitted type=5 at (0.0, 0.0) r=50.0 loud=0.50
[noise] Noise emitted type=3 at (24.0, 0.0) r=90.0 loud=0.90
  [PASS] Wall Blade extend -> strike -> retract sequence verified
TEST 5: Arrow Trap firing & parry deflection...
[noise] Noise emitted type=5 at (0.0, 0.0) r=50.0 loud=0.40
[noise] Noise emitted type=9 at (0.0, 0.0) r=140.0 loud=1.50
  [PASS] Arrow Trap aiming, firing, and 180-degree parry deflection verified
TEST 6: Spear Launcher charge, launch & reset...
[noise] Noise emitted type=5 at (0.0, 0.0) r=60.0 loud=0.60
[noise] Noise emitted type=3 at (0.0, 0.0) r=120.0 loud=1.20
  [PASS] Spear Launcher pneumatic charge and launch verified
TEST 7: Falling Rock crack, fall & impact...
[noise] Noise emitted type=3 at (0.0, 0.0) r=80.0 loud=0.80
  [PASS] Falling Rock ceiling tremor tell and floor impact verified
TEST 8: Rolling Boulder roll physics & noise...
[noise] Noise emitted type=3 at (0.0, 0.0) r=120.0 loud=1.20
[noise] Noise emitted type=3 at (0.0, 0.0) r=240.0 loud=2.50
  [PASS] Rolling Boulder roll physics and 240px acoustic rumble verified
TEST 9: Guillotine razor drop & winch reset...
[noise] Noise emitted type=5 at (0.0, 0.0) r=60.0 loud=0.60
[noise] Noise emitted type=3 at (0.0, 64.0) r=160.0 loud=1.60
  [PASS] Guillotine high-speed razor drop and winch reset verified
TEST 10: Fire Trap charge, flame jet & disarm...
[noise] Noise emitted type=0 at (0.0, 0.0) r=60.0 loud=0.50
[noise] Noise emitted type=3 at (0.0, 0.0) r=140.0 loud=1.40
  [PASS] Fire Trap gas charge, flame jet, and acoustic disarm verified
TEST 11: Extra Projectiles 6-archetype matrix...
  [PASS] All 6 ExtraProjectile ammunition types successfully initialized
TEST 12: Trap kill integration with EnemyRegistry clear-gate...
[noise] Noise emitted type=0 at (0.0, 0.0) r=320.0 loud=2.50
[noise] Noise emitted type=0 at (1168.0, 320.0) r=320.0 loud=2.50
[particles] Particle limit reached: 270/300
[noise] Noise emitted type=0 at (1232.0, 352.0) r=320.0 loud=2.50
  [PASS] Trap kills directly decrement EnemyRegistry and satisfy the clear gate
PASS test_traps.gd
[level] LevelParser: ragged row 2 has length 7, expected 8
PASS test_validator.gd
ALL TESTS PASSED
ERROR: 2 RID allocations of type 'N13RendererDummy11MeshStorage14DummyMultiMeshE' were leaked at exit.
ERROR: 2 RID allocations of type 'N13RendererDummy9DummyMeshE' were leaked at exit.
