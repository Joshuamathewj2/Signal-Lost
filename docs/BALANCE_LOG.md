# SIGNAL LOST — Master Balance & Difficulty Specification

**Version:** 2.0  
**Date:** 2026-10-17  
**Status:** IMPLEMENTED & VERIFIED  

---

## 1. Difficulty Tier Matrix (Shinobi / Ronin / Oni)

| Parameter | Shinobi (Normal) | Ronin (Hard) | Oni (Nightmare) | System Impact |
|---|---|---|---|---|
| **Player Max HP** | 5 | 4 | 3 | Segmented HUD HP blocks (`HUD._draw_hp_blocks`) |
| **Parry Deflect Window** | 6 frames (100 ms) | 4 frames (67 ms) | 3 frames (50 ms) | `CombatController.parry_active_frames` |
| **Counter Window (Riposte)** | 0.50 s | 0.40 s | 0.30 s | `CombatController.counter_window_timer` |
| **Enemy Evade Chance** | 25% | 40% | 55% | `EnemyBase._try_evade()` via `GameState` |
| **Trap Damage Modifier** | +0 | +1 | +2 (Lethal Crush) | `TrapBase._deliver_damage_to()` |
| **Enemy Attack Aggression** | Normal cooldowns | -20% cooldowns | -40% cooldowns, rapid tokens | `AttackTokenManager` circulation |
| **Noise Sensitivity** | 1.0x baseline | 1.25x range | 1.5x range, instant reveal | `Awareness.on_heard()` |

---

## 2. Enemy Roster & Health / Poise Scaling

| Enemy Archetype | Class / Sprite | HP (Shinobi) | HP (Ronin) | HP (Oni) | Poise | Speed (px/s) | Signature Behavior |
|---|---|---|---|---|---|---|---|
| **Ronin (Sword)** | Ronin (`ronin_frames.tres`) | 2 | 3 | 4 | 30.0 | 120.0 | 3-Hit combo, 35% evade backstep, parry guard |
| **Archer (Yumi)** | Archer (`archer_frames.tres`) | 2 | 2 | 3 | 20.0 | 130.0 | Mobile kiting, seeks high ground, ranged arrow |
| **Spear (Ashigaru)** | Spear (`spear_frames.tres`) | 3 | 4 | 5 | 40.0 | 110.0 | Thrust reach (52px), overhead sweep, defense stance |
| **Brute (Heavy)** | Brute (`brute_frames.tres`) | 5 | 6 | 8 | 80.0 | 85.0 | Super armor frontal absorb, Kanabo slam, low-HP enrage (+40% speed) |
| **Shield Bearer** | Shield (`shield_bearer.gd`) | 3 | 4 | 5 | 60.0 | 90.0 | Frontal block, broken only by heavy attack / breaker |
| **Bomber** | Bomber (`bomber.gd`) | 2 | 3 | 4 | 25.0 | 100.0 | Arc explosive throw, mid-air deflectable |
| **Drone** | Drone (`drone.gd`) | 1 | 1 | 2 | 10.0 | 140.0 | Airborne hover flight, charged laser beam |
| **Shadow Assassin** | Assassin (`shadow_assassin.gd`) | 2 | 3 | 4 | 30.0 | 160.0 | Optical cloak (0.08 alpha), pulse reveal, rear backstab |
| **Chain Reaper** | Chain Reaper (`chain_reaper.gd`) | 4 | 5 | 6 | 50.0 | 105.0 | Extended chain hook whip, parry snap counter |
| **Jammer Tower** | Jammer (`jammer_tower.gd`) | 3 | 3 | 4 | 999.0 | 0.0 | 240px electromagnetic pulse suppression field |
| **Banshee** | Banshee (`banshee.gd`) | 2 | 3 | 4 | 20.0 | 125.0 | 1.2s inhalation scream telegraph, silenceable on hit |
| **Mirror Duelist** | Mirror (`mirror_duelist.gd`) | 5 | 6 | 8 | 60.0 | 140.0 | Shadow reflection, counter parry, heavy breaker |
| **Oni Enforcer** | Enforcer (`oni_enforcer.gd`) | 12 | 14 | 16 | 120.0 | 95.0 | Phase 2 rage at <= 50% HP, shockwave earth slam |
| **Boss Shogun** | Shogun (`boss_shogun.gd`) | 20 | 24 | 28 | 150.0 | 130.0 | Multi-phase arena boss, lethal sword art sequences |

---

## 3. Trap Hazard Data & Balancing Matrix

All traps feature mandatory visual + sound telegraphing of **>= 0.50 s** before active hitbox frames, with red danger indicator lines and acoustic footprints.

| Trap Archetype | Script / Scene | DMG (Shinobi) | DMG (Ronin) | DMG (Oni) | Telegraph | Reset Cooldown | Noise Footprint | Disarm Method |
|---|---|---|---|---|---|---|---|---|
| **Floor Spikes** | `floor_spikes.tscn` | 2 | 3 | 4 | 0.50 s | 2.0 s | 40 px (0.5 loud) | Whisper pulse (Tier 1) |
| **Ceiling Spikes** | `ceiling_spikes.tscn` | 3 | 4 | 5 (Lethal) | 0.60 s | 3.0 s | 180 px (1.8 loud) | Proximity trigger only |
| **Swinging Blade** | `swinging_blade.tscn` | 2 | 3 | 4 | 0.50 s | Continuous | 100 px (1.0 loud) | Continuous rhythmic timing |
| **Wall Blade** | `wall_blade.tscn` | 2 | 3 | 4 | 0.50 s | 2.2 s | 90 px (0.9 loud) | Periodic timer / tripwire |
| **Arrow Trap** | `arrow_trap.tscn` | 1 | 2 | 3 | 0.50 s | 2.5 s | 80 px (0.8 loud) | Normal pulse (Tier 2) or Parry Deflect |
| **Spear Launcher** | `spear_launcher.tscn` | 2 | 3 | 4 | 0.50 s | 2.0 s | 120 px (1.2 loud) | Pneumatic lock trigger |
| **Falling Rock** | `falling_rock.tscn` | 3 | 4 | 5 (Lethal) | 0.60 s | 3.5 s | 220 px (2.2 loud) | Overhead tremor tell |
| **Rolling Boulder** | `rolling_boulder.tscn` | 3 | 4 | 5 (Lethal) | 0.50 s | 6.0 s | 240 px (2.5 loud) | Tripwire / slope release |
| **Guillotine** | `guillotine.tscn` | 3 | 4 | 5 (Lethal) | 0.50 s | 2.5 s | 160 px (1.6 loud) | Timed rhythm / winch |
| **Fire Trap** | `fire_trap.tscn` | 2 | 3 | 4 | 0.60 s | 2.0 s | 140 px (1.4 loud) | Scream pulse (Tier 3) |

---

## 4. Hero Maneuvers & Combat Balance

| Maneuver | Input | DMG | Poise DMG | Cooldown / Window | Acoustic Radius | Special Property |
|---|---|---|---|---|---|---|
| **Katana Light Slash 1** | `J` / `LMB` | 1 | 15.0 | 0.20 s recovery | 180 px | 3-hit combo chain starter |
| **Katana Light Slash 2** | `J` / `LMB` | 1 | 20.0 | 0.22 s recovery | 200 px | Extended forward reach |
| **Katana Light Slash 3** | `J` / `LMB` | 2 | 35.0 | 0.32 s recovery | 280 px | Heavy spin finisher, wide knockback |
| **Heavy Strike** | Hold `J` / `LMB` | 2 | 50.0 | 0.45 s recovery | 320 px | Guard breaker, penetrates brute armor |
| **Dash Slash** | `Shift + Attack` | 1 | 25.0 | 1.20 s cooldown | 220 px | Invulnerable piercing dash |
| **Plunge Strike** | Air `Down + Attack` | 2 | 40.0 | On landing | 240 px | High-speed dive (520 px/s), 64px ground slam shockwave |
| **Rising Slash** | `Up + Attack` | 2 | 35.0 | 0.30 s recovery | 200 px | Vertical launcher impulse (vy = -340 px/s) |
| **Counter Strike (Riposte)** | Attack after Parry | 3 | 60.0 | 0.50 s counter window | 260 px | Lethal punish following deflect, slow-mo hitstop |
| **Parry (Deflect)** | Tap `K` / `RMB` | 0 | 40.0 | 6f window | 260 px | Deflects hostile projectiles 180 deg back |
| **Kunai Toss** | `F` | 1 | 30.0 | 0.80 s cooldown | 40 px (silent) | Fast ranged projectile (600 px/s), 1.5s stun on impact |
