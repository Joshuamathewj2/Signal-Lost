# SIGNAL LOST — Autonomous AI Agent Operating Rules & Protocols (V2)

- **Purpose**: Non-negotiable operational protocols, engineering constraints, safety rules, evidence requirements, and commit conventions for all AI coding agents working on the SIGNAL LOST codebase.
- **Audience**: AI Coding Agents (Gemini, Claude Sonnet/Opus, GPT), Pair Programming Assistants.
- **Status**: Approved.
- **Last Updated**: 2026-10-12.
- **Depends On**: [00_CURRENT_STATE_AUDIT.md](file:///c:/vibe-game/docs/00_CURRENT_STATE_AUDIT.md), [ARCHITECTURE.md](file:///c:/vibe-game/docs/ARCHITECTURE.md), [QA_TEST_PLAN.md](file:///c:/vibe-game/docs/QA_TEST_PLAN.md).

---

## 1. The Prime Directives (Non-Negotiable Rules)

1. **Rule 1: Never Break Protected Systems**.
   Under no circumstances may you alter or refactor the core contracts of the 7 Protected Systems without explicit approval:
   - Sonar Pulse Wavefront Expansion (`SonarSystem`, `sonar_air.gdshader`).
   - Darkness & 2D Light Occlusion (`CanvasModulate` `#000000`, `flat_reveal.gdshader`).
   - In-Engine Procedural Audio Synthesis (`audio/synth.gd`, `sfx_library.gd`).
   - Acoustic Noise Physics Bus (`autoload/noise_bus.gd`, `NoiseEvent`).
   - Core Tactical HUD Base (`scenes/ui/hud.gd`, `battery_bar.gd`).
   - Headless WebAssembly Build & Export (`export_presets.cfg`, `tools/serve.js`).
   - Playwright E2E Test Loop & Debug Bridge (`autoload/debug_bridge.gd`, `window.__SL`).
2. **Rule 2: Read Documentation First**.
   Before authoring or modifying any code, you must read the primary specification documents governing that subsystem (e.g., read `COMBAT_DESIGN.md` before touching player combat; read `ENEMY_AI.md` before altering adversary states).
3. **Rule 3: One Task per Session ($\le 250$ Lines of Code)**.
   Confine every development session to a single discrete task from `TASKS.md`. Never attempt sprawling multi-system refactors in a single pass. Target $< 250$ lines of changed code per session.
4. **Rule 4: Zero Assumption of Success (The Evidence Rule)**.
   Never report a task as "done", "fixed", or "passing" based on theoretical expectations. You must run the automated test suite, observe real exit codes, and archive screenshot evidence in `/qa/shots/`.
5. **Rule 5: Honest Failure Reporting**.
   If a test fails or a regression occurs, report the exact error message and stack trace immediately. Never silently comment out assertions, suppress errors, or fake test passes.

---

## 2. Coding Standards & Web Export Safety

### 2.1 Strictly Typed GDScript
- Every variable, parameter, and function return must declare an explicit type:
  ```gdscript
  # FORBIDDEN:
  var speed = 180
  func calculate_damage(target, amount):

  # MANDATORY:
  var speed: float = 180.0
  func calculate_damage(target: Node2D, amount: int) -> int:
  ```

### 2.2 Duck-Typed Web Bytecode Safety (CRITICAL)
- In Godot 4 WebAssembly export bytecode, custom script class casts (e.g., `node as Player` or `body as EnemyBase`) evaluate to `null` due to class registry stripping.
- **MANDATORY**: Use group lookups, property checks, or `has_method()`:
  ```gdscript
  # FORBIDDEN (Crashes on Web):
  var p: Player = body as Player
  p.take_damage(1)

  # MANDATORY (Safe on Web & Desktop):
  if body.is_in_group(&"player") and body.has_method("take_damage"):
      body.take_damage(1)
  ```

### 2.3 Single Responsibility & File Limits
- No script may exceed **250 lines of code**. If a file approaches 250 lines, extract logic into a child component or helper class.
- Avoid circular references. Parents communicate downwards via **function calls**; children communicate upwards via **signals**.

---

## 3. Standard Verification Workflow (Every Task)

Before committing changes or declaring a task complete, every agent must execute this exact verification sequence:

```
  Step 1: Code Edits Applied (< 250 LOC)
            │
            ▼
  Step 2: Headless Static Syntax Check
          godot --headless --path . --quit-after 120
          [Assert: Zero script errors, zero warnings]
            │
            ▼
  Step 3: Headless Unit Test Suite
          godot --headless --path . -s res://tests/run_tests.gd
          [Assert: ALL TESTS PASSED]
            │
            ▼
  Step 4: Browser E2E Test Pass (Playwright)
          node tests/e2e/test_*.js
          [Assert: Zero console errors, evidence saved to /qa/shots/]
            │
            ▼
  Step 5: Documentation & Changelog Update
          Tick off task in TASKS.md; append entry to CHANGELOG.md
```

---

## 4. How to Update `CHANGELOG.md`

Every completed task requires an entry in `CHANGELOG.md` using the following format:
```markdown
### [Task ID]: [Task Title] (VERIFIED 0 ERRORS)
- Brief summary of code changes and components created.
- State machines, signals, or resources modified.
- Headless unit test verification command and result.
- Evidence screenshots captured in `qa/shots/<phase>/<shot_name>.png`.
```

---

## 5. When to Ask the User Questions

To maximize development velocity and avoid unnecessary stalling:
- **Default Behavior**: If an implementation detail or balance parameter is open, choose the recommended option, mark it clearly as `[ASSUMPTION]`, log it in `docs/RISKS_AND_DECISIONS.md`, and continue working.
- **When to Ask**: You may ask the user a question **only if**:
  1. An irreconcilable conflict exists between core design requirements that breaks architecture.
  2. A local operating system or tool failure prevents Godot from executing entirely.
  3. You have reached a designated milestone review gate requiring user playtest approval.
- **Limit**: Ask at most **3 questions per interaction**, strictly formatted as concise multiple-choice options.
