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


