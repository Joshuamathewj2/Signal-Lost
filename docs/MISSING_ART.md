# SIGNAL LOST — Missing Art Inventory & Stand-in Mapping

**Version:** 1.0  
**Date:** 2026-10-17  
**Purpose:** Documents all required animation states where bespoke hand-drawn frames are currently absent from the original sheets, defines the dynamic engine-generated stand-in transforms (frame reuse + squashes, tints, rotations, and VFX), and structures the `SpriteFrames` resources so that future artwork drops directly into `resources/sprites/*.tres` by animation name with zero GDScript code modifications.

---

## 1. Hero Missing Animations & Dynamic Stand-ins

| Animation State | Target Art Description | Current Stand-in Source Frame | Stand-in Procedural Transform / VFX | Future Drop-in Name |
|---|---|---|---|---|
| **`parry`** | Defensive deflection with crossguard raised and blade vertical | `hero_attack_thrust_0.png` | Stance locked horizontally, scaled `(0.9, 1.1)` (rigid braced pose) + white flash (`modulate = Color(2.5, 2.5, 2.5)`) + `fx_hit_spark_0` spawned at blade center | `parry` (2-4 frames) |
| **`guard`** | Low defensive guard blocking frontal energy | `hero_attack_thrust_0.png` | Held at 0° angle with blue rim pulse | `guard` (1-2 frames) |
| **`heavy`** | Full two-handed vertical cleave downward follow-through | `hero_attack_heavy_0.png` | Rotates from +15° (windup) to -30° (slam) + `fx_slash1_0` spawned on active frame | `heavy` (3-5 frames) |
| **`shuriken` / `kunai_toss`** | Arm cocked back and flicked forward to release throwing star/kunai | `hero_attack_thrust_0.png` | Fast 0.1s arm extension + spawned spinning `projectiles_knife_0` / shuriken | `shuriken` (2-3 frames) |
| **`takedown`** | Lethal rear backstab / neck snap on unaware target | `hero_attack_heavy_0.png` | Sudden forward dash + overhead blade plunge + target crimson flash | `takedown` (4-6 frames) |
| **`dead`** | Complete collapse and motionless dissolution into digital noise | `hero_hurt_0.png` | Knocks backward, drops to ground `position.y += 8`, fades with glitch scanlines (`death_burst`) | `dead` (3-5 frames) |
| **`wall_slide`** | Wall-cling / friction slide with one hand dragging sparks | `hero_crouch_0.png` | Flipped toward wall, tilted 15°, trailing subtle wall dust particles | `wall_slide` (1-2 frames) |
| **`air_attack`** | Mid-air horizontal spinning crescent slash | `hero_attack_heavy_0.png` | Scaled `(1.1, 0.9)`, rotated -25° with crescent slash arc attached | `air_attack` (2-3 frames) |
| **`dash_slash`** | Ultra-fast phantom dash with trailing afterimages | `hero_attack_thrust_0.png` | Streamlined horizontal lunge with ghost alpha trail (`Color(1, 1, 1, 0.5)`) | `dash_slash` (2-3 frames) |
| **`plunge`** | Vertical downward air-to-ground dive with blade pointed down | `hero_jump_0.png` | Rotated 90° downward + downward speed lines; triggers `fx_smash_impact_0` on impact | `plunge` (2 frames) |
| **`rising_slash`** | Upward launcher slash lifting enemy into the air | `hero_attack_heavy_0.png` | Upward angled leap + vertical slash arc + upward camera impulse | `rising_slash` (2-3 frames) |
| **`counter_strike`** | Explosive riposte following successful parry | `hero_attack_thrust_0.png` | Instant snap forward + red/white inverted screen flash + critical hit spark | `counter_strike` (2-3 frames) |

---

## 2. Enemy Missing Animations & Dynamic Stand-ins

| Enemy Type | Missing Animation | Current Stand-in Source Frame | Stand-in Procedural Transform / VFX | Future Drop-in Name |
|---|---|---|---|---|
| **Ronin (Sword)** | `stun` / `poise_break` | `ronin_hurt_0.png` | Unsteady wobble (`sin(time * 12.0) * 8°`), head bowed, yellow/white dizzy sparks above helm | `stun` (3-4 frames) |
| **Ronin (Sword)** | `block` / `parry` | `ronin_attack2_0.png` | Blade held vertically across chest + metallic clang SFX + blue spark | `block` (2 frames) |
| **Ronin (Sword)** | `evade` (backstep) | `ronin_run_0.png` | Flipped opposite to movement direction, rapid 80px back-glide + `fx_dust_0` at feet | `evade` (2-3 frames) |
| **Archer** | `stun` / `poise_break` | `archer_hurt_0.png` | Bow dropped slightly, staggered backward 12px, dizzy stars | `stun` (2-3 frames) |
| **Archer** | `evade` (side-hop) | `archer_run_0.png` | Airborne arc hop backward with dust puff | `evade` (2 frames) |
| **Spear** | `stun` / `poise_break` | `spear_hurt_0.png` | Spear butt grounded for balance, trembling stance | `stun` (3 frames) |
| **Spear** | `evade` (pole vault back) | `spear_idle_0.png` | Vaulting push off spear back 90px | `evade` (3 frames) |
| **Heavy (Brute)** | `stun` / `poise_break` | `brute_hurt_0.png` | Drops to one knee (long 2.0s vulnerability window) | `stun` (4 frames) |
| **Heavy (Brute)** | `enrage` | `brute_smash_0.png` | Roar pose, pulsating crimson danger aura, kanabo brandished overhead | `enrage` (3 frames) |

---

## 3. Architecture for Zero-Code Drop-in Replacement

All character and enemy visual controllers bind to animations exclusively via `AnimatedSprite2D.play(anim_name)` using the names above.
When a new hand-drawn sprite sheet is added:
1. Export the new frames into `assets/sprites/<category>/`.
2. Update the `SpriteFrames` resource (`resources/sprites/<category>_frames.tres`) with the new frames.
3. Because the GDScript controllers check `if sprite_2d.sprite_frames.has_animation(anim_name)`, the newly added frames will immediately take effect with zero code modifications.
