# SIGNAL LOST — Implementation Prompt: PHASE 9 (Final Hardening, Web Soak Pass & Release Gate)

Copy and paste the exact text below into your next Antigravity AI agent session to execute Phase 9:

```markdown
# MISSION: SIGNAL LOST — Phase 9 Implementation (Final Hardening, Web Soak Pass & Release Gate)

You are the Lead QA and Release Engineer. Your objective is to execute PHASE 9 of the SIGNAL LOST V2 implementation plan, running full campaign automated verification, executing a 60-second stability soak pass, validating the Web export, and compiling the master release evidence report.

## MANDATORY PRE-READING
1. `docs/AGENT_RULES.md` — The Ironclad Evidence Rule and zero-assumption reporting.
2. `docs/QA_TEST_PLAN.md` — Complete automated test case registry and Definition of Done.
3. `docs/TECH_STACK.md` — Web packaging rules and performance budgets.

## TASKS TO EXECUTE
Execute the following tasks strictly in order:
1. **P9-T01: Full Campaign Playthrough Pass**
   - Create and execute `tests/e2e/test_campaign_full.js` traversing Levels 1 through 9.
   - Assert all 9 sectors can be completed with valid victory screens and medal awards.
2. **P9-T02: Stability & Memory Soak Test**
   - Execute 60-second continuous gameplay soak loop via `tests/e2e/test_soak.js`.
   - Sample WebGL context status and memory leaks across 170+ sampled ticks. Assert zero errors.
3. **P9-T03: Performance & Quality Mode Benchmark**
   - Verify 60 FPS on integrated graphics baseline. Run `test_performance_mode.gd` to assert bubble count reduction (6 -> 4) and shadow toggling.
4. **P9-T04: Production Web Export Packaging**
   - Headless export release Web build to `build/web/index.html`.
   - Assert all 9 ASCII level files are packaged inside `index.pck`. Verify COOP/COEP isolation headers.
5. **P9-T05: Master Release Gate & Report**
   - Compile comprehensive QA verification report in `qa/QA_REPORT.md`.
   - Finalize `CHANGELOG.md` with V2 Release Milestone entry.
   - Capture final release screenshots to `/qa/shots/phase_9/`.

## SUCCESS CRITERIA
- 100% of campaign levels (1–9) verified playable with 0 soft-locks and 0 console errors.
- 60-second soak test passes with 0 memory leaks and 0 WebGL exceptions.
- Web export boots and runs at 60 FPS.
- `qa/QA_REPORT.md` and `CHANGELOG.md` 100% complete and verified.
- All 55 tasks in `docs/TASKS.md` marked completed (`[x]`).

When finished, stop and show me the screenshots from `/qa/shots/phase_9/`.
```
