# SIGNAL LOST — Implementation Prompt: PHASE 1 (Combat Primitives & Health Refactor)

Copy and paste the exact text below into your next Antigravity AI agent session to execute Phase 1:

```markdown
# MISSION: SIGNAL LOST — Phase 1 Implementation (Combat Primitives & Health Refactor)

You are an expert Godot 4 gameplay systems engineer. Your objective is to execute PHASE 1 of the SIGNAL LOST V2 implementation plan, replacing 1-hit death with 3-segment health, implementing poise/stagger, and wiring the Katana 3-hit combo.

## MANDATORY PRE-READING
1. `docs/AGENT_RULES.md` — Strict operational protocols and web duck-typing rules.
2. `docs/COMBAT_DESIGN.md` — Katana combo design, parry deflects, poise, and noise coupling.
3. `docs/COMBAT_FRAME_DATA.md` — Exact frame startup, active, and recovery timings at 60 FPS.
4. `docs/GAME_CONFIG_REFERENCE.md` — Tunable defaults for health, poise, dash, and parry.

## TASKS TO EXECUTE
Execute the following tasks strictly in order (<250 lines of code per task):
1. **P1-T01: HealthComponent Extraction**
   - Create `scenes/combat/health_component.gd` managing 3 integer segments, invulnerability flashing, and damage signals.
   - Wire into `scenes/player/player.gd`. Create automated unit test `tests/test_health_system.gd`.
2. **P1-T02: PoiseComponent & Stagger**
   - Create `scenes/combat/poise_component.gd` tracking balance meter (100.0 max), poise depletion, and stagger callbacks.
   - Create unit test `tests/test_combat_guard.gd`.
3. **P1-T03: Hitbox & Hurtbox Components**
   - Create `scenes/combat/hitbox_component.gd` and `hurtbox_component.gd` in `res://scenes/combat/`.
4. **P1-T04: CombatController & Katana 3-Hit Combo**
   - Create `scenes/player/combat_controller.gd`. Implement `J` 3-hit slash chain matching `COMBAT_FRAME_DATA.md`.
   - Wire noise emissions to `NoiseBus` (Slash 1: 180 px, Slash 2: 200 px, Slash 3: 280 px).
5. **P1-T05: Parry Deflect System**
   - Implement 6-frame parry window on `block_parry` (`K` / `LB`). Deflects attacks, inflicts 40 poise damage, grants 16 i-frames, and triggers 0.12s hit-stop.
   - Create unit test `tests/test_combat_parry.gd`.
6. **P1-T06: Hero Dash & I-Frames**
   - Implement 15-frame dash roll on `L` ($v = 400 \text{ px/s}$) with 12 i-frames and 0.50s cooldown.
7. **P1-T07: Phase 1 Verification**
   - Create and run `tests/test_combat_combo.gd`.
   - Run all headless tests: `godot --headless --path . -s res://tests/run_tests.gd`.
   - Capture combat screenshots to `/qa/shots/phase_1/`.

## SUCCESS CRITERIA
- Zero regression in player movement, sneaking, or pulse charging.
- Player sustains hits without instant reload; health bar segments deplete accurately.
- Katana 3-hit combo emits correct noise events on `NoiseBus`.
- `ALL TESTS PASSED` returned by `tests/run_tests.gd`.
- `docs/TASKS.md` updated and `CHANGELOG.md` entry logged.

When finished, stop and show me the screenshots from `/qa/shots/phase_1/`.
```
