# Error List and Triage for SIGNAL LOST

## Initial Audit Findings

### 1. `NoiseEvent.origin` Crash
- **Location**: `res://scenes/sonar/ripple_rings.gd:23`
- **Cause**: Code accesses `event.origin`, but `NoiseEvent` (in `scripts/core/noise_event.gd`) defines the field as `position: Vector2`.
- **Impact**: Any footstep, landing, or noise event crashes or triggers debugger errors (`Invalid access to property or key 'origin' on a base object of type 'RefCounted (NoiseEvent)'`).
- **Fix**: Standardize `NoiseEvent` with fields: `position: Vector2`, `radius: float`, `loudness: float`, `type: NoiseType`, `source: Node` (with `origin` and `emitter` accessors/aliases for backwards compatibility). Ensure all references across the codebase consistently use `position`. Guard the ripple pool against empty pop_front().

### 2. Washed Out / Foggy Grey Scene & Lack of Darkness
- **Locations**: 
  - `project.godot`: Default clear color was missing, defaulting Godot to standard grey `#4d4d4d` instead of pure black `#000000`.
  - `shaders/post_fx.gdshader`: Grain addition `c += n * grain_amount` lifted pure black into noisy grey.
  - `scenes/level/level_root.tscn` / `scenes/world/background_builder.gd`: Geometry rendered over unshaded grey viewport background.
- **Impact**: Screen appears flat grey and foggy rather than pure black sonar darkness.
- **Fix**: 
  - Set `environment/defaults/default_clear_color=Color(0, 0, 0, 1)` in `project.godot`.
  - Ensure post-processing shader clamps or multiplies grain by luminance so black pixels stay pure black `#000000`.
  - Add dark ambient styling matching spec.

### 3. Sonar Pulse Input & Visuals Missing
- **Locations**:
  - `project.godot`: `jump` is bound to Space (`keycode 32`), while `pulse` is bound to `[K / LMB]`. Space did not emit or charge pulses.
  - `scenes/sonar/pulse_bubble.gd` & `scenes/sonar/charge_rings.gd`: Pulse visual representation does not produce the specified bright wavefront arc, trailing ripples, and occlusion reveal.
- **Impact**: Core sonar mechanic cannot be used with Space and does not visually reveal the world.
- **Fix**: Rebind Space to charge/release pulse (Hold Space to charge, release to emit: whisper/normal/scream). Implement crisp wavefront arc with trailing concentric ripples, shadow-casting occlusion, and fading echo memory.

### 4. Window Stretch & Letterboxing
- **Locations**: `project.godot` display settings (`window/size/viewport_width=1280`, `window/size/viewport_height=720`).
- **Fix**: Update base resolution to 1920x1080 with `stretch/mode = "canvas_items"` and `stretch/aspect = "expand"`.

### 5. LevelParser Ragged Row Error in Test Suite
- **Location**: `res://scenes/level/level_parser.gd:49` during `test_validator.gd`
- **Cause**: `push_error` called for test invalid input causes Godot process to exit with error status.
- **Fix**: Clean up test error handling so test expectations don't trigger fatal engine errors.
