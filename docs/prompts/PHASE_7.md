# SIGNAL LOST — Implementation Prompt: PHASE 7 (Visual Overhaul, Scarf Physics & Tactical HUD)

Copy and paste the exact text below into your next Antigravity AI agent session to execute Phase 7:

```markdown
# MISSION: SIGNAL LOST — Phase 7 Implementation (Visual Overhaul, Scarf Physics & Tactical HUD)

You are an expert Godot 4 technical artist and UI engineer. Your objective is to execute PHASE 7 of the SIGNAL LOST V2 implementation plan, upgrading the hero to an articulated samurai vector rig with Verlet scarf physics, redrawing enemy silhouettes, and deploying the tactical HUD.

## MANDATORY PRE-READING
1. `docs/AGENT_RULES.md` — Strict operational protocols and web duck-typing rules.
2. `docs/ART_DIRECTION.md` — Tri-color palette, silhouette sheets, Verlet scarf specs, and VFX rules.
3. `docs/UI_UX_SPEC.md` — Tactical HUD layout matching target reference image (`reference_expected.png`).

## TASKS TO EXECUTE
Execute the following tasks strictly in order (<250 lines of code per task):
1. **P7-T01: Samurai Hero Vector Rig**
   - Redraw `scenes/player/player_visual.gd` into a 54 px tall white articulated samurai silhouette with scabbard.
2. **P7-T02: Verlet Scarf Physics**
   - Create `scenes/player/visuals/scarf_physics.gd` implementing a 6-node Verlet integration scarf trailing hero movement.
3. **P7-T03: Enemy Silhouette Overhaul**
   - Redraw `Ashigaru` (jingasa, yari), `Kenshi` (cape, jodan stance), `Yumi` (hood, bow), and `Oni Brute` (horned helm, spiked club) with distinct vector silhouettes.
4. **P7-T04: Procedural Slash Arcs**
   - Create `scenes/fx/slash_arc.gd` and `shaders/slash_arc.gdshader`. Swings draw crisp white curved lines fading over 0.12s.
5. **P7-T05: Tactical Samurai HUD Overhaul**
   - Overhaul `scenes/ui/hud.gd` and `scenes/ui/hud.tscn` to match `reference_expected.png`:
     - Top-left: Level label, fragment diamond pips, tactical score counter.
     - Bottom-left: Active weapon badge (`[Q]`), 3-segment health bar, shuriken pips, battery gauge.
6. **P7-T06: Shoji Parallax Backgrounds**
   - Deploy 3-plane Parallax2D background in `scenes/world/background_builder.gd` with shoji lattices, gantries, and stone pillars.
7. **P7-T07: Phase 7 Verification**
   - Run browser tests `tests/e2e/test_step_c.js` and `tests/e2e/test_step_d.js`.
   - Run all headless tests: `godot --headless --path . -s res://tests/run_tests.gd`.
   - Capture visual comparison screenshots to `/qa/shots/phase_7/`.

## SUCCESS CRITERIA
- Hero renders as an imposing 54 px white samurai with a flowing Verlet scarf.
- Enemies possess unmistakable, distinct red silhouettes visible across screen distances.
- HUD matches `reference_expected.png` layout with Rajdhani typography and segmented health blocks.
- `ALL TESTS PASSED` returned by `tests/run_tests.gd`.
- `docs/TASKS.md` updated and `CHANGELOG.md` entry logged.

When finished, stop and show me the screenshots from `/qa/shots/phase_7/`.
```
