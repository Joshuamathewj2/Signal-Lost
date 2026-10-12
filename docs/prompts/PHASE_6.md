# SIGNAL LOST — Implementation Prompt: PHASE 6 (Escape-Room Puzzle Layer & Cryptography)

Copy and paste the exact text below into your next Antigravity AI agent session to execute Phase 6:

```markdown
# MISSION: SIGNAL LOST — Phase 6 Implementation (Escape-Room Puzzle Layer & Cryptography)

You are an expert Godot 4 gameplay and puzzle engineer. Your objective is to execute PHASE 6 of the SIGNAL LOST V2 implementation plan, implementing the escape-room puzzle toolbox, resonance panels, echo glyphs, harmonic lanterns, and the emergency hint beacon (`H`).

## MANDATORY PRE-READING
1. `docs/AGENT_RULES.md` — Strict operational protocols and web duck-typing rules.
2. `docs/PUZZLES.md` — Complete puzzle toolbox, PuzzleController design, and level puzzle sheets.
3. `docs/GAME_CONFIG_REFERENCE.md` — Sonar pulse tiers and noise radius coupling.

## TASKS TO EXECUTE
Execute the following tasks strictly in order (<250 lines of code per task):
1. **P6-T01: PuzzleController Architecture**
   - Create `scenes/interactables/puzzle_controller.gd` managing multi-element states and blast door unlock signals.
2. **P6-T02: Echo Glyphs & Resonance Panels**
   - Create `scenes/interactables/echo_glyph.gd` (revealed only by specific pulse tiers).
   - Create `scenes/interactables/resonance_panel.gd` (triggers paired doors on matching acoustic frequency).
3. **P6-T03: Harmonic Lantern Sequences**
   - Create `scenes/interactables/harmonic_lantern.gd`. Striking lanterns in descending pitch order within 8.0s unlocks blast gates.
4. **P6-T04: Seal Locks & Cryptographic Airlocks**
   - Create `scenes/interactables/seal_lock.gd` requiring dual keys or simultaneous plate triggers to disengage.
5. **P6-T05: Emergency Exit Hint Beacon**
   - Implement `scenes/player/hint_beacon.gd`. Pressing `H` emits directional acoustic arrow pointing towards `E` ($r=120 \text{ px}$ noise, 5.0s cooldown).
6. **P6-T06: Phase 6 Verification**
   - Create unit tests `tests/test_puzzle_glyphs.gd` and `tests/test_puzzle_resonance.gd`.
   - Run all headless tests: `godot --headless --path . -s res://tests/run_tests.gd`.
   - Capture puzzle trigger screenshots to `/qa/shots/phase_6/`.

## SUCCESS CRITERIA
- Echo glyphs reveal clues selectively based on sonar pulse tier (Whisper = cyan, Normal = white, Scream = red).
- Resonance panels and harmonic lanterns unlock linked doors upon correct acoustic execution.
- Pressing `H` renders directional exit beacon and logs noise event on `NoiseBus`.
- `ALL TESTS PASSED` returned by `tests/run_tests.gd`.
- `docs/TASKS.md` updated and `CHANGELOG.md` entry logged.

When finished, stop and show me the screenshots from `/qa/shots/phase_6/`.
```
