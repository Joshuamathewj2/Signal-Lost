# SIGNAL LOST — Implementation Prompt: PHASE 8 (Shogun Mech Boss & Audio Polish)

Copy and paste the exact text below into your next Antigravity AI agent session to execute Phase 8:

```markdown
# MISSION: SIGNAL LOST — Phase 8 Implementation (Shogun Mech Boss & Audio Polish)

You are an expert Godot 4 boss designer and audio engineer. Your objective is to execute PHASE 8 of the SIGNAL LOST V2 implementation plan, implementing the 3-phase Shogun Mech climax boss in Sector 9 and deploying dynamic taiko combat music.

## MANDATORY PRE-READING
1. `docs/AGENT_RULES.md` — Strict operational protocols and web duck-typing rules.
2. `docs/ENEMY_AI.md` — Section 3 (Boss Encounter: The Shogun Mech).
3. `docs/AUDIO_SPEC.md` — Section 2 (Sound Effect Recipes) and Section 3 (Dynamic Music Layering).
4. `docs/UI_UX_SPEC.md` — Section 2.3 (Boss Vitality & Stance Gauge).

## TASKS TO EXECUTE
Execute the following tasks strictly in order (<250 lines of code per task):
1. **P8-T01: Shogun Mech Phases 1 & 2**
   - Create `scenes/enemies/boss_shogun.tscn` (18 HP segments, 200 poise).
   - Implement Phase 1 (twin Naginata sweeps) and Phase 2 (arena-wide acoustic shockwaves, Ashigaru summons).
2. **P8-T02: Shogun Mech Phase 3 & Climax Arena**
   - Implement Phase 3 (blackout sonic dash, berserk 5-hit flurry, electrified floor catwalks).
3. **P8-T03: Boss Vitality & Poise Gauge**
   - Create `scenes/ui/boss_health_bar.gd`. Render bottom-center 480 px health and poise gauge during Sector 9.
4. **P8-T04: Dynamic Music Taiko Cross-Fader**
   - Upgrade `audio/music_layers.gd` to cross-fade ambient drone to 138 BPM driving taiko percussion upon `GameState.detected()`.
5. **P8-T05: Procedural Combat SFX Library**
   - Expand `audio/sfx_library.gd` with synthesized metallic clangs, parry deflect rings, arrow whistles, and blade swooshes.
6. **P8-T06: Phase 8 Verification**
   - Create unit test `tests/test_boss_shogun.gd`.
   - Run all headless tests: `godot --headless --path . -s res://tests/run_tests.gd`.
   - Capture boss combat screenshots to `/qa/shots/phase_8/`.

## SUCCESS CRITERIA
- Shogun Mech executes 3 distinct combat phases with readable telegraphs and phase transition markers.
- Dynamic music cross-fades seamlessly into taiko percussion without audio pops or clipping.
- Boss health bar tracks HP segments and flashes on poise stagger.
- `ALL TESTS PASSED` returned by `tests/run_tests.gd`.
- `docs/TASKS.md` updated and `CHANGELOG.md` entry logged.

When finished, stop and show me the screenshots from `/qa/shots/phase_8/`.
```
