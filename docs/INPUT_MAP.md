# SIGNAL LOST — Input Mapping & Controls Specification (V2)

- **Purpose**: Authoritative input action mappings across Keyboard, Mouse, and Gamepad controllers, detailing physical scan codes, conflict resolution matrices, and on-screen HUD prompt text.
- **Audience**: Gameplay Programmers, UI Designers, QA Engineers, AI Coding Agents.
- **Status**: Approved.
- **Last Updated**: 2026-10-11.
- **Depends On**: [00_CURRENT_STATE_AUDIT.md](file:///c:/vibe-game/docs/00_CURRENT_STATE_AUDIT.md), [GAME_CONFIG_REFERENCE.md](file:///c:/vibe-game/docs/GAME_CONFIG_REFERENCE.md).

---

## 1. Input Mapping Philosophy & Conflict Resolution

SIGNAL LOST V2 unifies stealth exploration, echolocation charging, and fast-paced samurai blade combat:
- **Left Hand / Movement Cluster**: `W/A/S/D` controls locomotion, crouching, and directional dropping.
- **Right Hand / Combat Cluster**: `J/K/L/I` or Mouse Buttons control weapon slashes, parrying, dodging, and heavy thrusts.
- **Thumb / Utility Cluster**: `Space` controls sonar pulse charging, while `F/G/E/H` manage tools, weapons, and hints.
- **Zero Input Conflict Rule**:
  - `Space` is dedicated to **Pulse Charging** (holding charges tier, release emits).
  - `W` / `Up Arrow` is dedicated to **Jump**.
  - `Shift` / `S` is dedicated to **Sneak** (and platform drop-through when combined with `W`/`Jump`).
  - `K` doubles as keyboard **Block / Parry**; tapping deflects incoming attacks, holding maintains guard.

---

## 2. Complete Input Mapping Matrix

Every action below is formatted with physical scan codes and Godot engine input constants.

| Action Identifier | Keyboard Primary | Keyboard Secondary / Mouse | Gamepad Binding (XInput) | Category | Status |
|---|---|---|---|---|---|
| `move_left` | `A` (Keycode 65) | `Left Arrow` (Keycode 4194319) | Left Stick −X, D-Pad Left | Locomotion | `[CURRENT]` |
| `move_right` | `D` (Keycode 68) | `Right Arrow` (Keycode 4194321) | Left Stick +X, D-Pad Right | Locomotion | `[CURRENT]` |
| `jump` | `W` (Keycode 87) | `Up Arrow` (Keycode 4194320) | Bottom Action (`A` / Cross) | Locomotion | `[CURRENT]` |
| `sneak` | `Shift` (Keycode 4194325) | `S` (Keycode 83), `Down Arrow` | Left Trigger (Axis 4), D-Pad Down | Locomotion | `[CURRENT]` |
| `pulse` | `Space` (Keycode 32) | `Left Mouse Button` | Right Trigger (Axis 5) | Sonar | `[CURRENT]` |
| `attack` (Light Slash) | `J` (Keycode 74) | `Right Mouse Button` | Left Action (`X` / Square) | Combat | `[PROPOSED]` |
| `attack_heavy` (Heavy) | `I` (Keycode 73) | `Middle Mouse Button` | Right Shoulder (`RB` / R1) | Combat | `[PROPOSED]` |
| `dash` (Evade / Roll) | `L` (Keycode 76) | `Alt` (Keycode 4194328) | Right Action (`B` / Circle) | Combat | `[PROPOSED]` |
| `block_parry` (Guard) | `K` (Keycode 75) | `Mouse Button 4` (Thumb) | Left Shoulder (`LB` / L1) | Combat | `[PROPOSED]` |
| `weapon_swap` | `Q` (Keycode 81) | `Mouse Wheel Up/Down` | D-Pad Up | Combat | `[PROPOSED]` |
| `ability_primary` (Decoy)| `F` (Keycode 70) | — | Top Action (`Y` / Triangle) | Sub-Weapon | `[CURRENT]` |
| `ability_secondary` (Grapple)| `E` (Keycode 69) | — | D-Pad Right | Sub-Weapon | `[CURRENT]` |
| `hint` (Exit Beacon) | `H` (Keycode 72) | — | D-Pad Down (Hold) | Utility | `[PROPOSED]` |
| `codex` (Fragment Logs)| `C` (Keycode 67) | — | Select / View (Button 4) | UI / Lore | `[PROPOSED]` |
| `restart` | `R` (Keycode 82) | — | Select / Back (Button 4) | System | `[CURRENT]` |
| `pause` | `Escape` (Keycode 4194305) | — | Start / Menu (Button 6) | System | `[CURRENT]` |
| `debug_toggle` | `F1` (Keycode 4194332) | — | — | Debug | `[CURRENT]` |
| `debug_next_page` | `F2` (Keycode 4194333) | — | — | Debug | `[CURRENT]` |

---

## 3. Conflict Resolution & Combo Inputs

1. **Catwalk Drop-Through (`drop_through`)**:
   - Resolved by checking `Input.is_action_pressed("sneak") and Input.is_action_just_pressed("jump")`.
   - Clears collision mask layer 2 (one-way platforms) for `0.20s`, allowing the player to fall through without jumping.
2. **Parry vs Guard Window**:
   - Action `block_parry` (`K` / `LB`):
   - If tapped and released within 6 frames ($\le 0.10s$), it is registered as an active **Parry Deflect**.
   - If held beyond 6 frames, the hero raises their weapon into **Sustained Guard**, absorbing 70% damage at the cost of poise.
3. **Attack Combo Buffer**:
   - Pressing `attack` during the recovery frames of Attack 1 buffers Attack 2; pressing during Attack 2 buffers Attack 3.
   - Buffering expires after `0.35s` without input, resetting the combo back to Attack 1.
4. **Stealth Assassination vs Normal Attack**:
   - `attack` triggers standard slash unless all 3 assassination prerequisites are met:
     - Distance to target $\le 28 \text{ px}$.
     - Facing angle aligns within 60° of target rear (behind target).
     - Target awareness $< 0.35$ (unaware).
   - If prerequisites are satisfied, `attack` locks input for 0.40s and executes the lethal **Assassination**.
5. **Special Combat Maneuvers**:
   - **Dash Slash** (`Dash` + `J` or `J` during Dash): Piercing forward dash slash (1 DMG, 20 poise, 180 knockback, 1.2s cooldown, invulnerable dash).
   - **Plunge Strike** (`Air` + `Down` + `J`): High-speed dive slam into ground shockwave (2 DMG, 50 poise, 64px AoE stun, smash impact particles).
   - **Rising Slash** (`Up` + `J`): Upward vaulting launch strike (2 DMG, 35 poise, 280 knockback launching enemies upward).
   - **Counter Strike (Riposte)** (`J` during 0.5s counter window following successful Parry Deflect): Lethal riposte (3 DMG, 60 poise, 360 knockback, visual flash & slow-mo).
   - **Kunai Toss** (`F` Subweapon): Aerodynamic silent projectile ($v = 600 \text{ px/s}$, 40 px acoustic radius, 1 DMG, 1.5s stun on impact).

---

## 4. On-Screen HUD Controls Prompts

To onboard new players naturally without immersion-breaking text walls, context-sensitive HUD glyphs appear:

| Context / State | Keyboard HUD Prompt | Gamepad HUD Prompt |
|---|---|---|
| **Level 1 Infiltration Start** | `[A]/[D] MOVE  •  [W] JUMP  •  [SPACE] PULSE` | `[L-STICK] MOVE  •  [A] JUMP  •  [RT] PULSE` |
| **Near Low Ceiling / Patrol** | `HOLD [SHIFT] TO SNEAK SILENTLY` | `HOLD [LT] TO SNEAK SILENTLY` |
| **Enemy Attack Telegraph Flash**| `TAP [K] TO PARRY  •  [L] DASH` | `TAP [LB] TO PARRY  •  [B] DASH` |
| **Behind Unaware Enemy** | `[J] ASSASSINATE` | `[X] ASSASSINATE` |
| **Stuck / Lost in Darkness** | `PRESS [H] FOR ACOUSTIC EXIT BEACON` | `HOLD [D-PAD DOWN] FOR EXIT BEACON` |
| **Near Resonance Panel** | `EMIT MATCHING PULSE TO RESONATE` | `EMIT MATCHING PULSE TO RESONATE` |
| **Weapon Acquired** | `PRESS [Q] TO SWAP WEAPON` | `PRESS [D-PAD UP] TO SWAP WEAPON` |
