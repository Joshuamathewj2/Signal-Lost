# SIGNAL LOST — Animation, Feel & Audio (v1.0)

## 1. Procedural animation principles
No sprite sheets. Every entity's `Visual` scene is a small tree of `Polygon2D`/`Line2D` pieces animated in `_process` by code (sine-based) plus `Tween`s for one-shots. `AnimationPlayer` is used only for the Exit Terminal sequence and the title. All visual timings in `GameConfig.anim`.

## 2. Robot (`player_visual.tscn`) — white `#FFFFFF`, flat
Pieces (pivot at feet centre, px): `Body` Polygon2D rounded box 12×10 at y −14; `Head` 10×7 at y −21; `Eye` 2×2 white circle with its own tiny PointLight2D? **No** — eye is unshaded (CanvasItemMaterial UNSHADED) so it's always visible as the one glowing dot; `Antenna` Line2D 2 points (0,−25)→(0,−31) + tip dot 2 px; `LegL/LegR` Line2D 2-segment (hip, knee, foot) width 2; `ArmL/ArmR` short Line2D.
| Pose | Spec |
|---|---|
| Idle | body bob `y = sin(t*2.2)*0.6`; antenna tip wobble `θ = sin(t*3.1)*4°` |
| Run | legs: hip angle `±35° * sin(phase)`, knee `max(0, sin(phase+π/2))*50°`, phase speed `= |vx| * 0.11 rad/px`; body bob `|sin(phase)|*1.2`; lean 6° toward motion; antenna lags (spring k 60, c 8) |
| Sneak | body scale y 0.7, lowered 4 px, step amplitude ×0.5, antenna folded 30° back |
| Jump | squash on takeoff: scale (1.2, 0.8) → stretch (0.85, 1.2) over 0.08 s → (1,1) at apex |
| Fall | legs tucked 20°, arms up 40°, stretch y 1.08 |
| Land | squash (1.25, 0.75) → (1,1) over 0.12 s, TRANS_BACK; dust specks (6 white particles) on hard landing |
| Charge | antenna tip pulses scale `1 + 0.3*c*sin(t*20)`, body vibrates ±0.5 px when c ≥ 0.85 |
| Pulse release | antenna flash (tip scale 2 → 1 in 0.15 s), recoil body 1 px opposite facing |
| Hurt/Death | 0.08 s hit-stop → pieces replaced by `death_burst.tscn` CPUParticles2D (60 white 1–2 px squares, spread 180°, initial velocity 60–180, gravity 300, lifetime 0.9 s, fade); eye dot lingers 0.3 s then pops |

## 3. Enemies (red `#E00000`, `enemy_silhouette.gdshader`)
| Enemy | Shape (procedural) | Animation |
|---|---|---|
| Listener | 22×14 dome-shell body on two 3-joint legs, tall dish antenna | leg cycle like robot ×0.8; dish rotates toward last noise; on alert: dish spins 360° in 0.3 s |
| Sentry | 18×12 base trapezoid + 16 px barrel rectangle; mounted on balcony | barrel rotates to aim; recoil 3 px on fire; laser tick line during AIM |
| Hunter | low, long 28×10 wedge body, 4 thin legs, two forward "ears" | gallop cycle (legs in pairs, phase speed ×1.6); ears flatten when TRACK; body stretch 1.1 when sprinting |
| Brute | 30×36 blocky torso, big shoulders, short thick legs | heavy step every 0.7 s: body dips 2 px, camera shake 0.03 if near; STUNNED: head shake ±8° at 10 Hz |
Alert "!" / "?" glyph: Label (Rajdhani SemiBold 14, white, unshaded) above head, pop-scale 0→1.3→1 over 0.18 s, hold 0.6 s, fade 0.2 s. Silhouette `flash` uniform 1→0 over 0.2 s at the same time.

## 4. Particles (CPUParticles2D only — Compatibility-safe)
| Effect | Count | Colour | Notes |
|---|---|---|---|
| Death burst | 60 | white | above |
| Hard landing dust | 6 | `#3D3D3D` | lit (flat_reveal material) |
| Glass shatter | 24 per tile | white | gravity 900, lifetime 1.2 s, lit |
| Fragment pickup | 16 | white, unshaded | ring burst r 24 |
| Terminal "SIGNAL RESTORED" | 40 | white, unshaded | upward stream 0.8 s |
| Projectile impact | 8 | `#E00000`, unshaded | |
Max 300 alive particles total (ParticlesFactory refuses beyond, logs in debug).

## 5. Camera (`camera_rig.gd`, Camera2D zoom 2)
- Follow: `position_smoothing_enabled = true`, speed 6; look-ahead 40 px in facing direction (lerp 3/s); vertical deadzone 24 px.
- Limits = map bounds.
- **Shake:** trauma model. `trauma += amount` (clamped 1); offset = `max_offset * trauma² * noise(t*25)`; `trauma -= 1.5/s`. `max_offset` = 10 px. Tier adds: whisper 0, normal 0.2, scream 0.9, death 0.6, glass 0.5, brute step 0.03. Multiplied by Settings "screen shake" (0–1).
- **Zoom punch:** scream: zoom 2.0 → 2.12 in 0.15 s (TRANS_QUAD OUT) → back in 0.5 s (TRANS_SINE). Detection: 2.0 → 2.06 → 2.0 in 0.3 s.
- **Hit-stop:** `Engine.time_scale = 0.05` for 0.08 s real time (use `create_timer(…, true, false, true)` ignoring time scale).

## 6. Audio
### 6.1 Buses (`default_bus_layout.tres`)
```
Master (Limiter: ceiling −1 dB)
├─ Music      (−6 dB)  LowPassFilter (cutoff 18000; drops to 800 during death)
├─ SFX        (0 dB)
│   └─ Pulse  (Reverb: room_size driven by pulse tier, damping 0.5, wet 0.25)
├─ Ambience   (−10 dB) Reverb (room 0.8, wet 0.35)
└─ UI         (−4 dB)
```
`AudioManager.set_pulse_reverb(tier)`: whisper room 0.2 wet 0.1; normal 0.55 wet 0.25; scream 0.95 wet 0.45 (tween 0.1 s).

### 6.2 Procedural synthesis (`audio/synth.gd`)
All SFX are rendered **once at boot** into `AudioStreamWAV` (16-bit mono 44.1 kHz PCM, `PackedByteArray`) by small DSP functions, then played through a pool of 12 `AudioStreamPlayer` (+ 8 `AudioStreamPlayer2D` for positional). *Why:* `AudioStreamGenerator` per-frame pushing is fragile under load; pre-rendered WAVs are deterministic and cheap.
| SFX id | Recipe | Length |
|---|---|---|
| `ping_whisper` | sine 2400 Hz, exp decay τ 0.05 s, + 2nd harmonic 0.2 | 0.15 s |
| `ping_normal` | sine 1500 Hz → 1350 Hz glide, τ 0.18 s, + echo tap at 0.12 s (×0.35) | 0.6 s |
| `ping_scream` | sine 900 → 600 Hz glide + saw at 450 Hz ×0.15 low-passed, τ 0.5 s, 3 echo taps (0.15/0.3/0.45 s, ×0.4^k) | 1.6 s |
| `charge_loop` | sine 300 Hz + tremolo 8 Hz, pitch set by `pitch_scale = 1 + c` | 1.0 s loop |
| `pulse_fail` | short noise click 8 ms, band ~3 kHz | 0.03 s |
| `step_soft` | filtered noise burst 25 ms | 0.03 s |
| `land` | low thump: sine 80 Hz τ 0.08 + noise | 0.2 s |
| `listener_alert` | two-tone 700→1000 Hz square ×0.3 | 0.25 s |
| `hunter_ping` | double 1800 Hz blips 60 ms apart | 0.2 s |
| `sentry_whine` | saw 200→900 Hz rising | 0.6 s |
| `sentry_fire` | noise burst + 120 Hz thump | 0.25 s |
| `brute_step` | sine 45 Hz τ 0.15 + noise, positional | 0.3 s |
| `glass_break` | 12 random high sine pings 2–6 kHz over 0.4 s + noise | 0.8 s |
| `lantern_clink` | 3.2 kHz + 4.7 kHz inharmonic, τ 0.3 | 0.5 s |
| `plate_click`, `door_open` (filtered noise sweep 0.6 s), `key_pickup`, `fragment_pickup` (arpeggio 1200/1600/2000), `terminal_restore` (rising 4-note sine arpeggio + shimmer) | | |
| UI: `ui_move` (1 kHz 20 ms tick), `ui_select` (1.4 kHz 40 ms), `ui_back` (700 Hz 40 ms) | | |
Pitch randomization ±4% on steps and clinks.

### 6.3 Ambience & music layers (`audio/music_layers.gd`)
4 looping layers rendered by synth at boot (8 s loops, 44.1 kHz) and played simultaneously, volumes driven by `GameState.alert_level` (max awareness of all enemies, smoothed 1.5 s):
| Layer | Content | Volume curve |
|---|---|---|
| L0 drone | 55 Hz + 82.5 Hz sines, slow 0.1 Hz amplitude LFO, pink noise −30 dB | always −8 dB |
| L1 pulse | filtered noise heartbeat at 60 BPM | alert ≥ 0.2 → −12 dB |
| L2 tension | detuned saw pad 110/116 Hz, low-passed 600 Hz | alert ≥ 0.5 → −10 dB |
| L3 chase | 120 BPM kick (sine 60 Hz) + hat (noise 8 ms) | any enemy in CHASE → −6 dB |
Fades 0.8 s. On death: Music low-pass to 800 Hz for 0.6 s.

### 6.4 Positional rules
Enemy and object sounds use `AudioStreamPlayer2D` with `max_distance` = event radius ×1.2 and attenuation 1.5, so what you hear matches what enemies hear.
