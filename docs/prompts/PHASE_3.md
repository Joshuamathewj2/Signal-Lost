# SIGNAL LOST — Implementation Prompt: PHASE 3 (Adversary Roster: Ashigaru & Sentry)

Copy and paste the exact text below into your next Antigravity AI agent session to execute Phase 3:

```markdown
# MISSION: SIGNAL LOST — Phase 3 Implementation (Adversary Roster: Ashigaru & Sentry)

You are an expert Godot 4 AI and combat engineer. Your objective is to execute PHASE 3 of the SIGNAL LOST V2 implementation plan, integrating combat components into `EnemyBase`, implementing the Ashigaru spearman, and enhancing the Sentry turret.

## MANDATORY PRE-READING
1. `docs/AGENT_RULES.md` — Strict operational protocols and web duck-typing rules.
2. `docs/ENEMY_AI.md` — Section 1 (Shared Perception) and Section 2.1 (Ashigaru) & 2.5 (Sentry).
3. `docs/COMBAT_DESIGN.md` — Attack token concurrency and parry deflect interaction.
4. `docs/GAME_CONFIG_REFERENCE.md` — Enemy health, poise, and telegraph windows.

## TASKS TO EXECUTE
Execute the following tasks strictly in order (<250 lines of code per task):
1. **P3-T01: EnemyBase Combat Integration**
   - Refactor `scenes/enemies/enemy_base.gd` to include child `HealthComponent`, `PoiseComponent`, and `HurtboxComponent`.
   - Ensure enemies take typed weapon damage, flash white on impact, and enter Stagger when poise reaches 0.
2. **P3-T02: Ashigaru Spearman AI & FSM**
   - Create `scenes/enemies/ashigaru.tscn` inheriting from `EnemyBase`.
   - Implement `st_thrust.gd` with 27-frame telegraph glint and 44 px spear thrust.
3. **P3-T03: Attack Token Concurrency Integration**
   - Wire `AttackTokenManager.request_token(self)` before enemy initiates attack startup.
   - Release token upon attack recovery or stagger. If denied, enemy circles defensively.
4. **P3-T04: Sentry Deflect Interaction**
   - Update `scenes/enemies/projectile.gd` and `sentry.gd` to allow Katana parries to deflect plasma bolts back at the turret.
5. **P3-T05: Phase 3 Verification**
   - Create unit test `tests/test_ai_ashigaru.gd`. Run browser test `tests/e2e/test_step_e.js`.
   - Run all headless tests: `godot --headless --path . -s res://tests/run_tests.gd`.
   - Capture combat duel screenshots to `/qa/shots/phase_3/`.

## SUCCESS CRITERIA
- Ashigaru patrols, investigates noise, telegraphs spear thrust with red glint, and staggers upon parry.
- No more than 2 enemies attack simultaneously.
- Sentry bolts can be deflected back to destroy the turret.
- `ALL TESTS PASSED` returned by `tests/run_tests.gd`.
- `docs/TASKS.md` updated and `CHANGELOG.md` entry logged.

When finished, stop and show me the screenshots from `/qa/shots/phase_3/`.
```
