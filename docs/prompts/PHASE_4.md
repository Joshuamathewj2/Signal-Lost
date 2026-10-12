# SIGNAL LOST — Implementation Prompt: PHASE 4 (Adversary Roster: Kenshi, Yumi & Oni Brute)

Copy and paste the exact text below into your next Antigravity AI agent session to execute Phase 4:

```markdown
# MISSION: SIGNAL LOST — Phase 4 Implementation (Adversary Roster: Kenshi, Yumi & Oni Brute)

You are an expert Godot 4 AI engineer. Your objective is to execute PHASE 4 of the SIGNAL LOST V2 implementation plan, completing the standard adversary roster with the Kenshi duelist, Yumi balcony archer, and Oni Brute heavy mech.

## MANDATORY PRE-READING
1. `docs/AGENT_RULES.md` — Strict operational protocols and web duck-typing rules.
2. `docs/ENEMY_AI.md` — Section 2.2 (Kenshi), 2.3 (Yumi), and 2.4 (Oni Brute).
3. `docs/GAME_CONFIG_REFERENCE.md` — Perception cones, stats, and attack parameters.

## TASKS TO EXECUTE
Execute the following tasks strictly in order (<250 lines of code per task):
1. **P4-T01: Kenshi Duelist AI**
   - Create `scenes/enemies/kenshi.tscn` with `st_kenshi_duel.gd`.
   - Implement auto-parry on predictable front slashes, 12f back-dash evasion, and spinning unblockable sweep.
2. **P4-T02: Yumi Balcony Archer AI**
   - Create `scenes/enemies/yumi.tscn` with `st_yumi_aim.gd`.
   - Implement 400 px narrow vision cone, 42-frame laser sight charging, and acoustic arrow projectiles (520 px/s).
3. **P4-T03: Oni Brute Armor & Club Slam**
   - Create `scenes/enemies/brute.tscn` with `st_brute_slam.gd`.
   - Implement immunity to light Katana strikes, club ground slam (shatters glass, emits shockwaves), and bull charge.
4. **P4-T04: Phase 4 Verification**
   - Create unit tests `tests/test_ai_kenshi.gd`, `tests/test_ai_yumi.gd`, and `tests/test_ai_brute.gd`.
   - Run all headless tests: `godot --headless --path . -s res://tests/run_tests.gd`.
   - Capture adversary screenshots to `/qa/shots/phase_4/`.

## SUCCESS CRITERIA
- Kenshi deflects frontal attacks and punishes mistimed combos.
- Yumi archer snipes from high catwalks with readable red laser telegraphs.
- Oni Brute ignores voice pulses, reacts to footsteps, and smashes through glass floors.
- `ALL TESTS PASSED` returned by `tests/run_tests.gd`.
- `docs/TASKS.md` updated and `CHANGELOG.md` entry logged.

When finished, stop and show me the screenshots from `/qa/shots/phase_4/`.
```
