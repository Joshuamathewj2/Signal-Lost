# GEMINI_RULES — Rulebook for the coding agent

You are implementing SIGNAL LOST from a fixed plan. You are **not** the designer. Read this file fully at the start of every session.

## 1. Session procedure
1. Open `docs/TASKS.md`, find the first unticked task (`- [ ]` in the Progress list). Do tasks **in order**; never skip ahead.
2. Read only: that task, this file, and the spec sections the task references.
3. Implement with minimal diffs. Keep within the task's file list (you may add a tiny helper only if the task says so).
4. Verify:
   - `godot --headless --path . --quit-after 120` → **zero** `SCRIPT ERROR`/`Parse Error` lines.
   - If the task has tests: `godot --headless --path . -s res://tests/run_tests.gd` → prints `ALL TESTS PASSED`.
   - Do the task's manual "How to test" steps if a display is available; otherwise state that the user must do them.
5. Append to `CHANGELOG.md`: `## P{x}-T{n} <name>` + bullet list of files changed + any deviation.
6. Tick the task in `TASKS.md` Progress list (`- [x]`).
7. `git add -A && git commit -m "<message given in the task or checkpoint>"`.
8. Report: what changed, how to test, any OPEN_QUESTIONS entries.

## 2. Spec discipline
- Do not change design, numbers, names, uniform names, signal names or file paths. If the spec is wrong/impossible, write to `docs/OPEN_QUESTIONS.md`: `### Qn (task id)` — problem, evidence (error text), smallest proposed fix — then implement that smallest fix and mark it `ASSUMED`.
- All tunables come from `GameConfig.cfg` (a `GameConfigData`), `PulseProfile`, `EnemyProfile`, or `Palette`. **No magic numbers** in gameplay scripts (0, 1, 0.5 for math, and array indices are fine).
- Colours only via `Palette.color(&"white")` etc. Never write a hex literal outside `palette_*.tres`.

## 3. Code rules
- Godot **4.4**, **typed GDScript** everywhere: `var speed: float = 0.0`, typed function args/returns, `Array[Vector2]`, `@export var profile: EnemyProfile`.
- Every script that is instanced by name has `class_name`. Autoloads have **no** `class_name` that collides with the autoload name.
- One responsibility per script; **≤ 250 lines** (split otherwise).
- Signals up, calls down. Children never reach for parents except via `@export` references or signals.
- No `get_node` paths deeper than 2 levels; prefer `@export` or unique names (`%Name`).
- `@onready var x: Type = %Name`.
- Connect in code with callables: `button.pressed.connect(_on_pressed)`.
- Use groups listed in ARCHITECTURE §16 exactly.
- Physics/light layer numbers exactly as ARCHITECTURE §1.
- Prefer composition (component Nodes) over inheritance; inheritance allowed only for `EnemyBase`, `Interactable`, `State`.
- No placeholder `pass` that silently breaks gameplay. If something is intentionally stubbed: `push_warning("STUB: <what> (task Px-Tn)")` once and `DebugFlags.log(&"stub", ...)`.
- Do not use plugins, C#, or external assets other than the Rajdhani font.

## 4. Godot 4 cheat sheet (common mistakes → correct)
| ❌ Godot 3 / wrong | ✅ Godot 4.4 |
|---|---|
| `KinematicBody2D`, `move_and_slide(vel, Vector2.UP)` | `CharacterBody2D`; set `velocity`, `up_direction`, then `move_and_slide()` |
| `export var x = 1` | `@export var x: int = 1` |
| `onready var` | `@onready var` |
| `yield(get_tree().create_timer(1), "timeout")` | `await get_tree().create_timer(1.0).timeout` |
| `connect("pressed", self, "_on_p")` | `pressed.connect(_on_p)` |
| `emit_signal("x", a)` | `x.emit(a)` |
| `instance()` | `instantiate()` |
| `PoolVector2Array` | `PackedVector2Array` |
| `Light2D` | `PointLight2D` / `DirectionalLight2D` |
| `rand_range()` | `randf_range()` / `RandomNumberGenerator` |
| `tool` | `@tool` |
| `TileMap` (deprecated) | not used in this project |
| `ParallaxBackground` | `Parallax2D` (4.3+) |
| `get_world_2d().direct_space_state.intersect_ray(a, b)` | `PhysicsRayQueryParameters2D.create(a, b, mask, exclude)` then `intersect_ray(query)` |
| `Tween.new()` node | `create_tween()` |
| `OS.get_ticks_msec()` | `Time.get_ticks_msec()` |
| `hint_color` / `SCREEN_TEXTURE` in shaders | `source_color` / `uniform sampler2D screen_tex : hint_screen_texture;` |
| `deg2rad` | `deg_to_rad` |
| `File.new()` | `FileAccess.open(path, FileAccess.READ)` |
| `.empty()` | `.is_empty()` |
| `str2var`, `to_json` | `str_to_var`, `JSON.stringify` |
| setget | `var x: int: set = _set_x` / property syntax |
| `Engine.time_scale` timers | `get_tree().create_timer(t, true, false, true)` to ignore time scale |
| `Area2D.monitoring` changes in signal callback | use `set_deferred("monitoring", false)` |
| Changing collision shapes in physics callback | `call_deferred` / `set_deferred("disabled", true)` |
| Freeing in a signal from physics | `queue_free()` only |

## 5. Shader rules
- `shader_type canvas_item;` only. Must compile on **Compatibility**: no compute, no `hint_depth_texture`, no global uniform **arrays** (use per-material arrays), loops with constant upper bounds and early `break`.
- Uniform names, types and defaults exactly as `SHADER_SPEC.md`. Every uniform must be set by the script named in SHADER_SPEC §12.
- Use `source_color` for colour uniforms. Use `hint_screen_texture` only in `post_fx.gdshader`.
- Set uniforms with `material.set_shader_parameter(&"name", value)`. For a shared material that must differ per instance, use `material = material.duplicate()` or `instance uniform` (supported in 4.x canvas_item? → **don't**; duplicate the material).

## 6. Scenes
- Create `.tscn` files through code-free text format only if you are sure of the format; otherwise build node trees in the script's `_ready()` for procedural pieces and keep `.tscn` minimal (root + script + key children). Every `.tscn` must open without errors in the editor.
- Swappable visuals: every entity has a child named `Visual` instantiated from its `*_visual.tscn`; gameplay scripts talk to it only through methods `set_facing(dir:int)`, `set_pose(pose:StringName)`, `set_alert(v:float)`, `flash()`, `play_death()`.

## 7. Testing
- Unit tests live in `res://tests/` as scripts extending `RefCounted` with `func run() -> Array[String]` returning failure messages. `run_tests.gd` (extends `SceneTree`) loads each `test_*.gd`, runs it, prints `PASS name` / `FAIL name: msg`, prints `ALL TESTS PASSED` or `N FAILURES`, and calls `quit(exit_code)`.
- Sandbox scenes in `res://sandbox/` must run standalone with F6.

## 8. Git
- Commit after every task with the task's message (format `P{x}-T{n}: <short>`), and a checkpoint commit at phase end with the checkpoint message.
- Never commit `.godot/` (add `.gitignore`: `.godot/`, `*.import` is **kept**, `export/`).

## 9. Forbidden
- Rewriting working files wholesale; renaming files; changing the folder tree.
- Adding hues other than the palette.
- Adding features not in TASKS.md.
- Catching errors silently.
