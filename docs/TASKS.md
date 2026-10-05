# SIGNAL LOST — Implementation Tasks

Read `docs/GEMINI_RULES.md` first. Do tasks strictly in order. Each task lists the spec sections it relies on — read them.
Abbreviations: **GDD**, **ARCH** (ARCHITECTURE), **SHD** (SHADER_SPEC), **AI** (ENEMY_AI), **LVL** (LEVEL_DESIGN), **AA** (ANIMATION_AUDIO), **UI** (UI_UX), **TP** (TEST_PLAN).
Parse check command (PC): `godot --headless --path . --quit-after 120` (expect no `ERROR`/`SCRIPT ERROR`). Test command (TC): `godot --headless --path . -s res://tests/run_tests.gd` (expect `ALL TESTS PASSED`).

## Progress
- [x] P0-T1 Project settings & repo
- [x] P0-T2 Input map & layer names
- [x] P0-T3 Resource class scripts
- [x] P0-T4 Resource data files (.tres)
- [x] P0-T5 Core autoloads (config, palette, debug, math)
- [x] P0-T6 Stub autoloads (noise, pulses, state, router, save, audio)
- [x] P0-T7 Main scene + debug overlay shell
- [x] P0-T8 Test harness
- [x] P0-T9 Font + UI theme
- [x] P1-T1 Player body & motor (run/sneak/gravity)
- [x] P1-T2 Jump feel & one-way drop-through
- [x] P1-T3 Camera rig (follow)
- [x] P1-T4 Gray-box player sandbox
- [x] P1-T5 Battery + pulse charger
- [x] P1-T6 Footstep emitter
- [x] P1-T7 Early HUD: charge rings + battery bar
- [x] P2-T1 Reveal texture + PulseBubble
- [x] P2-T2 SonarSystem pool
- [x] P2-T3 flat_reveal + sonar_air shaders
- [x] P2-T4 Rough edge lines
- [ ] P2-T5 Parallax background silhouettes
- [ ] P2-T6 PulseRegistry.reveal_at + RippleRings
- [ ] P2-T7 sandbox_sonar (vertical slice)
- [ ] P3-T1 StateMachine/State
- [ ] P3-T2 NoiseBus + HearingComponent
- [ ] P3-T3 EnemyBase + Awareness/Memory/Vision
- [ ] P3-T4 PlatformMover (flat mode)
- [ ] P3-T5 Listener FSM
- [ ] P3-T6 Enemy shaders + smudge
- [ ] P3-T7 Enemy debug page + sandbox_enemy
- [ ] P4-T1 LevelParser
- [ ] P4-T2 SolidMerger + LevelBuilder solids
- [ ] P4-T3 EdgeBuilder from grid
- [ ] P4-T4 PlatformGraph + mover graph mode
- [ ] P4-T5 LevelValidator
- [ ] P4-T6 EntitySpawner + LevelRoot
- [ ] P4-T7 SceneRouter + levels 1–2
- [ ] P5-T1 Interactable base, fragment, keycard, exit
- [ ] P5-T2 Doors + pressure plate
- [ ] P5-T3 One-way door
- [ ] P5-T4 Glass floor
- [ ] P5-T5 Lantern
- [ ] P5-T6 Vents
- [ ] P5-T7 Sentry + projectile
- [ ] P5-T8 Hunter
- [ ] P5-T9 Brute
- [ ] P5-T10 GameState: death, win, restart, stats, medals
- [ ] P6-T1 Post FX
- [ ] P6-T2 Camera juice + hit-stop
- [ ] P6-T3 Robot procedural animation + death burst
- [ ] P6-T4 Enemy animations + alert glyphs
- [ ] P6-T5 Particles factory
- [ ] P6-T6 Synth SFX + AudioManager + buses
- [ ] P6-T7 Music layers
- [ ] P7-T1 Full HUD
- [ ] P7-T2 Awareness bars + reticles
- [ ] P7-T3 Main menu + title
- [ ] P7-T4 Pause menu
- [ ] P7-T5 Settings + SaveData settings
- [ ] P7-T6 Level complete + level select + medals save
- [ ] P8-T1 Decoy beacon
- [ ] P8-T2 Hint signs
- [ ] P8-T3 Levels 3–5
- [ ] P8-T4 Levels 6–8
- [ ] P8-T5 Balancing pass
- [ ] P9-T1 Performance & quality mode
- [ ] P9-T2 Bug-bash
- [ ] P9-T3 Export presets + README
- [ ] P10 (optional stretch) EMP / Echo upgrade / Mimic

---
# PHASE 0 — Foundation

### TASK P0-T1: Project settings & repo
Goal: Empty-but-valid Godot 4.4 project with the folder tree.
Files to create/modify: `project.godot`, `.gitignore`, `CHANGELOG.md`, `README.md` (stub), empty folders from ARCH §8 (put a `.gdkeep` file in empty ones).
Depends on: —
Detailed spec: `config/name="SIGNAL LOST"`; `rendering/renderer/rendering_method="gl_compatibility"` and `.mobile="gl_compatibility"`; `display/window/size/viewport_width=1280`, `viewport_height=720`; `display/window/stretch/mode="canvas_items"`, `aspect="expand"`; `rendering/textures/canvas_textures/default_texture_filter=1` (linear); `physics/common/physics_ticks_per_second=60`; `application/run/max_fps=0`, vsync on. `rendering/2d/shadow_atlas/size=2048`. `.gitignore`: `.godot/`, `export/`, `*.tmp`. `git init` if not a repo.
Acceptance criteria: project opens in editor without warnings; PC clean; folders match ARCH §8.
How to test: PC; open project in editor; Project Settings show Compatibility.
Known pitfalls: Godot writes `config_version=5`; keep `[application]` section; don't hand-edit `.godot/`.
Do NOT: add any scripts yet.
Commit: `P0-T1: project skeleton`

### TASK P0-T2: Input map & layer names
Goal: All input actions and physics layer names.
Files: `project.godot`.
Depends on: P0-T1
Detailed spec: Actions exactly ARCH §12 (deadzone 0.25; triggers as `InputEventJoypadMotion` axis 4/5 value 1.0). 2D physics layer names ARCH §1 (1 world … 7 hazard_kill). 2D render layer names: 1 world_fg, 2 world_bg, 3 actors, 4 air.
Acceptance: Input Map tab lists 11 actions with keys + pads; layer names visible in inspector.
How to test: Editor → Project Settings → Input Map. PC.
Known pitfalls: In `project.godot`, input events are serialized `Object(InputEventKey,...)`; easiest is to create them via the editor or write `physical_keycode` values (A=65, D=68, W=87, S=83, Space=32, Shift=4194325, Up=4194320, Down=4194322, Left=4194319, Right=4194321, Esc=4194305, F1=4194332, F2=4194333, K=75, F=70, G=71, R=82). Mouse left: `InputEventMouseButton button_index=1`.
Do NOT: rename actions.
Commit: `P0-T2: input map and layers`

### TASK P0-T3: Resource class scripts
Goal: Typed custom Resources.
Files: `scripts/resources/game_config_data.gd`, `pulse_profile.gd`, `enemy_profile.gd`, `level_data.gd`, `palette_data.gd`.
Depends on: P0-T1
Detailed spec: Fields per ARCH §13, all `@export` with the GDD/AI default values as initializers. `GameConfigData` groups (use `@export_group`): Player (GDD §4.1 table, all names snake_case as in table), Noise (footstep_radius 40, footstep_loudness 0.5, footstep_interval 0.30, footstep_min_speed 40, land_radius 96, land_loudness 1.0, land_speed_threshold 520), Pulse (charge_full_time 1.0, tier_normal_at 0.35, tier_scream_at 0.85, charge_move_mult 0.6, max_bubbles 6, sound_speed 700, ghost_energy 0.12, ghost_time 2.0, ring_fade_time 0.35), Battery (max 100, regen_still 8, regen_moving 3, regen_delay 0.8), Hearing (wall_penalty 0.75, max_wall_raycasts 3, reveal_visible_threshold 0.25, memory_expiry 20, vision_tick 0.1, repath_interval 0.25), Camera (zoom 2.0, smoothing 6, lookahead 40, shake_max_offset 10, shake_decay 1.5, scream_zoom_punch 0.06), Render (rim_softness 0.25, player_glow_radius 40, player_glow_energy 0.6, sonar_quality enum {HIGH, LOW}), Post (vignette_strength 0.45, vignette_radius 0.75, grain_amount 0.06, bloom_amount 0.25, ca_scream 0.012, ca_detect 0.008, flash_detect 0.35), Anim (see AA tables: land_squash 0.12, jump_squash 0.08, death_time 0.6, hitstop 0.08). `PulseProfile` adds `func noise_radius() -> float: return reveal_radius * noise_mult` and `func expand_time(sound_speed: float) -> float`. `LevelData` fields per ARCH §13 + `headers: Dictionary`.
Acceptance: PC clean; each class creatable via "New Resource".
How to test: Editor → FileSystem → New Resource → search `PulseProfile`.
Known pitfalls: `class_name` must be unique; use `@export_enum` or `enum` + `@export var sonar_quality: Quality`.
Do NOT: put logic beyond tiny helpers.
Commit: `P0-T3: resource classes`

### TASK P0-T4: Resource data files
Goal: Default data assets.
Files: `resources/config/default_config.tres`, `resources/pulses/pulse_whisper.tres`, `pulse_normal.tres`, `pulse_scream.tres`, `pulse_decoy.tres`, `resources/enemies/enemy_listener.tres`, `enemy_sentry.tres`, `enemy_hunter.tres`, `enemy_brute.tres`, `resources/theme/palette_default.tres`, `palette_colorblind.tres`.
Depends on: P0-T3
Detailed spec: Pulse values GDD §4.3 table (+ ring_thickness 1.5/2.0/3.0, trail_gap 10/14/22, trail_count 1/2/3, sfx ids `ping_whisper/normal/scream`, ca_strength 0/0/0.012). `pulse_decoy` = copy of normal with id `decoy`. Enemy values AI §2 (accepted_types as int arrays of `NoiseEvent.NoiseType` — define the enum order now in a comment: PULSE=0, FOOTSTEP=1, LAND=2, IMPACT=3, GLASS=4, CLINK=5, PLATE=6, DECOY=7, ENEMY=8). Palette per GDD §12; colorblind: same greys, danger `#FFFFFF` with `hatch = true`, smudge `#3D3D3D`.
Acceptance: Files load (`load()` non-null) — verified in P0-T8 test.
How to test: open each `.tres` in inspector.
Known pitfalls: `.tres` text must reference `script = ExtResource("1")`; easiest: create via a one-off `@tool` EditorScript, then delete the script. Keep files text.
Do NOT: hardcode these numbers anywhere else.
Commit: `P0-T4: data resources`

### TASK P0-T5: Core autoloads
Goal: Config, palette, debug log, math helpers.
Files: `autoload/game_config.gd`, `autoload/palette_service.gd`, `autoload/debug_flags.gd`, `scripts/core/math_util.gd`, `project.godot` (autoload list, order ARCH §7).
Depends on: P0-T4
Detailed spec: `GameConfig`: `var cfg: GameConfigData = preload(".../default_config.tres")`, `var pulses: Dictionary` (`&"whisper"→PulseProfile`…), `func pulse_for_tier(tier: int) -> PulseProfile` (0 whisper,1 normal,2 scream), `var enemies: Dictionary` (`&"listener"`…). `Palette` (palette_service.gd): `var data: PaletteData`, `func color(name: StringName) -> Color`, `func set_colorblind(on: bool)`, `signal palette_changed`. `DebugFlags`: `var overlay_visible: bool`, `var page: int`, `var lights_off: bool`, `func log(cat: StringName, msg: String)` → prints `[cat] msg` when `OS.is_debug_build()`; toggles on `debug_toggle`/`debug_next_page` in `_unhandled_input`. `MathUtil` (`class_name MathUtil`, static funcs): `ease_out_cubic(x)`, `wave_radius(R, t, T_exp)`, `bubble_brightness(t, T_exp, hold, fade, ghost, ghost_time) -> float` (returns −1 when dead), `ring_alpha(t, T_exp, ring_fade)`. Curves exactly SHD §1.
Acceptance: PC clean; F1 prints toggle log.
How to test: run any scene, press F1 → console `[debug] overlay on`.
Known pitfalls: autoload names must not equal a `class_name`.
Do NOT: add gameplay logic.
Commit: `P0-T5: core autoloads`

### TASK P0-T6: Stub autoloads
Goal: Remaining singletons with final signal signatures (bodies minimal).
Files: `scripts/core/noise_event.gd`, `autoload/noise_bus.gd`, `autoload/pulse_registry.gd`, `autoload/game_state.gd`, `autoload/scene_router.gd`, `autoload/save_data.gd`, `autoload/audio_manager.gd`, `project.godot`.
Depends on: P0-T5
Detailed spec: `NoiseEvent` (`class_name NoiseEvent extends RefCounted`): enum NoiseType (order P0-T4), fields position, radius, loudness, type, source (Node, may be null), `static func make(...)`. `NoiseBus`: `signal noise_emitted(event: NoiseEvent)`, `func emit_noise(event: NoiseEvent) -> void` (for now: emit signal + DebugFlags.log). `PulseRegistry`: `var bubbles: Array` (of dictionaries/objects later), `func reveal_at(pos: Vector2) -> float: return 0.0` (stub warn once). `GameState`: signals from ARCH §11 (`run_stats_changed`, `detected`, `level_completed`, `decoy_count_changed`, `keycard_changed`), vars `level_index: int`, `has_keycard: bool`, `stats: Dictionary`, `func reset_run()`. `SceneRouter`: `func goto_scene(path: String)`, `func restart_level()` (stub). `SaveData`: ConfigFile at `user://save.cfg`, `func get_setting(key, default)`, `func set_setting(key, value)` (saves), `signal settings_changed`. `AudioManager`: `func play_sfx(id: StringName, pos := Vector2.INF, pitch := 1.0)` stub that logs.
Acceptance: PC clean, autoload order as ARCH §7.
How to test: PC; `print(NoiseEvent.NoiseType.GLASS)` = 4 in a scratch run.
Do NOT: implement hearing yet.
Commit: `P0-T6: stub autoloads`

### TASK P0-T7: Main scene + debug overlay shell
Goal: Bootable main scene with F1 overlay showing FPS.
Files: `scenes/main/main.tscn`, `main.gd`, `boot.gd`, `scenes/debug/debug_overlay.tscn`, `debug_overlay.gd`, `scenes/debug/debug_draw.gd`, `project.godot` (main scene).
Depends on: P0-T6
Detailed spec: Tree per ARCH §9 (LevelHost, PostFx placeholder CanvasLayer 10, HUD placeholder CanvasLayer 20, Menus CanvasLayer 30, DebugOverlay CanvasLayer 100). `boot.gd` (attached to Main via main.gd composition or as child Node) logs versions. DebugOverlay: Label top-right (monospace default font OK), shows `FPS`, page index; hidden unless `DebugFlags.overlay_visible`. `debug_draw.gd` (`class_name DebugDraw extends Node2D`): API `circle(pos, r, color, ttl)`, `line(a,b,color,ttl)`, `text(pos, s, ttl)`, `polyline(points, color, ttl)`; draws queued shapes in `_draw`, expires by ttl; unshaded material; z_index 100. It will be added to each LevelRoot later; for now unused.
Acceptance: F5 runs a black window; F1 toggles FPS label; F2 changes page number.
How to test: F5, press F1/F2.
Do NOT: build menus.
Commit: `P0-T7: main scene + debug overlay`

### TASK P0-T8: Test harness
Goal: Headless unit-test runner.
Files: `tests/run_tests.gd`, `tests/test_resources.gd` (extra helper test, allowed).
Depends on: P0-T5
Detailed spec: As GEMINI_RULES §7. `test_resources.gd` checks all 11 `.tres` load, pulse noise radii = 43.2/200/728 (±0.5), and `MathUtil.bubble_brightness` = 1 at t=0.05 (normal), < 0.2 just before ghost phase, −1 when dead.
Acceptance: TC prints `ALL TESTS PASSED`, exit code 0.
How to test: TC.
Known pitfalls: In `-s` mode autoloads ARE loaded in 4.x only if the script extends `SceneTree` and you `await process_frame` once before using them; tests must not depend on autoloads unless they await one frame.
Commit: `P0-T8: test harness`

### TASK P0-T9: Font + UI theme
Goal: Bundled Rajdhani and the single Theme.
Files: `assets/fonts/Rajdhani-Medium.ttf`, `Rajdhani-SemiBold.ttf`, `OFL.txt`, `resources/theme/ui_theme.tres`, `project.godot` (`gui/theme/custom` = ui_theme).
Depends on: P0-T1
Detailed spec: UI §1. Theme default font Medium size 22; type variations `TitleLabel` (SemiBold 96), `HudLabel` (22), `LevelNameLabel` (26), `MenuButton` (30). Colours from palette values (theme is the one other place hex literals may appear — keep consistent with palette_default).
Acceptance: a Label in a scratch scene renders Rajdhani.
How to test: open ui_theme.tres preview.
Known pitfalls: if download impossible, write OPEN_QUESTIONS entry and proceed with default font.
Commit: `P0-T9: font and theme`

**CHECKPOINT P0** — You should see: black window, F1 FPS overlay, tests passing. Commit: `checkpoint: phase 0 foundation`.

---
# PHASE 1 — Player & pulse input

### TASK P1-T1: Player body & motor
Goal: Side-view run/sneak/gravity.
Files: `scenes/player/player.tscn`, `player.gd`, `player_motor.gd`, `scenes/player/player_visual.tscn`, `player_visual.gd` (placeholder shapes only).
Depends on: P0
Detailed spec: Tree ARCH §9 (Player CharacterBody2D layer 3, mask 1|2|5; capsule r7 h18; group `player`). `player_motor.gd` (`class_name PlayerMotor extends Node`, `@export var body: CharacterBody2D`): reads `move_left/right`, `sneak`; horizontal: target = dir × (sneak ? sneak_speed : run_speed) × (charging ? charge_move_mult : 1); approach with ground_accel / ground_friction / air_accel; gravity with fall_gravity_mult; clamp max_fall_speed; `body.move_and_slide()`. Crouch: swap capsule height to 12 (keep feet planted: offset shape), refuse un-crouch if ceiling raycast hits. Exposes `is_sneaking`, `is_on_floor`, `facing:int`, signal `landed(impact_speed: float)`, `jumped`. `player.gd`: wires components, `func die(cause: StringName)` (emit `player_died`, disable input; full effect P5/P6). Visual placeholder: white Polygon2D body 12×10 + head 10×7 + 1 px antenna (final animation P6-T3), implements Visual API stubs (`set_facing`, `set_pose`).
Acceptance: In P1-T4 sandbox (or a temp floor) the robot runs at 180 px/s, sneaks at 70, falls with gravity.
How to test: Debug overlay shows velocity (add `player` line to overlay page 0: state, vx, vy).
Known pitfalls: Use `floor_snap_length` 6; set `up_direction`; don't multiply velocity by delta before move_and_slide.
Do NOT: implement jump here.
Commit: `P1-T1: player motor`

### TASK P1-T2: Jump feel & drop-through
Goal: Jump with coyote, buffer, jump-cut, one-way drop-through.
Files: `scenes/player/player_motor.gd`.
Depends on: P1-T1
Detailed spec: GDD §4.1 numbers. Coyote timer set when leaving floor without jumping; buffer timer on `jump` press; jump when `(on_floor or coyote>0) and buffer>0`; jump-cut on release while vy<0. Drop-through: if `sneak` held and `jump` pressed and the floor collider is on layer 2 → `body.set_collision_mask_value(2, false)` for `drop_through_time`, then restore; no jump impulse. Emit `jumped` and `landed(impact)` (impact = vy before landing).
Acceptance: jump apex ≈ 87 px (±4) — print max height in debug; can jump 0.1 s after walking off a ledge; pressing jump 0.1 s before landing still jumps; sneak+jump on `=` drops.
How to test: P1-T4 sandbox, overlay values.
Known pitfalls: Check layer via `get_last_slide_collision()` collider's `get_collision_layer_value(2)`.
Commit: `P1-T2: jump feel`

### TASK P1-T3: Camera rig
Goal: Follow camera.
Files: `scenes/fx/camera_rig.tscn`, `camera_rig.gd`.
Depends on: P1-T1
Detailed spec: AA §5 follow part (zoom from cfg, smoothing, look-ahead, deadzone, `func set_limits(rect: Rect2i)`). Public API stubs for later: `add_trauma(a: float)`, `zoom_punch(amount: float, t_in: float, t_out: float)` (implement in P6-T2; now push_warning once).
Acceptance: camera follows smoothly, leads in facing direction.
How to test: sandbox.
Commit: `P1-T3: camera rig`

### TASK P1-T4: Gray-box player sandbox
Goal: Multi-floor test room (lit normally — no darkness yet).
Files: `sandbox/sandbox_player.tscn`.
Depends on: P1-T2, P1-T3
Detailed spec: 1280×720-px room (40×22 tiles): 3 floors of StaticBody2D rectangles (layer 1) drawn with grey Polygon2D, two one-way platforms (layer 2, one_way_collision), 1- and 2-tile steps, a 3-tile gap, a 4-tile gap (must be impossible), Player, CameraRig, DebugOverlay instance + DebugDraw.
Acceptance: all moves from GDD §4.1 reproducible; 4-tile gap impossible, 3-tile possible.
How to test: open, F6.
Commit: `P1-T4: player sandbox`

### TASK P1-T5: Battery + pulse charger
Goal: Charge/release pulses with tier selection and energy.
Files: `scenes/player/battery.gd`, `scenes/player/pulse_charger.gd`, `tests/test_pulse_tiers.gd`, `scenes/player/player.tscn` (add nodes).
Depends on: P1-T1, P0-T8
Detailed spec: `Battery` (`class_name Battery`): `energy`, `signal energy_changed(value, max)`, regen per GDD §4.4 (needs `is_still` and `is_charging` inputs set by player), `func try_spend(cost) -> bool`. `PulseCharger` (`class_name PulseCharger`): on `pulse` pressed → `charge_started`; while held `c = t / charge_full_time`; `static func tier_for_charge(c, normal_at, scream_at) -> int`; `affordable_tier` = highest tier ≤ selected whose cost ≤ energy (−1 if none); emits `charge_changed(tier, c, affordable_tier)` each frame; on release: if affordable_tier == −1 → `pulse_failed`; else respect per-tier cooldown (if cooling, treat as fail), spend energy, emit `pulse_released(profile, global_position)` AND `NoiseBus.emit_noise(NoiseEvent.make(origin, profile.noise_radius(), profile.loudness, PULSE, player))`. Mute-vent factor hook: `var noise_scale: float = 1.0` (set by vents in P5-T6). Test: tier boundaries (0→0, 0.34→0, 0.35→1, 0.84→1, 0.85→2, 1→2) and downgrade logic (energy 10 + scream → whisper).
Acceptance: TC passes; console logs `[noise] PULSE r=200` on normal release.
How to test: TC; sandbox with F1 overlay showing energy and tier.
Known pitfalls: Use `Input.is_action_just_released` in `_process`, not `_unhandled_input`, to avoid missing releases when paused.
Commit: `P1-T5: battery and pulse charger`

### TASK P1-T6: Footstep emitter
Goal: Movement noise.
Files: `scenes/player/footstep_emitter.gd`, `player.tscn`.
Depends on: P1-T5
Detailed spec: GDD §4.2. Listens `PlayerMotor.landed`. Emits `NoiseEvent` FOOTSTEP / LAND via NoiseBus. No noise while sneaking.
Acceptance: running logs FOOTSTEP every 0.3 s; sneaking logs nothing; 5-tile drop logs LAND.
How to test: sandbox with console.
Commit: `P1-T6: footsteps`

### TASK P1-T7: Early HUD — charge rings + battery bar
Goal: Visible charge (white) and noise (red) rings and battery bar.
Files: `scenes/sonar/charge_rings.gd`, `scenes/ui/battery_bar.gd`, `scenes/ui/hud.tscn`, `scenes/ui/hud.gd`, `player.tscn` (ChargeRings node).
Depends on: P1-T5, P0-T9
Detailed spec: UI §2 BatteryBar and UI §3 charge/noise rings exactly. ChargeRings is unshaded Node2D child of Player using `draw_arc` (64 segments), hidden when not charging. HUD for now contains only BottomLeft/BatteryBar; `hud.gd` finds the player via group `player` on `ready` and when a level loads (`SceneRouter.level_loaded` signal — add the signal to SceneRouter now).
Acceptance: holding pulse grows white ring to 72/200/560 px radius by tier with red ring 43/200/728; bar drains and shows ghost segment.
How to test: sandbox_player (add HUD instance).
Commit: `P1-T7: early HUD`

**CHECKPOINT P1** — Robot runs, jumps, sneaks, drops through catwalks in a grey multi-floor room; holding the pulse button shows the white reveal ring and red noise ring; releasing drains the red battery bar and logs a noise event. Commit: `checkpoint: phase 1 player`.

---
# PHASE 2 — THE SONAR (make-or-break vertical slice)

### TASK P2-T1: Reveal texture + PulseBubble
Goal: One bubble = occluded, fading light.
Files: `scenes/sonar/reveal_texture_factory.gd`, `scenes/sonar/pulse_bubble.tscn`, `pulse_bubble.gd`.
Depends on: P0-T5
Detailed spec: Factory: static cached `get_texture() -> ImageTexture` per SHD §4. `PulseBubble` (`class_name PulseBubble extends Node2D`): child `Light` PointLight2D (blend ADD, `shadow_enabled` true unless `sonar_quality == LOW`, shadow_filter PCF5, smooth 1.5, `range_item_cull_mask = 1|2|4|8` i.e. bits 1–4, `texture = factory`), `func start(profile: PulseProfile, origin: Vector2)`, per-frame `age += delta`, `radius = MathUtil.wave_radius`, `light.texture_scale = max(radius,1)/256`, `light.energy = brightness`, `ring_alpha`; `signal finished(bubble)`; `var active: bool`. Expose read-only `radius`, `brightness`, `ring_alpha`, `profile`, `origin`.
Acceptance: in a scratch scene with CanvasModulate black and a white Polygon2D + LightOccluder2D box, a started bubble expands, holds, fades, ghosts, finishes; the box casts a shadow wedge.
How to test: scratch scene (do not commit it) or wait for P2-T7.
Known pitfalls: PointLight2D `texture_scale` scales the texture size in px (texture 512 → radius 256 at scale 1). Lights need `shadow_enabled` AND occluders with `occluder_light_mask` matching the light's `shadow_item_cull_mask`.
Commit: `P2-T1: pulse bubble`

### TASK P2-T2: SonarSystem pool
Goal: Manage up to 6 bubbles, feed shader arrays and registry.
Files: `scenes/sonar/sonar_system.tscn`, `sonar_system.gd`, `autoload/pulse_registry.gd` (register API only).
Depends on: P2-T1, P1-T5
Detailed spec: Pool `max_bubbles` PulseBubbles created in `_ready`. `func spawn(profile, origin) -> PulseBubble` (reuse inactive; else recycle oldest). Connects to player's `PulseCharger.pulse_released` (found via group `player`; reconnect on `SceneRouter.level_loaded`). Emits `bubble_spawned`. Each frame: build `pulse_data` (x, y, radius, ring_alpha) and `pulse_style` (thickness, trail_gap, trail_count, brightness), set on `@export var air_material: ShaderMaterial` (`pulse_count`, arrays padded to 6). Wavefront hooks: each frame for each active expanding bubble, for nodes in group `wave_reactive` whose distance crossed from > previous radius to ≤ current radius → call `node.on_wavefront(profile, origin)` (track per-bubble set of already-hit node ids). Registry: `PulseRegistry.set_bubbles(active_list)`.
Acceptance: rapid pulsing never exceeds 6 lights; arrays update (print in debug page 2).
How to test: debug page 2 lists bubbles with age/radius/energy.
Known pitfalls: `set_shader_parameter` with `PackedVector4Array` (4.3+) or `Array` of Vector4 — use `PackedVector4Array` sized exactly 6.
Commit: `P2-T2: sonar system`

### TASK P2-T3: flat_reveal + sonar_air shaders
Goal: Silhouette look and wavefront arcs.
Files: `shaders/flat_reveal.gdshader`, `shaders/sonar_air.gdshader`.
Depends on: P2-T2
Detailed spec: SHD §2 and §3 exactly (uniform names!). The air shader varying world position: use `MODEL_MATRIX` in `vertex()`; SonarAir ColorRect is a direct child of LevelRoot (no transform except position).
Acceptance: arcs visible only inside lit, unshadowed areas; trailing rings fade per profile; whisper/normal/scream visually distinct.
How to test: P2-T7 sandbox.
Known pitfalls: In `light()` you cannot read `TEXTURE`; use `COLOR`. Loop over uniform array needs a constant bound (6) + `if (i >= pulse_count) break;`. Light pass is additive per light: keep arcs `step()`-gated so they don't over-brighten when 2 bubbles overlap (clamp alpha ≤ 1).
Commit: `P2-T3: reveal shaders`

### TASK P2-T4: Rough edge lines
Goal: Torn-paper white edges + specks generator.
Files: `scenes/world/edge_line_factory.gd`, `shaders/edge_line.gdshader`.
Depends on: P2-T3
Detailed spec: `class_name EdgeLineFactory` static `make_edge(a: Vector2, b: Vector2, is_top: bool, rng: RandomNumberGenerator) -> Node2D` returning a Node2D containing: main Line2D (width 2.5 top / 1.5 side, flat_reveal material, tint white, `light_mask` 1, joint/caps round, antialiased false), glow Line2D (width ×3, α0.25, edge_line material), and for top edges specks: every 6–18 px a tiny grass tuft (2–3 Line2D strokes 2–5 px tall, ±25°) or debris dot (2×2 Polygon2D), 40% probability, white/near-grey. Points per SHD §5 (6 px step, noise jitter 1.6 px + rand 0.6, notches). Use a `FastNoiseLite` seeded from rng.
Acceptance: an edge looks hand-drawn, not straight; only visible inside bubbles.
How to test: P2-T7.
Known pitfalls: Line2D `texture_mode` TILE needs a texture for UV.y — set a 1×4 white `GradientTexture2D` so UV exists.
Commit: `P2-T4: edge lines`

### TASK P2-T5: Parallax background silhouettes
Goal: Layered facility silhouettes visible only in bubbles.
Files: `scenes/world/bg_prop_factory.gd`, `scenes/world/background_builder.gd`.
Depends on: P2-T3
Detailed spec: `BackgroundBuilder.build(parent: Node2D, map_rect: Rect2, seed: int)` creates 3 `Parallax2D` (Far scroll 0.35 colour far `#1A1A1A`, Mid 0.6 `#2B2B2B`, Near 0.85 `#3D3D3D`; `repeat_size` 0 — no repeat; z −30/−20/−10), each with props from `BgPropFactory` (static methods returning Node2D built from Polygon2D/Line2D with flat_reveal material, `light_mask` 2): `pipe_run` (horizontal thick Line2D w 6–10 with flange rects), `pillar` (rect 24–40 wide, full height, with rivet dots), `gantry` (truss: two lines + zigzag), `hanging_cable` (catenary Line2D, 12 points, sag 20–60), `hanging_lamp` (cable + trapezoid shade), `vent_grate` (rect + 5 slats), `railing` (posts + rail), `machine_block` (rect with panel lines), `grated_window` (rect outline + grid), `sign_panel` (rect with 2–3 short bars), `chain` (Line2D dashed). Density ~1 prop/3 tiles per layer; seeded RNG.
Acceptance: In a bubble you see 3 grey depths with parallax motion as the camera moves; outside bubbles pure black.
How to test: P2-T7.
Known pitfalls: Parallax2D children are lit at their *screen-transformed* position — that is desired. Don't use colour other than palette greys.
Commit: `P2-T5: background silhouettes`

### TASK P2-T6: PulseRegistry.reveal_at + RippleRings
Goal: CPU reveal query and sound ripples.
Files: `autoload/pulse_registry.gd`, `scenes/sonar/ripple_rings.gd`.
Depends on: P2-T2
Detailed spec: `reveal_at(pos) -> float`: max over active bubbles of `brightness` where `pos.distance_to(origin) < radius` and raycast(origin→pos, mask 1) has no hit (cache world `PhysicsDirectSpaceState2D` from a registered Node2D — `func set_space_provider(n: Node2D)` called by SonarSystem). `func player_revealed(player_pos) -> bool` = `reveal_at > reveal_visible_threshold`. RippleRings (Node2D, unshaded, in SonarSystem): listens `NoiseBus.noise_emitted`; for each event except PULSE, add ripple {pos, radius = min(event.radius, 120), age, colour = white for world/objects, `#5A0000`→mixed red-grey for ENEMY type}; draw 3 concentric arcs expanding over 0.8 s with alpha 0.6/0.35/0.2; max 16 ripples.
Acceptance: footsteps show tiny white ripples even in darkness; enemy noises (later) red-grey ripples.
How to test: sandbox_player with SonarSystem added: run → ripples at feet.
Commit: `P2-T6: reveal query and ripples`

### TASK P2-T7: sandbox_sonar (the money shot)
Goal: Standalone, stunning sonar demo.
Files: `sandbox/sandbox_sonar.tscn`, `sandbox/sandbox_sonar.gd`.
Depends on: P2-T1…T6, P1
Detailed spec: Dark room 40×22 tiles: CanvasModulate `#000000`; hand-authored solids (3 floors, pillars, a ceiling overhang) each with black Polygon2D + LightOccluder2D + collision + edges via EdgeLineFactory; two one-way catwalks (top edge only, no occluder); BackgroundBuilder props; SonarAir ColorRect covering room with sonar_air material referenced by SonarSystem; Player with GlowLight (PointLight2D r 40, energy 0.6, shadows, cull bits 1–3); CameraRig; HUD; DebugOverlay. 3 static red Polygon2D "dummy enemies" with `enemy_silhouette` placeholder = flat_reveal tinted red (P3-T6 replaces). Keys: `1/2/3` fire whisper/normal/scream at player position without energy cost; `C` toggles CanvasModulate (see-all); `L` spawns 6 bubbles at random positions to test overlap; `Q` toggles sonar_quality LOW.
Acceptance (visual — compare with GDD §12/§2B): pure black at rest except robot glow; pulse = expanding dome clipped by ceiling/floor; thin white arc at the front + 1–3 trailing rings; white jagged edges with grass specks; three grey parallax depths visible only inside the dome; red dummies flat red; overlapping bubbles at different fade stages, older dimmer, ghost at 12% for 2 s; 60 FPS with 6 bubbles (overlay).
How to test: F6; press 1,2,3,L; move around.
Known pitfalls: If shadows don't appear: occluder `occluder_light_mask` must include bit 1; light `shadow_item_cull_mask` bit 1. If arcs appear through walls: the air light() gate is wrong.
Do NOT: start enemies.
Commit: `P2-T7: sonar sandbox`

**CHECKPOINT P2** — In `sandbox_sonar.tscn`: a black screen; a scream sends a bright white wavefront that fills a big bubble clipped by floors and ceilings, revealing rough white platform edges with grass specks and 3 layers of grey machinery, then fading through a dim ghost. Multiple bubbles overlap gracefully. Commit: `checkpoint: phase 2 sonar vertical slice`.

---
# PHASE 3 — Hearing & the Listener

### TASK P3-T1: StateMachine / State
Files: `scripts/core/state_machine.gd`, `scripts/core/state.gd`.
Goal/Spec: ARCH §6. `State` (`class_name State extends Node`): `var machine: StateMachine`, `var actor: Node`, virtual `enter(msg: Dictionary)`, `exit()`, `update(delta)`, `physics_update(delta)`, helper `transition(name: StringName, msg := {})`. `StateMachine` (`class_name StateMachine extends Node`): `@export var initial: State`, `@export var actor: Node`; on ready assigns machine/actor to children; `transition_to(name, msg)` calls exit/enter, emits `state_changed(actor, from, to)`; forwards `_process`/`_physics_process`. Ignore transition to the same state unless `msg.get("force")`.
Depends on: P0. Acceptance: PC; tiny test in `tests/test_resources.gd`? → no: add `tests/test_state_machine.gd` (allowed helper) verifying enter/exit order.
How to test: TC. Pitfalls: children `_ready` run before parent — assign in parent `_ready`.
Commit: `P3-T1: state machine`

### TASK P3-T2: NoiseBus + HearingComponent
Files: `autoload/noise_bus.gd`, `scenes/enemies/hearing_component.gd`, `tests/test_hearing.gd`.
Depends on: P3-T1, P2-T6
Spec: AI §1 hearing math and ARCH §3. `HearingComponent` (`class_name HearingComponent extends Node2D` so it has a position): `@export var profile: EnemyProfile`; `static func evaluate(d: float, walls: int, event_radius: float, loudness: float, type: int, profile: EnemyProfile, wall_penalty: float) -> float` returns strength or −1 (pure → unit-testable); `func consider(event)` does cheap reject → raycast walls (repeated, exclude prior RIDs, max 3) → evaluate → schedule delivery timer `d / sound_speed` → `heard.emit(event, strength)`. Ignore events whose `source` is its own owner. NoiseBus: on `emit_noise` iterate group `listeners` and call `consider`; still emits `noise_emitted`. Tests: whisper at 40 px heard by Listener (strength>0), at 50 px not; normal through 1 wall at 120 px heard (120×1.75=210 > 200 → NOT heard — assert −1); scream at 700 px heard by Sentry; footstep ignored by Listener (threshold) and heard by Hunter at 45 px (40×1.25=50).
Acceptance: TC passes.
Pitfalls: raycasts must run in `_physics_process` context or use `PhysicsDirectSpaceState2D` from `get_world_2d()` — it's valid outside physics step in 4.x for queries, but results are from last physics frame (fine).
Commit: `P3-T2: hearing`

### TASK P3-T3: EnemyBase + components
Files: `scenes/enemies/enemy_base.tscn`, `enemy_base.gd`, `awareness.gd`, `noise_memory.gd`, `vision_component.gd`.
Depends on: P3-T2
Spec: Tree ARCH §9; `EnemyBase` (`class_name EnemyBase extends CharacterBody2D`): `@export var profile: EnemyProfile`, `@export var kind: StringName`, gravity from cfg, `facing:int`, `func face(dir)`, `func die_player_on_contact` via Hitbox `body_entered` → `body.die(&"caught")`; group `enemies`; wires Hearing.heard → Awareness + NoiseMemory; exposes `last_noise`, `last_seen`. Awareness/Memory/Vision per AI §1 (Vision uses `PulseRegistry.reveal_at(player)` + cone + raycast every `vision_tick`).
Acceptance: PC; enemy_base.tscn opens.
How to test: P3-T7.
Commit: `P3-T3: enemy base`

### TASK P3-T4: PlatformMover (flat mode)
Files: `scenes/enemies/platform_mover.gd`.
Depends on: P3-T3
Spec: `class_name PlatformMover extends Node`; `@export var body: EnemyBase`; `func move_to(target: Vector2, speed: float)`, `func stop()`, signals `arrived`, `path_failed`. Flat mode (no `PlatformGraph` set): walk horizontally toward target.x on current floor; stop at walls (`is_on_wall`) or ledges (downward raycast 20 px ahead at foot fails) → `path_failed` if target not reached; arrived when `abs(dx) < 6`. Graph mode added in P4-T4 (leave `var graph: PlatformGraph = null` and a branch that push_warning STUB). Also `func patrol_segment() -> Vector2` (min_x, max_x of current floor run limited by walls, ledges, `|` bounds supplied via `var bounds: Array[float]`).
Acceptance: enemy walks to a clicked point (P3-T7) and stops at ledges.
Commit: `P3-T4: platform mover flat`

### TASK P3-T5: Listener FSM
Files: `scenes/enemies/states/st_patrol.gd`, `st_investigate.gd`, `st_search.gd`, `st_chase.gd`, `st_return.gd`, `scenes/enemies/listener.tscn`, `scenes/enemies/visuals/listener_visual.tscn`, `listener_visual.gd`.
Depends on: P3-T4
Spec: AI §3 table exactly (timers from profile). CHASE entry calls `GameState.register_detection(enemy)` (add method to game_state.gd: increments `stats.detections`, emits `detected`) and emits an ENEMY NoiseEvent (radius 120, loudness 0) for the ripple. Visual: AA §3 Listener shape (static pose now; animation P6-T4), implements Visual API, `light_mask` 3, material flat_reveal red for now.
Acceptance: In sandbox: Listener patrols; whisper beside it (≤43 px) alerts; whisper at 60 px doesn't; normal at 150 px → walks to origin, searches 4 s, returns.
How to test: P3-T7.
Commit: `P3-T5: listener`

### TASK P3-T6: Enemy shaders + smudge
Files: `shaders/enemy_silhouette.gdshader`, `shaders/smudge_blur.gdshader`, `scenes/enemies/smudge.tscn`, `smudge.gd`, `listener_visual.gd` (switch material), `scenes/enemies/enemy_base.gd` (smudge hookup).
Depends on: P3-T5
Spec: SHD §6, §7. EnemyBase spawns a Smudge into the level's `SenseLayer` (find via group `sense_layer`); on any noise made by the enemy OR heard-strength event while `reveal_at(self) < threshold` → smudge.show_at(global_position) opacity 0.5 → 0 in 1.2 s; follows enemy while visible. Visual sets `alert` from Awareness, `flash` on state change.
Acceptance: enemy unrevealed but alerting → dark-red blurred blob visible; revealed → crisp red silhouette.
Commit: `P3-T6: enemy shaders`

### TASK P3-T7: Enemy debug page + sandbox_enemy
Files: `scenes/debug/debug_overlay.gd`, `sandbox/sandbox_enemy.tscn`.
Depends on: P3-T6
Spec: ARCH §15 page 0 enemy items + AI §9 (noise circles by type, hearing rings, cones, state labels, awareness, memory crosses, mover target). sandbox_enemy = copy of sandbox_sonar room + 1 Listener on the bottom floor + `SenseLayer` CanvasLayer(2, follow_viewport, group `sense_layer`); mouse right-click sets a debug move target for the Listener (only in sandbox).
Acceptance: F1 shows all debug items; the Listener scenario in P3-T5 is reproducible.
**CHECKPOINT P3** — Listener patrols in darkness; whisper is safe, normal/scream draw it to the pulse origin; F1 shows hearing radius, state and noise circles; unrevealed alerts show as red smudges. Commit: `checkpoint: phase 3 hearing and listener`.
Commit (task): `P3-T7: enemy debug + sandbox`

---
# PHASE 4 — ASCII levels

### TASK P4-T1: LevelParser
Goal: Text → `LevelData`.
Files: `scenes/level/level_parser.gd`, `tests/test_level_parser.gd`, `levels/level_test.txt`.
Depends on: P0-T8
Detailed spec: `class_name LevelParser`, `static func parse_file(path: String) -> LevelData` and `parse_text(text: String) -> LevelData`. Headers `;key=value` (int-cast `decoys`, `seed`). Grid rows: strip `\r`; width = first row length; fill `cells[char] = Array[Vector2i]` for every non-`.` char; `player_spawn`, `exit_cell`. Errors (`push_error`) for ragged rows. `level_test.txt` = a 20×8 map using every legend char at least once (LVL §1).
Acceptance: TC: level_test parses, counts correct, header values typed; level_01 (created in P4-T7 — for now test uses an inline string copy of LVL Level 1) width 40 height 11, spawn (2,9), exit (36,9).
How to test: TC.
Commit: `P4-T1: level parser`

### TASK P4-T2: SolidMerger + LevelBuilder (solids)
Files: `scenes/level/solid_merger.gd`, `scenes/level/level_builder.gd`.
Depends on: P4-T1, P2-T3
Spec: LVL §1 auto-gen rule 1. `SolidMerger.merge(grid, char := "#") -> Array[Rect2i]` (row runs then vertical merge). `LevelBuilder.build(data: LevelData, root: LevelRoot)`: creates `Solids` StaticBody2D (layer 1) with per-rect CollisionShape2D(RectangleShape2D) + LightOccluder2D (OccluderPolygon2D closed, `cull_mode` disabled, `occluder_light_mask` 1) + Polygon2D black; `OneWays` StaticBody2D layer 2 with one CollisionShape2D per horizontal run of `=` (rect height 8 at top of cell, `one_way_collision` true, margin 4). `G`, doors handled by spawner (P5).
Acceptance: Level 1 builds ≤ 12 rects; player collides; `=` one-way works.
How to test: temporary call in sandbox or after P4-T6.
Pitfalls: Rect pixel = cell × 32; shape position is centre.
Commit: `P4-T2: solids builder`

### TASK P4-T3: EdgeBuilder from grid
Files: `scenes/world/edge_builder.gd`, `scenes/level/level_builder.gd` (call it).
Depends on: P4-T2, P2-T4
Spec: LVL §1 rule 2; exposed sides of solid cells (neighbour not solid; out-of-bounds counts as solid so the outer border isn't edged on the outside); merge collinear; top edges `is_top=true`; one-way runs get a top edge (width 2.0, no specks). RNG seeded from `data.seed`. Parent `EdgeLines` node.
Acceptance: Level 1 shows jagged white top edges with specks and thinner side edges only inside bubbles.
Commit: `P4-T3: edge builder`

### TASK P4-T4: PlatformGraph + mover graph mode
Files: `scenes/level/platform_graph.gd`, `tests/test_platform_graph.gd`, `scenes/enemies/platform_mover.gd`.
Depends on: P4-T1, P3-T4
Spec: ARCH §1 nav. `class_name PlatformGraph extends RefCounted`: `build(data: LevelData, solid_fn: Callable)`, `AStar2D` ids = `r*width + c`, positions = cell bottom-centre px; edges with metadata dictionary `edge_type[(a,b)] = WALK|JUMP|DROP` (directed: JUMP up / DROP down are one-directional). Jump: rise ≤2, |dx| ≤3, require empty arc cells (check cells above start up to rise+1 and above target). `find_path(from_px, to_px) -> PackedVector2Array` + `path_types`. `nearest_node(px)`. `func path_length(a,b) -> float` (for HUD progress). `set_door_open(cell, open)` toggles node disabled state for door cells (`AStar2D.set_point_disabled`). Mover graph mode: follows waypoints; WALK steer; JUMP: when aligned within 4 px of edge start, set `vy = -sqrt(2*g*(rise*32+20))`, keep horizontal speed; DROP: walk off / for one-way under feet, disable mask bit 2 for 0.2 s. Re-path every `repath_interval` while moving. If `can_jump` false, JUMP edges excluded (build a second AStar2D or weight 1e6). Tests: Level 1 spawn→exit path exists; Level 2 path uses ≥1 JUMP; jump of 3 tiles up doesn't exist in a synthetic map.
Acceptance: TC; Listener in level 2 can follow a noise onto a catwalk.
Commit: `P4-T4: platform graph`

### TASK P4-T5: LevelValidator
Files: `scenes/level/level_validator.gd`, `tests/test_validator.gd`.
Depends on: P4-T4
Spec: LVL §2 checklist exactly (door/key/plate logic via repeated BFS on PlatformGraph). `static func validate(data) -> Array[String]` (errors) and warnings array. Tests: all `levels/level_*.txt` present in the folder validate with zero errors (iterate `DirAccess`), plus 3 synthetic broken maps (no exit, ragged, enemy near spawn) fail.
Acceptance: TC.
Commit: `P4-T5: validator`

### TASK P4-T6: EntitySpawner + LevelRoot
Files: `scenes/level/entity_spawner.gd`, `scenes/level/level_root.tscn`, `level_root.gd`.
Depends on: P4-T3, P3-T7
Spec: LevelRoot tree ARCH §9. `level_root.gd` (`class_name LevelRoot`): `func load_level(path)`: parse → validate (debug build: errors → push_error but continue) → BackgroundBuilder → LevelBuilder → PlatformGraph → spawner → set camera limits → size SonarAir to map + 64 px margin → add DebugDraw → emit `SceneRouter.level_loaded`. EntitySpawner: char→scene map (`P` player, `L` listener …); entity char cells: place at cell bottom-centre; for chars whose scene doesn't exist yet (P5), `push_warning("STUB: spawn <c>")` once. Assigns `graph` to every PlatformMover and `|` bounds.
Acceptance: `level_root.tscn` with `@export var level_path` = level_test.txt runs: dark, player spawns, pulses reveal edges + background.
Commit: `P4-T6: level root`

### TASK P4-T7: SceneRouter + levels 1–2
Files: `autoload/scene_router.gd`, `levels/level_01.txt`, `levels/level_02.txt`, `scenes/main/main.gd`.
Depends on: P4-T6
Spec: Copy maps verbatim from LVL §4. SceneRouter: `load_level(index)` instantiates LevelRoot under Main/LevelHost (free previous), fade via a black ColorRect on Menus layer (0.25 s), `restart_level()` (instant, no fade, ≤ 1 frame stall acceptable), `next_level()`, signal `level_loaded(level_root)`. `restart` action → restart. Main boots straight into level 1 for now.
Acceptance: F5 → Level 1 playable to E (E not yet functional — reaching it does nothing; that's fine); R restarts; debug key F3 (debug build only) loads next level. Validator passes both maps (TC).
**CHECKPOINT P4** — Levels 1 and 2 load from text, look like the sandbox, Listener in level 2 navigates catwalks via the graph (F1 page 1 shows graph). Commit: `checkpoint: phase 4 ascii levels`.
Commit (task): `P4-T7: router and levels 1-2`

---
# PHASE 5 — Enemies, interactables, rules

### TASK P5-T1: Interactable base, fragment, keycard, exit
Files: `scenes/interactables/interactable.tscn`, `interactable.gd`, `fragment.tscn`, `fragment.gd`, `keycard.tscn`, `keycard.gd`, `exit_terminal.tscn`, `exit_terminal.gd`.
Depends on: P4-T7
Spec: `Interactable` (`class_name Interactable extends Area2D`, layer 5, mask 3|4): `@export var cell: Vector2i`, child `Visual`, virtual `_on_player_entered(p)`, `_on_enemy_entered(e)`, helper `emit_noise(radius, loudness, type)`. Fragment: diamond 8×8 white with slow bob (flat_reveal), id from spawner; on player → `GameState.collect_fragment(id)` + noise 0 + particles stub; free. Keycard: 10×7 card shape with notch; `GameState.has_keycard = true`, signal. ExitTerminal: 18×26 terminal (screen rect + stand), screen dot unshaded blinking (always visible as beacon); on player → disable player input, play 0.8 s sequence (AnimationPlayer: screen fill white, text "SIGNAL RESTORED" Label unshaded), then `GameState.complete_level()` (implemented P5-T10; stub now logs).
Acceptance: collecting works; E triggers sequence.
Commit: `P5-T1: base interactables`

### TASK P5-T2: Doors + pressure plate
Files: `scenes/interactables/door.tscn`, `door.gd`, `pressure_plate.tscn`, `pressure_plate.gd`.
Depends on: P5-T1
Spec: Door = StaticBody2D (layer 1) 2 cells tall, 10 px wide centred, LightOccluder2D, Visual (outline rect + slot glyph; KEY doors show a key-notch glyph, PLATE doors show 3 bars). `mode KEY`: Interactable sensor child; on player entered && has_keycard → open. `mode PLATE`: group `plate_doors`, `func on_plate()` → open. Open = tween Visual up 64 px 0.6 s, disable collision + occluder (`set_deferred`), PlatformGraph.set_door_open, door_open sfx, noise r 64 loud 0.5 PLATE type. Plate: 24×4, pressed by player or enemy body; once → `get_tree().call_group("plate_doors","on_plate")`, click noise r 64 loud 1.0 PLATE.
Acceptance: level_test door/plate behave.
Commit: `P5-T2: doors and plates`

### TASK P5-T3: One-way door
Files: `scenes/interactables/one_way_door.tscn`, `one_way_door.gd`.
Depends on: P5-T2
Spec: StaticBody2D collision 2 cells tall, 6 px wide; `dir` +1 (`>`) or −1 (`<`). Blocks only when player velocity.x · dir < 0: implement via a sensor Area2D slightly larger; when the player is inside the sensor and moving with dir, disable body collision (deferred); re-enable on exit. Visual: thin vertical line + chevrons pointing dir. Does not occlude. Graph: edges through the door cell only in `dir`.
Acceptance: can pass right through `>`, cannot pass back.
Commit: `P5-T3: one-way door`

### TASK P5-T4: Glass floor
Files: `scenes/interactables/glass_floor.tscn`, `glass_floor.gd`, `shaders/glass_crack.gdshader`.
Depends on: P5-T1
Spec: SHD §8 + GDD §6. StaticBody2D layer 1 cell-sized + occluder; group `wave_reactive`: `on_wavefront(profile, origin)`: scream → break; normal → crack 0.4. Brute standing (body above with group `brute`) → break. Break: shards particles, GLASS noise r 360 loud 3.0 from the glass, collision+occluder off, graph update (cell becomes non-standable), sfx.
Acceptance: level 4 glass breaks on scream, not on whisper.
Commit: `P5-T4: glass`

### TASK P5-T5: Lantern
Files: `scenes/interactables/lantern.tscn`, `lantern.gd`.
Depends on: P5-T1
Spec: SHD §9 physics; chain Line2D length 72 px from ceiling cell bottom; lamp polygon; group `wave_reactive`; CLINK noise r 96 loud 1.0 throttled 1.5 s.
Acceptance: scream makes lanterns swing and settle in ~3 s.
Commit: `P5-T5: lantern`

### TASK P5-T6: Vents
Files: `scenes/interactables/vent.tscn`, `vent.gd`, `autoload/noise_bus.gd` (hook), `scenes/player/pulse_charger.gd` (mute factor).
Depends on: P5-T1
Spec: GDD §6 / LVL legend. `mode INTAKE/OUTLET/MUTE`; spawner pairs i-th V with i-th v (`intake.outlet = outlet`). NoiseBus: before routing, call `get_tree().get_nodes_in_group("vent_intakes")` → if event within 96 px of an intake and `event.source` is not a vent → after 0.2 s emit a new event at the outlet (radius `max(r*4, 240)`, loudness +1.5, type same, source = outlet vent) — prevents loops. MUTE: Area2D r 64; on player inside → `pulse_charger.noise_scale = 0.3`, else 1.0 (charge red ring reflects it). Visual: grate rect with 3 slats; intake/outlet show arrows; mute shows a crossed wave glyph.
Acceptance: level 6 lure works: Normal at V pulls the Hunter to v.
Commit: `P5-T6: vents`

### TASK P5-T7: Sentry + projectile
Files: `scenes/enemies/states/st_sentry_idle.gd`, `st_sentry_aim.gd`, `st_sentry_fire.gd`, `scenes/enemies/sentry.tscn`, `scenes/enemies/visuals/sentry_visual.tscn`, `sentry_visual.gd`, `scenes/enemies/projectile.tscn`, `projectile.gd`.
Depends on: P3-T7
Spec: AI §4. Sentry has no gravity (static), no Hitbox. Laser tick: unshaded Line2D red α0.4 dotted (draw_dashed_line). Projectile per AI §4 incl. reticle (WorldReticle comes P7-T2; for now draw a 1 px white circle in projectile `_draw`, unshaded) and IMPACT noise; kills player (`die(&"shot")`).
Acceptance: level 4: scream → sentry aims at origin after 0.6 s and fires; standing revealed in cone → it tracks you.
Commit: `P5-T7: sentry`

### TASK P5-T8: Hunter
Files: `scenes/enemies/states/st_hunter_track.gd`, `scenes/enemies/hunter.tscn`, `scenes/enemies/visuals/hunter_visual.tscn`, `hunter_visual.gd`.
Depends on: P4-T4
Spec: AI §5 (reuses st_patrol/search/chase/return with hunter profile; memory 3; TRACK ripple every 1.2 s).
Acceptance: three pulses at A, B, C → hunter visits A, B, C in order; scream → sprint.
Commit: `P5-T8: hunter`

### TASK P5-T9: Brute
Files: `scenes/enemies/states/st_brute_wander.gd`, `st_brute_charge.gd`, `st_stunned.gd`, `scenes/enemies/brute.tscn`, `scenes/enemies/visuals/brute_visual.tscn`, `brute_visual.gd`.
Depends on: P4-T4
Spec: AI §6. group `brute`. Step thud ripples (ENEMY type, loudness 0 → no one reacts). Camera trauma request via `get_tree().call_group("camera_rig","add_trauma",0.03)` if within 160 px of player.
Acceptance: level 5: pulses ignored, running near it triggers CHARGE, sneaking doesn't.
Commit: `P5-T9: brute`

### TASK P5-T10: GameState — death, win, restart, stats, medals
Files: `autoload/game_state.gd`, `scenes/player/player.gd`, `autoload/scene_router.gd`.
Depends on: P5-T1…T9
Spec: GDD §4.5, §8. Stats dictionary keys: `time`, `pulses` ({whisper, normal, scream}), `loudest` (tier int), `detections`, `fragments` (Array[int]), `level_index`. Listens `pulse_released` (via SonarSystem relay or player group), detection, fragments. `func compute_medal(stats) -> StringName` (`&"ghost"|&"quiet"|&"loud"`) — add `tests/test_medals.gd`(helper). Death: player.die → input off, death anim placeholder (hide), after `death_time` → `SceneRouter.restart_level()`. Fall-out: y > map bottom + 200 → die(&"fell"). Win: `complete_level()` → emit `level_completed(stats)` → (P7 shows UI) for now SceneRouter.next_level after 1 s.
Acceptance: levels 1–2 completable end-to-end; death restarts ≤ 1 s; TC medals test.
**CHECKPOINT P5** — All four enemy types and all interactables work in `level_test.txt`; levels 1–2 can be won and lost. Commit: `checkpoint: phase 5 gameplay complete`.
Commit (task): `P5-T10: game state rules`

---
# PHASE 6 — Juice: post, animation, audio

### TASK P6-T1: Post FX
Files: `scenes/fx/post_fx.tscn`, `post_fx.gd`, `shaders/post_fx.gdshader`, `scenes/main/main.tscn` (instance into PostFx layer).
Depends on: P5
Spec: SHD §10. `post_fx.gd`: listens `pulse_released` (scream → ca burst), `GameState.detected` (flash + ca), `SaveData.settings_changed` (grain/CA toggles). ColorRect full rect, mouse_filter IGNORE.
Acceptance: vignette + grain always; scream → mono CA burst; detection → white flash frame.
Commit: `P6-T1: post fx`

### TASK P6-T2: Camera juice + hit-stop
Files: `scenes/fx/camera_rig.gd`, `scenes/fx/hitstop.gd`.
Depends on: P6-T1
Spec: AA §5 shake/zoom/hit-stop. CameraRig joins group `camera_rig`; listens `pulse_released` (trauma by tier, zoom punch on scream), `detected`, `player_died`. `HitStop` static `func freeze(tree: SceneTree, dur: float)`.
Acceptance: scream shakes + zooms; death hit-stops; shake slider (later) scales.
Commit: `P6-T2: camera juice`

### TASK P6-T3: Robot procedural animation + death burst
Files: `scenes/player/player_visual.gd`, `player_visual.tscn`, `scenes/player/death_burst.tscn`.
Depends on: P5-T10
Spec: AA §2 all poses. Visual API from GEMINI_RULES §6. Eye unshaded.
Acceptance: all poses visibly distinct; death disintegrates.
Commit: `P6-T3: robot animation`

### TASK P6-T4: Enemy animations + alert glyphs
Files: `scenes/enemies/visuals/listener_visual.gd`, `sentry_visual.gd`, `hunter_visual.gd`, `brute_visual.gd`.
Depends on: P5-T9
Spec: AA §3; glyph Label child created in code (theme font), unshaded.
Acceptance: each enemy animates per spec; "?" on investigate, "!" on chase.
Commit: `P6-T4: enemy animation`

### TASK P6-T5: Particles factory
Files: `scenes/fx/particles_factory.gd`.
Depends on: P6-T3
Spec: AA §4 table; static creators returning configured CPUParticles2D (one_shot, emitting, auto-free on `finished`); global alive counter ≤ 300. Replace earlier particle stubs (fragment, glass, terminal, landing, impact) with factory calls (touch those files minimally).
Acceptance: effects visible; overlay shows particle count.
Commit: `P6-T5: particles`

### TASK P6-T6: Synth SFX + AudioManager + buses
Files: `audio/synth.gd`, `audio/sfx_library.gd`, `autoload/audio_manager.gd`, `default_bus_layout.tres`.
Depends on: P6-T5
Spec: AA §6.1–6.2, §6.4. `Synth` static DSP helpers (`sine`, `saw`, `square`, `noise`, `env_exp`, `glide`, `echo`, `lowpass_onepole`, `to_wav(samples: PackedFloat32Array) -> AudioStreamWAV`). `SfxLibrary.build() -> Dictionary` id→AudioStreamWAV (render at boot; log total ms; must be < 1500 ms). AudioManager: pool, `play_sfx(id, pos, pitch)`, listens NoiseBus/pulse signals to auto-play matching cues, `set_pulse_reverb(tier)`, volumes from SaveData.
Acceptance: every SFX id plays; pulses audibly differ by tier; reverb grows with scream.
Pitfalls: `AudioStreamWAV.data` expects little-endian 16-bit; set `format = FORMAT_16_BITS`, `mix_rate = 44100`, `stereo = false`.
Commit: `P6-T6: audio sfx`

### TASK P6-T7: Music layers
Files: `audio/music_layers.gd`, `autoload/audio_manager.gd`, `autoload/game_state.gd` (`alert_level`).
Depends on: P6-T6
Spec: AA §6.3. `GameState.alert_level` = smoothed max awareness over group `enemies` (update 10 Hz). Loops with `loop_mode = LOOP_FORWARD`.
Acceptance: drone always; tension rises as enemies grow aware; chase layer on chase.
**CHECKPOINT P6** — The game feels alive: shake, zoom, CA on screams, animated silhouettes, procedural pings with reverb, adaptive music. Commit: `checkpoint: phase 6 juice`.
Commit (task): `P6-T7: music layers`

---
# PHASE 7 — UI, menus, saves

### TASK P7-T1: Full HUD
Files: `scenes/ui/hud.tscn`, `hud.gd`, `fragment_counter.gd`, `ability_slot.tscn`, `ability_slot.gd`, `pip_row.gd`, `level_label.gd`, `scenes/ui/ui_button.gd`, `sandbox/sandbox_ui.tscn`.
Depends on: P6
Spec: UI §1–§2 exactly (tree, sizes, anchors, safe margins, progress via `PlatformGraph.path_length`). `ui_button.gd` (`class_name UiButton extends Button`): plays ui sfx on focus/press, red on hover/focus via theme. sandbox_ui: HUD driven by fake signals (keys to change energy, fragments, decoys).
Acceptance: matches layout at 1280×720, 1920×1080, 2560×1080 (ultrawide) — screenshots attached in CHANGELOG notes.
Commit: `P7-T1: full HUD`

### TASK P7-T2: Awareness bars + reticles
Files: `scenes/ui/awareness_bar.tscn`, `awareness_bar.gd`, `scenes/ui/world_reticle.tscn`, `world_reticle.gd`, `scenes/enemies/enemy_base.gd`, `scenes/enemies/projectile.gd`.
Depends on: P7-T1
Spec: UI §3. EnemyBase spawns its AwarenessBar into SenseLayer; projectile replaces its temp circle with WorldReticle(PROJECTILE); investigating enemies show NOISE_ORIGIN reticle.
Acceptance: bars only on revealed enemies; reticles crisp 1 px.
Commit: `P7-T2: awareness bars and reticles`

### TASK P7-T3: Main menu + title
Files: `scenes/ui/main_menu.tscn`, `main_menu.gd`, `scenes/ui/title_logo.gd`, `shaders/title_glitch.gdshader`, `scenes/main/main.gd`.
Depends on: P7-T1
Spec: UI §4 Main menu; SHD §11. Main now boots into the menu.
Acceptance: title wipes in with sonar ring, glitches periodically, buttons navigable by keyboard & gamepad.
Commit: `P7-T3: main menu`

### TASK P7-T4: Pause menu
Files: `scenes/ui/pause_menu.tscn`, `pause_menu.gd`.
Depends on: P7-T3
Spec: UI §4 Pause. `process_mode = PROCESS_MODE_ALWAYS`.
Acceptance: Esc pauses everything (enemies, bubbles, audio fades -10 dB), resume restores.
Commit: `P7-T4: pause`

### TASK P7-T5: Settings + SaveData settings
Files: `scenes/ui/settings_menu.tscn`, `settings_menu.gd`, `autoload/save_data.gd`, `autoload/palette_service.gd`, `scenes/player/pulse_charger.gd` (quick-scream option).
Depends on: P7-T4
Spec: UI §4 Settings table + UI §5 quick scream. Colour-blind applies at runtime (Palette.palette_changed → visuals re-read colours; `hatch` uniforms set).
Acceptance: every setting applies immediately and persists across restart.
Commit: `P7-T5: settings`

### TASK P7-T6: Level complete + level select + medals save
Files: `scenes/ui/level_complete.tscn`, `level_complete.gd`, `scenes/ui/level_select.tscn`, `level_select.gd`, `autoload/save_data.gd`, `autoload/scene_router.gd`.
Depends on: P7-T5
Spec: UI §4. SaveData: `levels/<n>/best_time`, `best_medal` (ghost>quiet>loud), `fragments_mask`, `unlocked`. Continue = highest unlocked.
Acceptance: full loop menu → level → complete screen → next; progress persists.
**CHECKPOINT P7** — Complete UI per §2B; settings and progress saved. Commit: `checkpoint: phase 7 ui`.
Commit (task): `P7-T6: level complete and select`

---
# PHASE 8 — Content & balance

### TASK P8-T1: Decoy beacon
Files: `scenes/interactables/decoy_beacon.tscn`, `decoy_beacon.gd`, `scenes/interactables/decoy_pickup.tscn`, `scenes/player/player.gd`, `autoload/game_state.gd`.
Depends on: P7
Spec: GDD §7. Beacon: RigidBody2D? → **no**: CharacterBody2D-less simple projectile with manual gravity + `move_and_collide`, stops on floor; after 0.5 s calls SonarSystem.spawn(pulse_decoy, pos) and emits DECOY NoiseEvent (radius = decoy noise radius, loudness 2.0); then fades. Pickup `C` +1 (max 3). HUD pips + primary slot active state.
Acceptance: decoy lures a Listener away; HUD pips update.
Commit: `P8-T1: decoy`

### TASK P8-T2: Hint signs
Files: `scenes/interactables/hint_sign.tscn`, `hint_sign.gd`, `levels/level_01.txt`, `levels/level_02.txt` (add `?` + headers).
Depends on: P8-T1
Spec: UI §3. Level 1: `?` at (5,9) hint_0 = "HOLD [K] / LMB"; level 2: `?` near the low catwalk hint_0 = "[SHIFT] SNEAK". Signs only visible when lit. Level 1 start: unshaded controls hint text at the bottom-centre above level name, fades after first movement (HUD).
Acceptance: hints readable inside a whisper bubble.
Commit: `P8-T2: hint signs`

### TASK P8-T3: Levels 3–5
Files: `levels/level_03.txt`, `level_04.txt`, `level_05.txt`.
Depends on: P8-T2
Spec: copy from LVL §4 verbatim; run validator; fix minimally if needed (log OPEN_QUESTIONS).
Acceptance: TC validator passes; each level completable by its "Solution" line; Ghost medal achievable.
Commit: `P8-T3: levels 3-5`

### TASK P8-T4: Levels 6–8
Files: `levels/level_06.txt`, `level_07.txt`, `level_08.txt`.
Depends on: P8-T3
Spec/Acceptance: as P8-T3.
Commit: `P8-T4: levels 6-8`

### TASK P8-T5: Balancing pass
Files: `resources/config/default_config.tres`, `resources/pulses/*.tres`, `resources/enemies/*.tres`, `docs/BALANCE_LOG.md` (new, allowed).
Depends on: P8-T4
Spec: Play each level 3× (or ask the user to). Targets: LVL §3 times; Ghost achievable every level; Scream must be useful in ≥5 levels and fatal-if-careless in ≥4. Only change numbers in resources; record every change (old→new, why) in BALANCE_LOG.md. Never change whisper noise_mult above 0.6 or scream below 1.3.
Acceptance: BALANCE_LOG complete; TC passes.
**CHECKPOINT P8** — 8 levels, full difficulty curve. Commit: `checkpoint: phase 8 content`.
Commit (task): `P8-T5: balance pass`

---
# PHASE 9 — Ship

### TASK P9-T1: Performance & quality mode
Files: `autoload/game_config.gd`, `scenes/sonar/sonar_system.gd`, `scenes/world/background_builder.gd`, `docs/PERF_REPORT.md` (new, allowed).
Depends on: P8
Spec: ARCH §14 budget & degrade order; Performance setting toggles. Measure with Godot Profiler + overlay on level 8 with 6 screams: record avg/min FPS, draw calls, lights in PERF_REPORT tables (TP §3).
Acceptance: ≥ 60 FPS avg on target hardware (or documented); LOW mode works.
Commit: `P9-T1: performance`

### TASK P9-T2: Bug-bash
Files: any (minimal fixes), `docs/BUGS.md` (new, allowed).
Depends on: P9-T1
Spec: run full TP regression list; log each bug (repro, fix, commit).
Acceptance: no open P1/P2 bugs.
Commit: `P9-T2: bug bash`

### TASK P9-T3: Export presets + README
Files: `export_presets.cfg`, `README.md`.
Depends on: P9-T2
Spec: Windows Desktop + Linux/X11 presets, output `export/SignalLost.exe` / `.x86_64`, embed PCK. README: pitch, controls table, build steps, credits (Rajdhani OFL), project structure link to docs.
Acceptance: exported build runs outside the editor.
**CHECKPOINT P9** — Shippable build. Commit: `checkpoint: phase 9 release 1.0`.
Commit (task): `P9-T3: export and readme`

---
# PHASE 10 — Optional stretch (only if user asks)
- **P10-T1 EMP** (`ability_secondary`): 1 charge/level, 2.5 s deafness (HearingComponent disabled) for enemies within 160 px; secondary HUD slot goes red when available. Files: `scenes/interactables/emp_burst.tscn/.gd` (new).
- **P10-T2 Echo memory upgrade**: ghost_time 2 → 6 s and ghost_energy 0.12 → 0.18 as a per-level pickup.
- **P10-T3 Mimic**: AI §7. Files: `scenes/enemies/mimic.tscn`, `states/st_mimic_wait.gd`.
Each follows the standard template when started; add them to ARCH §8 first via OPEN_QUESTIONS.

