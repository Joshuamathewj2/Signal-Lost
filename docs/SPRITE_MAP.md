# SIGNAL LOST — Master Sprite Map & Atlas Specification

**Version:** 1.0  
**Date:** 2026-10-17  
**Status:** FULLY SLICED & INTEGRATED (110 Frames)  
**Atlas Source Files:**
1. `res://assets/sprites/hero/White_Ninja_Samurai_Sprite_Sheet.png` (1024x512, 8 poses, 2 rows of 4)
2. `res://assets/sprites/enemies/Samurai_Enemy_Sprite_Sheet.png` (1024x682, 4 enemy classes + FX & extra)
3. `res://assets/sprites/traps/Dark_Trap_Sprite_Atlas.png` (1024x682, 10 traps + 6 extra projectiles)

---

## 1. Hero Sheet Reading Order & Coordinate Mapping

Reading order (Top row L-to-R, then Bottom row L-to-R):
1. **Pose 1 (`hero_idle_0`)**: Standing neutral pose facing right, scarf trailing, sword sheathed/held down back.
2. **Pose 2 (`hero_run_0`)**: Forward stride phase A (left forward, right back, forward lean).
3. **Pose 3 (`hero_run_1`)**: Forward stride phase B (opposite leg forward, continuous momentum).
4. **Pose 4 (`hero_jump_0`)**: Leaping airborne rise / apex tuck with drawn sword.
5. **Pose 5 (`hero_attack_heavy_0`)**: Two-handed high overhead windup (heavy attack / breaker).
6. **Pose 6 (`hero_attack_thrust_0`)**: Deep lunge forward thrust with horizontal reach (Katana combo 2 / Naginata reach).
7. **Pose 7 (`hero_crouch_0`)**: Low crouch / sneak stance, one knee to floor, hands braced.
8. **Pose 8 (`hero_hurt_0`)**: Mid-air recoil knockback, chest arched, arms splayed, sword flung back.

### Hero Pose Bounding Boxes & Sliced Dimensions

| Pose Name | Atlas Rect `(x0, y0, x1, y1)` | Sliced Trimmed Size | Pivot Anchor | Collision Match & Target Height |
|---|---|---|---|---|
| `hero_idle_0` | `(40, 85, 245, 245)` | 200 x 158 px | Bottom-Center (100, 158) | Scaled 0.24x -> 38px visual, matches 18px capsule |
| `hero_run_0` | `(250, 100, 420, 245)` | 166 x 144 px | Bottom-Center (83, 144) | Scaled 0.24x -> 35px visual |
| `hero_run_1` | `(505, 100, 680, 245)` | 171 x 144 px | Bottom-Center (85, 144) | Scaled 0.24x -> 35px visual |
| `hero_jump_0` | `(745, 75, 1000, 240)` | 254 x 161 px | Center-Bottom (127, 161) | Scaled 0.24x -> airborne clearance |
| `hero_attack_heavy_0` | `(35, 280, 200, 455)` | 160 x 173 px | Bottom-Center (80, 173) | Heavy strike startup & active frame |
| `hero_attack_thrust_0` | `(240, 325, 515, 455)` | 275 x 126 px | Bottom-Center (137, 126) | Extended reach forward hitbox |
| `hero_crouch_0` | `(520, 350, 695, 455)` | 169 x 104 px | Bottom-Center (84, 104) | Scaled 0.24x -> 25px crouch height |
| `hero_hurt_0` | `(750, 305, 1005, 455)` | 252 x 150 px | Center (126, 75) | Recoil knockback |

*Readability note:* Hero is pure white `#FFFFFF` with black inner markings. A subtle 1px drop contour or unshaded canvas item outline preserves readability against lit lanterns and brighter parallax backgrounds.

---

## 2. Enemy Sheet Coordinate Mapping

Atlas Size: 1024 x 682. Black background removed to true alpha with smooth anti-aliased edge thresholding.

### Sword Enemy (Ronin) — Row 1 (y: 20..110)
- `ronin_idle_0`: `(20, 20, 85, 110)` -> 65 x 90 px, Bottom pivot
- `ronin_walk_0`: `(125, 20, 215, 110)` -> 90 x 90 px, Bottom pivot
- `ronin_run_0`: `(220, 20, 315, 110)` -> 95 x 88 px, Bottom pivot
- `ronin_attack1_0`: `(350, 20, 450, 110)` -> 100 x 88 px, Bottom pivot
- `ronin_attack2_0`: `(460, 20, 570, 110)` -> 110 x 88 px, Bottom pivot
- `ronin_attack3_0`: `(570, 20, 735, 110)` -> 165 x 90 px, Bottom pivot (Spin slash with arc)
- `ronin_hurt_0`: `(755, 20, 840, 110)` -> 85 x 86 px, Bottom pivot
- `ronin_die_0`: `(840, 20, 1015, 110)` -> 175 x 74 px, Bottom pivot (Corpse on ground)

### Archer Enemy — Row 2 (y: 130..228)
- `archer_idle_0`: `(25, 130, 95, 228)` -> 70 x 96 px, Bottom pivot
- `archer_walk_0`: `(130, 130, 205, 228)` -> 75 x 94 px, Bottom pivot
- `archer_run_0`: `(240, 130, 325, 228)` -> 85 x 92 px, Bottom pivot
- `archer_aim_0`: `(370, 130, 450, 228)` -> 80 x 95 px, Bottom pivot
- `archer_shoot_0`: `(470, 130, 560, 228)` -> 90 x 94 px, Bottom pivot
- `archer_shoot_release_0`: `(590, 130, 675, 228)` -> 85 x 92 px, Bottom pivot
- `archer_arrow_in_flight_0`: `(675, 160, 765, 210)` -> 90 x 15 px, Center pivot (Fired projectile)
- `archer_hurt_0`: `(785, 130, 860, 228)` -> 75 x 90 px, Bottom pivot
- `archer_die_0`: `(865, 130, 1015, 228)` -> 150 x 50 px, Bottom pivot

### Spear Enemy — Row 3 (y: 260..360)
- `spear_idle_0`: `(15, 260, 80, 360)` -> 65 x 98 px, Bottom pivot
- `spear_walk_0`: `(105, 260, 215, 360)` -> 110 x 96 px, Bottom pivot
- `spear_run_0`: `(230, 260, 340, 360)` -> 110 x 94 px, Bottom pivot
- `spear_thrust_0`: `(360, 260, 540, 360)` -> 180 x 90 px, Bottom pivot (Extended forward reach)
- `spear_sweep_0`: `(545, 260, 730, 360)` -> 185 x 92 px, Bottom pivot (High overhead sweep)
- `spear_hurt_0`: `(755, 260, 840, 360)` -> 85 x 90 px, Bottom pivot
- `spear_die_0`: `(845, 260, 1015, 360)` -> 170 x 60 px, Bottom pivot

### Heavy Enemy (Brute) — Row 4 (y: 380..510)
- `brute_idle_0`: `(10, 380, 105, 510)` -> 95 x 120 px, Bottom pivot
- `brute_walk_0`: `(130, 380, 240, 510)` -> 110 x 120 px, Bottom pivot
- `brute_run_0`: `(265, 380, 360, 510)` -> 95 x 118 px, Bottom pivot
- `brute_smash_0`: `(395, 380, 540, 510)` -> 145 x 121 px, Bottom pivot (Kanabo overhead slam)
- `brute_swing_0`: `(550, 380, 735, 510)` -> 185 x 118 px, Bottom pivot (Horizontal club cleave)
- `brute_hurt_0`: `(750, 380, 835, 510)` -> 85 x 117 px, Bottom pivot
- `brute_die_0`: `(845, 380, 1015, 510)` -> 170 x 75 px, Bottom pivot

### Projectiles, Effects & Extra — Row 5 (y: 535..630)
- `fx_arrow_0`: `(20, 560, 95, 620)` -> 75 x 16 px, Center pivot
- `fx_arrow_trail_0`: `(110, 560, 180, 620)` -> 70 x 18 px, Center pivot
- `fx_slash1_0`: `(195, 545, 315, 620)` -> 120 x 70 px, Center pivot (Wide arc)
- `fx_slash2_0`: `(335, 550, 410, 620)` -> 75 x 65 px, Center pivot (Tight crescent)
- `fx_spear_trail_0`: `(420, 560, 535, 620)` -> 115 x 24 px, Center pivot
- `fx_smash_impact_0`: `(550, 540, 685, 625)` -> 135 x 85 px, Bottom pivot (Ground shockwave debris)
- `fx_hit_spark_0`: `(735, 540, 795, 620)` -> 60 x 60 px, Center pivot (Radial burst)
- `fx_blood_splat_0`: `(810, 540, 895, 620)` -> 85 x 75 px, Center pivot (Toggleable in Settings)
- `fx_dust_0`: `(910, 560, 1015, 620)` -> 105 x 45 px, Bottom pivot (Landing / evade cloud)

---

## 3. Dark Trap Sprite Atlas Mapping (12 Traps & Projectiles)

Atlas Size: 1024 x 682. Pure black background removed to true alpha.

| Trap Name | States / Frames | Sliced Names | Trigger & Behavior |
|---|---|---|---|
| **Floor Spikes** | Idle, Trigger, Rising 1-2, Full Up, Reset 1-2, Hidden | `floor_spikes_idle_0`, `trigger_0`, `rising_0/1`, `full_0`, `reset_0/1`, `hidden_0` | Pressure plate or proximity trigger; spikes extend upward dealing 2 DMG |
| **Ceiling Spikes** | Idle, Dropping 1-2, Full Drop, Reset | `ceiling_spikes_idle_0`, `drop_0/1`, `full_0`, `reset_0` | Drops on detection below with dust tell; lethal crush |
| **Swinging Blade** | Idle, Swing Left, Center, Right, Back Left | `swinging_blade_idle_0`, `swing_left_0`, `swing_center_0`, `swing_right_0`, `back_left_0` | Continuous pendulum motion with dynamic arc damage hitbox |
| **Horizontal Blade** | Idle, Extend 1-2, Full Attack, Retract 1-2, Hidden | `wall_blade_idle_0`, `extend_0/1`, `attack_0`, `retract_0/1`, `hidden_0` | Periodic rhythmic wall thrust with red danger tell |
| **Arrow Trap** | Idle, Aim, Shoot, Arrow Proj, Retract | `arrow_trap_idle_0`, `aim_0`, `shoot_0`, `arrow_proj_0`, `retract_0` | Wall launcher; arrow is deflectable by player parry |
| **Spear Launcher** | Idle, Charge, Launch, Spear Proj, Retract | `spear_launcher_idle_0`, `charge_0`, `launch_0`, `spear_proj_0`, `retract_0` | High velocity floor/wall bolt with linear hitbox |
| **Falling Rock** | Idle, Crack, Fall 1-2, Impact, Reset | `falling_rock_idle_0`, `crack_0`, `fall_0/1`, `impact_0`, `reset_0` | Ceiling tremor telegraph -> falls with crushing AoE impact |
| **Rolling Boulder** | Idle, Roll 1, Roll 2, Roll 3, Roll 4 | `rolling_boulder_idle_0`, `roll_0..3` | Released on trigger; rolls along slope/floor, crushing everything |
| **Guillotine** | Idle, Dropping 1-2, Full Drop, Reset | `guillotine_idle_0`, `drop_0/1`, `full_0`, `reset_0` | Heavy vertical blade; timed or proximity drop with reset winch |
| **Fire Trap** | Idle, Charge, Flame 1-2, Off | `fire_trap_idle_0`, `charge_0`, `flame_0/1`, `off_0` | Jet nozzle; pre-ignition spark -> intense flame column |
| **Extra Projectiles** | Knife, Spear, Fireball, Dart, Spike Ball, Chain Blade | `projectiles_knife_0`, `spear_0`, `fireball_0`, `dart_0`, `spike_ball_0`, `chain_blade_0` | Reusable projectiles across traps and special enemy attacks |

---

## 4. Contact Sheet Verification
Generated visual contact sheet with labeled bounds, names, and resolutions:
- File path: [`docs/contact_sheet_preview.png`](file:///c:/vibe-game/docs/contact_sheet_preview.png)
- Total Sliced Sprites: 110 assets
- JSON Manifest: [`assets/sprites/sprite_manifest.json`](file:///c:/vibe-game/assets/sprites/sprite_manifest.json)
