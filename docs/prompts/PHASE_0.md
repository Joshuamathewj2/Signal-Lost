# SIGNAL LOST — Implementation Prompt: PHASE 0 (Architectural Hygiene & Baseline Verification)

Copy and paste the exact text below into your next Antigravity AI agent session to execute Phase 0:

```markdown
# MISSION: SIGNAL LOST — Phase 0 Implementation (Architectural Hygiene & Regression Setup)

You are an expert Godot 4 systems engineer. Your objective is to execute PHASE 0 of the SIGNAL LOST V2 implementation plan, preparing input actions, combat singletons, and verifying that zero V1 systems regress.

## MANDATORY PRE-READING (Read these docs before authoring any code)
1. `docs/AGENT_RULES.md` — Strict operational protocols, protected systems, and web duck-typing rules.
2. `docs/ARCHITECTURE.md` — Target architecture, folder structure, and singleton registry.
3. `docs/IMPLEMENTATION_PLAN.md` — Detailed Phase 0 deliverables and task breakdown.
4. `docs/INPUT_MAP.md` — Exact scan codes and bindings for new combat actions.

## TASKS TO EXECUTE
Execute the following 4 tasks strictly in order:
1. **P0-T01: Input Map Expansion**
   - Open `project.godot` and register new V2 actions: `attack`, `attack_heavy`, `dash`, `block_parry`, `weapon_swap`, `hint`.
   - Configure exact keyboard, mouse, and gamepad bindings per `docs/INPUT_MAP.md`.
2. **P0-T02: AttackTokenManager Singleton**
   - Create `autoload/attack_token_manager.gd` with single responsibility: enforce enemy attack concurrency cap (max 2 active tokens).
   - Register singleton in `project.godot` under `[autoload]`.
3. **P0-T03: Combat Configuration Resources**
   - Create `scripts/resources/attack_data.gd` defining typed AttackData resource.
   - Create `resources/config/combat_config.tres` with default combat parameters per `docs/GAME_CONFIG_REFERENCE.md`.
4. **P0-T04: Baseline Regression Gate**
   - Run headless syntax check: `godot --headless --path . --quit-after 120`.
   - Run all 17 headless unit tests: `godot --headless --path . -s res://tests/run_tests.gd`.
   - Run Playwright Gate A: `node tests/e2e/test_gate_a.js`.
   - Save verification screenshots to `/qa/shots/phase_0/`.

## SUCCESS CRITERIA
- `project.godot` parses cleanly with 0 syntax warnings.
- `AttackTokenManager` successfully initializes in tree.
- `ALL TESTS PASSED` returned by `res://tests/run_tests.gd`.
- `CHANGELOG.md` updated with Phase 0 completion entry.
- `docs/TASKS.md` checkboxes for P0-T01 through P0-T04 checked off.

When finished, stop and show me the screenshots from `/qa/shots/phase_0/`.
```
