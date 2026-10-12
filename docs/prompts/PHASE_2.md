# SIGNAL LOST — Implementation Prompt: PHASE 2 (Weapon Arsenal & Stealth Assassinations)

Copy and paste the exact text below into your next Antigravity AI agent session to execute Phase 2:

```markdown
# MISSION: SIGNAL LOST — Phase 2 Implementation (Weapon Arsenal & Stealth Assassinations)

You are an expert Godot 4 combat and weapons programmer. Your objective is to execute PHASE 2 of the SIGNAL LOST V2 implementation plan, implementing the Naginata spear, Twin Kunai daggers, weapon swapping, and rear stealth assassinations.

## MANDATORY PRE-READING
1. `docs/AGENT_RULES.md` — Strict operational protocols and web duck-typing rules.
2. `docs/COMBAT_DESIGN.md` — Section 2 (Three Primary Weapons) and Section 4 (Assassinations).
3. `docs/COMBAT_FRAME_DATA.md` — Naginata and Twin Kunai frame startup, active, and recovery timings.
4. `docs/GAME_CONFIG_REFERENCE.md` — Noise radii and weapon reach parameters.

## TASKS TO EXECUTE
Execute the following tasks strictly in order (<250 lines of code per task):
1. **P2-T01: Weapon Swap Manager**
   - Create `scenes/player/combat/weapon_swap.gd` handling `weapon_swap` action (`Q` / `D-Pad Up`).
   - Smoothly cycles active weapon and updates HUD weapon badge icon.
2. **P2-T02: Naginata Spear Implementation**
   - Create `scenes/player/combat/weapon_naginata.gd`.
   - Implement 52 px reach thrusts, group piercing (up to 2 targets), and vertical upward hits for ceiling switches.
3. **P2-T03: Twin Kunai Flurry Implementation**
   - Create `scenes/player/combat/weapon_kunai.gd`.
   - Implement rapid 4-hit flurry (0.18s recovery, 20 px reach) with low noise profile ($\le 90 \text{ px}$).
4. **P2-T04: Stealth Assassination System**
   - Create `scenes/player/combat/assassination.gd`.
   - Detect rear unaware guards ($\le 28 \text{ px}$, rear 60° cone, awareness $< 0.35$).
   - Execute instant lethal 0.40s takedown animation with muted audio (60 px noise).
5. **P2-T05: Sub-Weapon Shuriken**
   - Create `scenes/player/subweapons/shuriken.gd`. Wire `F` key to throw physical shuriken ($v = 580 \text{ px/s}$) for remote distractions.
6. **P2-T06: Phase 2 Verification**
   - Create and run `tests/test_combat_weapons.gd` and `tests/test_combat_stealth.gd`.
   - Run all headless tests: `godot --headless --path . -s res://tests/run_tests.gd`.
   - Capture weapon swap and assassination screenshots to `/qa/shots/phase_2/`.

## SUCCESS CRITERIA
- Player can seamlessly switch between Katana, Naginata, and Kunai on `Q`.
- Naginata pierces aligned enemies and triggers high ceiling switches.
- Rear takedowns instantly eliminate unaware guards without alarming distant rooms.
- `ALL TESTS PASSED` returned by `tests/run_tests.gd`.
- `docs/TASKS.md` updated and `CHANGELOG.md` entry logged.

When finished, stop and show me the screenshots from `/qa/shots/phase_2/`.
```
