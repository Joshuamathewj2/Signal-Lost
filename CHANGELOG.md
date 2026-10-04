# Changelog — SIGNAL LOST

All notable changes to this project will be documented in this file.

## P0-T1 Project settings & repo
- Initialized local Git repository
- Created `.gitignore` ignoring `.godot/`, `export/`, and `*.tmp`
- Created `project.godot` with 1280x720 canvas_items/expand stretch, GL Compatibility renderer, and shadow atlas size 2048
- Created directory hierarchy per ARCH §8 with `.gdkeep` files
- Created `README.md` stub

## P0-T2 Input map & layer names
- Configured 2D physics layer names (world, one_way, player, enemy, interactable, projectile, hazard_kill)
- Configured 2D render layer names (world_fg, world_bg, actors, air)
- Added all 11 input actions with keyboard, mouse, and gamepad bindings per ARCH §12

## P0-T3 Resource class scripts
- Created `GameConfigData` (`scripts/resources/game_config_data.gd`) with typed groups and tunable parameters per GDD §4.1, ARCH §13
- Created `PulseProfile` (`scripts/resources/pulse_profile.gd`) with noise and expand time helper methods
- Created `EnemyProfile` (`scripts/resources/enemy_profile.gd`) for AI parameters per AI §2, ARCH §13
- Created `LevelData` (`scripts/resources/level_data.gd`) for parsed ASCII levels
- Created `PaletteData` (`scripts/resources/palette_data.gd`) for theme and accessibility palettes

## P0-T4 Resource data files
- Generated `default_config.tres` with default gameplay values
- Generated 4 pulse profiles: `pulse_whisper.tres`, `pulse_normal.tres`, `pulse_scream.tres`, `pulse_decoy.tres`
- Generated 4 enemy profiles: `enemy_listener.tres`, `enemy_sentry.tres`, `enemy_hunter.tres`, `enemy_brute.tres`
- Generated 2 palette profiles: `palette_default.tres`, `palette_colorblind.tres`

## P0-T5 Core autoloads
- Created `autoload/game_config.gd` (`GameConfig`) loading config, pulse profiles, and enemy profiles
- Created `autoload/palette_service.gd` (`Palette`) providing color queries, runtime colorblind toggle, and `palette_changed` signal
- Created `autoload/debug_flags.gd` (`DebugFlags`) with F1/F2 toggle handling and debug logging
- Created `scripts/core/math_util.gd` (`MathUtil`) with ease_out_cubic, wave_radius, bubble_brightness, and ring_alpha functions
- Registered `GameConfig`, `Palette`, and `DebugFlags` in `project.godot`

## P0-T6 Stub autoloads
- Created `scripts/core/noise_event.gd` (`NoiseEvent`) with NoiseType enum and factory method
- Created `autoload/noise_bus.gd` (`NoiseBus`) with `noise_emitted` signal and debug log
- Created `autoload/pulse_registry.gd` (`PulseRegistry`) with `reveal_at`, `player_revealed`, and bubble tracking
- Created `autoload/game_state.gd` (`GameState`) with run stats, detections, fragment tracking, and level signals
- Created `autoload/scene_router.gd` (`SceneRouter`) with scene transitions, level loading, and restart methods
- Created `autoload/save_data.gd` (`SaveData`) managing settings and persistence with `user://save.cfg`
- Created `autoload/audio_manager.gd` (`AudioManager`) with SFX playback and reverb methods
- Registered all 9 autoloads in `project.godot` in exact ARCH §7 order

## P0-T7 Main scene & debug overlay shell
- Created `scenes/main/main.tscn` and `main.gd` with node hierarchy per ARCH §9
- Created `scenes/main/boot.gd` logging game, engine, and platform versions
- Created `scenes/debug/debug_overlay.tscn` and `debug_overlay.gd` displaying FPS and page indicators toggled via F1/F2
- Created `scenes/debug/debug_draw.gd` (`DebugDraw`) supporting circle, line, text, and polyline with TTL-based queue drawing
- Set `application/run/main_scene="res://scenes/main/main.tscn"` in `project.godot`

## P0-T8 Test harness
- Created `tests/run_tests.gd` headless test runner extending `SceneTree` dynamically discovering and executing `test_*.gd`
- Created `tests/test_resources.gd` testing all 11 `.tres` resources, whisper/normal/scream pulse noise radii, and MathUtil bubble brightness curves
- Verified TC runs headlessly and reports `ALL TESTS PASSED`

## P0-T9 Font & UI theme
- Bundled Rajdhani fonts (`Rajdhani-Medium.ttf`, `Rajdhani-SemiBold.ttf`) and `OFL.txt` under `assets/fonts/`
- Created `resources/theme/ui_theme.tres` with default font, sizes, Button StyleBoxes, and type variations (`TitleLabel`, `HudLabel`, `LevelNameLabel`, `MenuButton`)
- Registered `gui/theme/custom="res://resources/theme/ui_theme.tres"` in `project.godot`
- Extended `tests/test_resources.gd` to validate theme loading and typography variation sizes








