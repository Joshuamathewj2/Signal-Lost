# SIGNAL LOST - COLLISION LAYER ARCHITECTURE
**Document:** `/docs/COLLISION_LAYERS.md`  
**Engine:** Godot 4.7.2 (2D Physics Engine)  
**Standardized Bitmasks & Collision Matrix**

---

## 1. Physics Layer Allocation (1-Indexed)

| Layer # | Bit Value | Name | Description & Entity Types |
|---|---|---|---|
| **Layer 1** | `1` (bit 0) | `world` | Static terrain, solid walls (`#`), ground blocks, sealed blast doors. |
| **Layer 2** | `2` (bit 1) | `one_way` | Drop-through catwalks and thin platforms (`=`). |
| **Layer 3** | `4` (bit 2) | `player` | Player CharacterBody2D, Player Hitbox, and Player Hurtbox. |
| **Layer 4** | `8` (bit 3) | `enemy` | Enemy CharacterBody2D (Guard, Spearman, Brute, Sentry), Enemy Hitbox, Enemy Hurtbox. |
| **Layer 5** | `16` (bit 4) | `interactable` | Collectibles & triggers: Keycards (`K`), Terminals (`E`), Lanterns (`Y`), Panels (`R`), Fragments (`F`), Hint Signs (`?`). |
| **Layer 6** | `32` (bit 5) | `projectile` | Kinetic projectiles: Thrown Shurikens, Sentry energy orbs, reflected bolts. |
| **Layer 7** | `64` (bit 6) | `hazard_kill` | Instakill environmental volumes (death barriers, crushing gears, electrified hazards). |

---

## 2. Interaction & Collision Mask Matrix

| Node / Component | Collision Layer | Collision Mask | Rationale |
|---|---|---|---|
| **Player Body** (`CharacterBody2D`) | `3` (`4`) | `1, 2, 5` (`1 + 2 + 16 = 19`) | Collides with solid geometry and one-way platforms; scans interactables. |
| **Player Hitbox** (`HitboxComponent`) | `3` (`4`) | `4` (`8`) | Detects Enemy Hurtboxes (Layer 4) when weapon slashes are active. |
| **Player Hurtbox** (`HurtboxComponent`) | `3` (`4`) | `4, 6, 7` (`8 + 32 + 64 = 104`) | Receives hits from Enemy Hitboxes (Layer 4), Projectiles (Layer 6), and Hazards (Layer 7). |
| **Enemy Body** (`CharacterBody2D`) | `4` (`8`) | `1, 2` (`1 + 2 = 3`) | Walks on solid geometry and one-way platforms. |
| **Enemy Hitbox** (`HitboxComponent` / `Hitbox`) | `4` (`8`) | `3` (`4`) | Detects Player Hurtbox (Layer 3) during strikes. |
| **Enemy Hurtbox** (`HurtboxComponent`) | `4` (`8`) | `3, 6` (`4 + 32 = 36`) | Receives hits from Player Hitbox (Layer 3) and Player Projectiles (Layer 6). |
| **Shuriken** (`Projectile`) | `6` (`32`) | `1, 4` (`1 + 8 = 9`) | Collides with walls (emits clatter noise event) and hits Enemy Hurtboxes. |
| **Sentry Bolt** (`Projectile`) | `6` (`32`) | `1, 3` (`1 + 4 = 5`) | Collides with walls and hits Player Hurtbox. When parried/deflected, flips mask to `1, 4`. |
| **Interactables** (`Area2D`) | `5` (`16`) | `3` (`4`) | Triggers when overlapped by Player Body. |

---

## 3. Strict Rules & Verification

1. **Hitboxes must never stay enabled**: All `HitboxComponent` nodes must have `monitoring = false` and `monitorable = false` while idle. They are only enabled during active combat frames.
2. **Hurtbox Interception**: When the player is in `PARRY` state (6-frame window), incoming hits on the player's hurtbox trigger `intercept_hit()`, deflecting projectiles and staggering melee attackers rather than damaging health.
3. **Drop-Through Platforms**: When dropping through Layer 2 (`one_way`), the player temporarily disables mask bit 2 for `drop_through_time` (0.2s), then restores it upon passing through.
