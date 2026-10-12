# SIGNAL LOST — Implementation Prompt: PHASE 5 (Vertical Level Pipeline & Zero Soft-Locks)

Copy and paste the exact text below into your next Antigravity AI agent session to execute Phase 5:

```markdown
# MISSION: SIGNAL LOST — Phase 5 Implementation (Vertical Level Pipeline & Zero Soft-Locks)

You are an expert Godot 4 level designer and tool programmer. Your objective is to execute PHASE 5 of the SIGNAL LOST V2 implementation plan, ingesting the 9-level vertical campaign, eliminating all vertical soft-locks, and upgrading the automated level validator.

## MANDATORY PRE-READING
1. `docs/AGENT_RULES.md` — Strict operational protocols and regression safety.
2. `docs/LEVEL_DESIGN_V2.md` — Section 1 (Traversal Rules), Section 2 (Validator Specs), and Section 4 (Levels 1–9 Maps).
3. `docs/GAME_CONFIG_REFERENCE.md` — Hero jump apex (2.7 tiles) and maximum gap (3.5 tiles).

## TASKS TO EXECUTE
Execute the following tasks strictly in order (<250 lines of code per task):
1. **P5-T01: LevelValidator Reachability Upgrade**
   - Update `scenes/level/level_validator.gd` to simulate bidirectional reachability on directed `PlatformGraph`.
   - Assert every downward drop has a verified return route.
2. **P5-T02: Level 3 Architecture Refactor**
   - Refactor `levels/level_03.txt`. Create `scenes/interactables/ladder.gd` triggered by an overhead release latch.
   - Assert player can drop to bottom floor, collect Keycard `K`, and re-ascend to Exit `E`.
3. **P5-T03: Levels 1, 2, 4 Map Ingestion**
   - Update `levels/level_01.txt`, `level_02.txt`, and `level_04.txt` with multi-tier vertical layouts per spec.
4. **P5-T04: Levels 5, 6, 7 Map Ingestion**
   - Update `levels/level_05.txt`, `level_06.txt`, and `level_07.txt` incorporating puzzle nodes and vents.
5. **P5-T05: Levels 8, 9 Map Ingestion**
   - Update `levels/level_08.txt` and `level_09.txt` (Redoubt Perimeter & Shogun Citadel).
6. **P5-T06: Dynamic Camera Framing**
   - Update `scenes/fx/camera_rig.gd` with 48 px look-ahead and dynamic combat zoom (1.8x base, 1.45x combat).
7. **P5-T07: Phase 5 Verification**
   - Run `test_validator.gd` headlessly: `godot --headless -s res://tests/run_tests.gd`.
   - Verify 100% reachability across Levels 1 through 9 with 0 errors.
   - Capture vertical framing screenshots to `/qa/shots/phase_5/`.

## SUCCESS CRITERIA
- Zero soft-locks across all 9 levels; all levels validated by `test_validator.gd`.
- Level 3 soft-lock completely eliminated with working return ladder.
- Viewport fills screen vertically without dead void borders.
- `ALL TESTS PASSED` returned by `tests/run_tests.gd`.
- `docs/TASKS.md` updated and `CHANGELOG.md` entry logged.

When finished, stop and show me the screenshots from `/qa/shots/phase_5/`.
```
