# SIGNAL LOST — Shader Specification (v1.0)

All shaders are `shader_type canvas_item;` and must compile under **Compatibility** (GLSL ES 3.0 subset). No `hint_depth_texture`, no compute, no global uniform arrays (Godot 4 global uniforms do not support arrays → arrays are per-material uniforms). Uniform names below are **binding**.

Godot 4 canvas `light()` reference used here: inputs `COLOR` (output of fragment), `LIGHT_COLOR` (light colour × texture sample), `LIGHT_ENERGY`, `LIGHT_POSITION`, `LIGHT_VERTEX`, `SHADOW_MODULATE`; output `LIGHT` (vec4). Shadows are applied by the engine after `light()`.

---
## 1. Shared curves (implemented in GDScript `math_util.gd`, mirrored in shaders where needed)
- Wavefront radius: `r(t) = R * ease_out_cubic(clamp(t / T_exp, 0, 1))`, `T_exp = max(R / sound_speed, 0.08)`, `ease_out_cubic(x) = 1 - (1-x)^3`.
- Brightness (bubble energy):
  ```
  if t < T_exp + hold:               b = 1.0
  elif t < T_exp + hold + fade:      u = (t - T_exp - hold)/fade;  b = ghost + (1-ghost) * (1-u)^2
  elif t < ... + ghost_time:         b = ghost * (1 - smoothstep(0.7, 1.0, v))   # v = progress through ghost time
  else:                              dead
  ```
  `ghost = 0.12`. Newer bubbles therefore read brighter; older ones sink to a dim ghost then vanish.
- Ring (arc) alpha: `a_ring = (t < T_exp) ? 1.0 : max(0, 1 - (t - T_exp)/0.35)` — the arc travels with the front and dies 0.35 s after full expansion.

---
## 2. `flat_reveal.gdshader` — world silhouettes (edges, specks, bg props, doors, items)
**Purpose:** turn smooth 2D lighting into flat, crisp silhouette reveals with a soft rim at the bubble edge.
**Used by:** EdgeLines `Line2D`s, speck `Polygon2D`s, Parallax silhouettes, interactable Visuals, player Visual.
| Uniform | Type | Default | Set by |
|---|---|---|---|
| `tint` | vec4 (source_color) | `#FFFFFF` | builder / Visual (`Palette`) |
| `rim_softness` | float | 0.25 | GameConfig.render.rim_softness (BackgroundBuilder/EdgeBuilder) |
| `max_brightness` | float | 1.0 | Visual (bg layers use 1.0, tint carries the grey) |
| `hatch` | bool | false | Palette (colour-blind) |
**fragment:** `COLOR = texture(TEXTURE, UV) * COLOR * tint;`
**light:**
```
float l = clamp(LIGHT_ENERGY * max(LIGHT_COLOR.r, max(LIGHT_COLOR.g, LIGHT_COLOR.b)), 0.0, 1.0);
float k = smoothstep(0.0, rim_softness, l) * l_cap;  // l_cap = min(1, l*4) keeps ghost dim
LIGHT = vec4(COLOR.rgb * k * max_brightness, COLOR.a * k);
```
Use `l_cap = clamp(LIGHT_ENERGY,0,1)` so ghost-energy (0.12) bubbles render at 12% → the "ghost map".
**Test:** `sandbox_sonar.tscn` → bubble over a white Line2D: interior is flat white, boundary has a ~10 px soft rim, wall-shadowed side is black.

## 3. `sonar_air.gdshader` — wavefront arcs + trailing ripples (on `SonarAir` ColorRect)
| Uniform | Type | Default | Set by |
|---|---|---|---|
| `pulse_count` | int | 0 | SonarSystem every frame |
| `pulse_data` | vec4[6] | 0 | SonarSystem: (world_x, world_y, radius_px, ring_alpha) |
| `pulse_style` | vec4[6] | 0 | SonarSystem: (thickness_px, trail_gap_px, trail_count, brightness) |
| `arc_color` | vec4 | `#FFFFFF` α0.85 | Palette |
| `rect_origin` | vec2 | (0,0) | SonarSystem (ColorRect global position) |
**vertex:** pass world position: `world = (MODEL_MATRIX * vec4(VERTEX,0,1)).xy` as varying (ColorRect at known origin; alternatively `rect_origin + VERTEX`).
**fragment:**
```
float a = 0.0;
for (int i = 0; i < 6; i++) { if (i >= pulse_count) break;
  vec4 p = pulse_data[i]; vec4 s = pulse_style[i];
  float d = distance(world, p.xy);
  a = max(a, band(d, p.z, s.x) * p.w);                         // main arc
  for (int k = 1; k <= 3; k++) { if (float(k) > s.z) break;     // trailing rings inside the front
     a = max(a, band(d, p.z - s.y*float(k), s.x*0.6) * p.w * pow(0.45, float(k))); }
}
band(d, r, w) = 1.0 - smoothstep(0.0, w, abs(d - r));   // thin smooth distance-field band
COLOR = vec4(arc_color.rgb, arc_color.a * a);
```
**light:** `LIGHT = vec4(COLOR.rgb, COLOR.a) * step(0.02, LIGHT_ENERGY * LIGHT_COLOR.a);` → arcs only where a bubble light reaches unshadowed (so they hug walls, clipped by floors/ceilings). Additive accumulation is fine.
Profiles' `ring_thickness`: whisper 1.5, normal 2.0, scream 3.0; trail_gap 10/14/22; trail_count 1/2/3.
**Test:** sandbox key `1/2/3` fires tiers; arcs visibly clip at a ceiling; up to 6 overlapping.

## 4. Reveal light texture (`reveal_texture_factory.gd`, not a shader)
Generates once a 512×512 `ImageTexture` (RGBA8): `v = 1` for `d ≤ 0.82`, `v = 1 - smoothstep(0.82, 1.0, d)` beyond (d normalized to radius 256 px), plus a 4% darker 2 px band at `d = 0.80` (subtle dark vignette edge behind the arc). Light `texture_scale = radius / 256`.

## 5. `edge_line.gdshader` — rough white edge glow (on top-surface Line2Ds, second "glow" Line2D)
Main line uses `flat_reveal`. A duplicate wider line (width ×3, α 0.25) uses `edge_line`:
| Uniform | Type | Default |
|---|---|---|
| `tint` | vec4 | `#FFFFFF` |
| `glow_falloff` | float | 2.2 |
| `rim_softness` | float | 0.25 |
**fragment:** `float x = abs(UV.y - 0.5) * 2.0; COLOR = vec4(tint.rgb, tint.a * pow(1.0 - x, glow_falloff));` (Line2D `texture_mode = TILE`, UV.y spans width). **light:** same as flat_reveal. This is the "bloom" on edges (no WorldEnvironment glow needed).
Geometry roughness is in the CPU-generated points (EdgeLineFactory: points every 6 px, perpendicular jitter `noise(x*0.08)*1.6 px + rand(±0.6)`, occasional 1-px notches every 20–60 px).

## 6. `enemy_silhouette.gdshader` — red flat silhouette + alert flicker
| Uniform | Type | Default | Set by |
|---|---|---|---|
| `danger_color` | vec4 | `#E00000` | Palette |
| `alert` | float 0–1 | 0 | enemy Visual from Awareness (≥1 in CHASE) |
| `flash` | float 0–1 | 0 | Visual tween on state change (1→0 over 0.2 s) |
| `hatch` | bool | false | Palette |
| `rim_softness` | float | 0.25 | GameConfig |
**fragment:**
```
vec4 base = texture(TEXTURE, UV) * COLOR;                 // shape alpha
float flick = alert * (0.85 + 0.15 * step(0.5, fract(TIME * 12.0)));
vec3 c = mix(danger_color.rgb, vec3(1.0, 0.35, 0.35), max(flick*0.35, flash));
if (hatch) { float h = step(0.5, fract((FRAGCOORD.x + FRAGCOORD.y) / 6.0)); c = mix(vec3(0), vec3(1), h); /* + outline via alpha edge */ }
COLOR = vec4(c, base.a);
```
**light:** as flat_reveal (enemies visible only in bubbles/glow). Polygons (Polygon2D) supply shape; outline in hatch mode via a sibling `Line2D` loop enabled by Palette.
**Test:** sandbox_enemy: toggle alert with key A — red brightens and flickers at 12 Hz.

## 7. `smudge_blur.gdshader` — sensed-but-not-seen dark-red blob (SenseLayer, unlit)
Applied to a `Sprite2D` with a 64×64 white radial gradient texture, scaled to enemy size ×1.6.
| Uniform | Type | Default | Set by |
|---|---|---|---|
| `smudge_color` | vec4 | `#5A0000` | Palette |
| `opacity` | float | 0.5 | Smudge.gd (tween 0.5→0 over 1.2 s after a noise) |
| `wobble` | float | 0.06 | const |
**fragment:** domain-warped soft blob: `vec2 uv = UV + wobble * vec2(sin(TIME*3.0+UV.y*9.0), cos(TIME*2.3+UV.x*7.0)); float d = length(uv - 0.5)*2.0; float a = (1.0 - smoothstep(0.35, 1.0, d)); COLOR = vec4(smudge_color.rgb, a * opacity);` (Fake blur; no screen sampling → cheap.) Hidden when `PulseRegistry.reveal_at(enemy) > 0.25`.

## 8. `glass_crack.gdshader` — glass floor tiles
| Uniform | Type | Default | Set by |
|---|---|---|---|
| `crack` | float 0–1 | 0 | GlassFloor (0.4 after a Normal wavefront passes = warning, 1 on break) |
| `seed` | float | cell index | GlassFloor |
| `tint` | vec4 | `#3D3D3D` | Palette (near grey) |
**fragment:** Voronoi-ish lines: `vec2 g = UV*4.0 + seed; float e = cellular_edge(g);` (F2−F1 of 9-neighbour hash); `float line = 1.0 - smoothstep(0.0, 0.04 + 0.06*crack, e) * step(0.01, crack); COLOR = vec4(mix(tint.rgb, vec3(1), line), max(tint.a*0.6, line));`. **light:** flat_reveal. On break, the tile is replaced by CPUParticles2D shards (white, 24 particles).

## 9. Lantern sway (no shader, transform) — documented here for completeness
`Lantern` = pivot Node2D + chain `Line2D` + lamp `Polygon2D` (flat_reveal). On wavefront: angular impulse `ω += impulse_by_tier (whisper 0.6, normal 1.8, scream 4.0 rad/s) * sign(dx)`. Damped spring: `α = -k θ - c ω`, `k = 18`, `c = 1.6`. Clink noise if `|ω| > 2.0` (throttled 1.5 s).

## 10. `post_fx.gdshader` — vignette + grain + chromatic aberration (PostFx CanvasLayer 10, full-rect ColorRect)
`uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;`
| Uniform | Type | Default | Set by |
|---|---|---|---|
| `vignette_strength` | float | 0.45 | GameConfig.post |
| `vignette_radius` | float | 0.75 | GameConfig.post |
| `grain_amount` | float | 0.06 | Settings (0 when grain off) |
| `ca_amount` | float | 0.0 | PostFx.gd burst: scream 0.012, detection 0.008 → 0 over 0.4 s |
| `flash` | float | 0.0 | PostFx.gd: 0.35 one frame on detection, decay 0.12 s |
| `bloom_amount` | float | 0.25 | GameConfig.post (cheap 5-tap bright-pass blur) |
| `ca_mono` | bool | true | const — CA rendered as white/grey offset only (keeps palette) |
**fragment:**
```
vec2 uv = SCREEN_UV; vec2 dir = uv - 0.5;
vec3 c = texture(screen_tex, uv).rgb;
if (ca_amount > 0.0) {  // mono CA: offset luminance ghosts, then re-tint by original hue so no new hues appear
  float l1 = luminance(texture(screen_tex, uv + dir*ca_amount).rgb);
  float l2 = luminance(texture(screen_tex, uv - dir*ca_amount).rgb);
  c = max(c, vec3((l1 + l2) * 0.25));
}
vec3 b = 5-tap cross blur at 2.0/screen_px of max(c-0.6,0); c += b * bloom_amount;
float v = smoothstep(vignette_radius, vignette_radius - 0.45, length(dir)*1.2); c *= mix(1.0 - vignette_strength, 1.0, v);
float n = hash(uv * vec2(1280,720) + fract(TIME)*91.0) - 0.5; c += n * grain_amount;
c = mix(c, vec3(1.0), flash);
COLOR = vec4(c, 1.0);
```
Note: CA kept monochrome to respect "no other hues". **Test:** sandbox key `P` triggers burst; Settings grain toggle visibly removes noise.

## 11. `title_glitch.gdshader` — title logo (Label with this material, unlit UI)
| Uniform | Type | Default | Set by |
|---|---|---|---|
| `reveal` | float 0–1 | 0 | TitleLogo tween 0→1 over 1.2 s (sonar wipe) |
| `wipe_center` | vec2 | (0.5, 0.5) | const |
| `glitch` | float | 0.3 | TitleLogo (spikes to 1 for 0.08 s every 3–6 s) |
**fragment:** `float d = distance(UV, wipe_center); float front = reveal*1.2; float vis = 1.0 - smoothstep(front-0.02, front, d); float ring = band(d, front, 0.01); slice offset: UV.x += glitch*0.02*step(0.9, hash(floor(UV.y*24.0)+floor(TIME*20.0)))`; `COLOR.a *= vis; COLOR.rgb = mix(COLOR.rgb, vec3(1), ring);` plus the red accent: second Label ("LOST") uses danger colour.

## 12. Uniform → setter audit table
| Shader.uniform | Script that sets it |
|---|---|
| flat_reveal.tint/max_brightness/rim_softness/hatch | edge_builder.gd, background_builder.gd, Visual scripts, palette_service.gd |
| sonar_air.pulse_count/pulse_data/pulse_style/arc_color/rect_origin | sonar_system.gd |
| edge_line.tint/glow_falloff/rim_softness | edge_line_factory.gd |
| enemy_silhouette.danger_color/alert/flash/hatch/rim_softness | *_visual.gd (via enemy_base), palette_service.gd |
| smudge_blur.smudge_color/opacity | smudge.gd |
| glass_crack.crack/seed/tint | glass_floor.gd |
| post_fx.* | post_fx.gd (reads GameConfig + SaveData settings) |
| title_glitch.reveal/glitch | title_logo.gd |
