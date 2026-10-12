# SIGNAL LOST — Audio & Acoustic Synthesis Specification (V2)

- **Purpose**: Authoritative audio engineering specification detailing procedural sound synthesis algorithms, sound-to-noise physical coupling, dynamic multi-layer music cross-fading, and bus routing.
- **Audience**: Audio Programmers, Sound Designers, Technical Directors, AI Coding Agents.
- **Status**: Approved.
- **Last Updated**: 2026-10-12.
- **Depends On**: [00_CURRENT_STATE_AUDIT.md](file:///c:/vibe-game/docs/00_CURRENT_STATE_AUDIT.md), [GAME_CONFIG_REFERENCE.md](file:///c:/vibe-game/docs/GAME_CONFIG_REFERENCE.md), [COMBAT_DESIGN.md](file:///c:/vibe-game/docs/COMBAT_DESIGN.md).

---

## 1. Procedural Synthesis Architecture (`audio/synth.gd`)

In accordance with the zero external binary assets mandate, 100% of sound effects are synthesized algorithmically at boot into memory-cached `AudioStreamWAV` buffers via `SfxLibrary` (`audio/sfx_library.gd`):
- **Synthesis Latency Budget**: Entire sound library generates in **$< 350 \text{ ms}$** on engine startup.
- **Sample Format**: 16-bit PCM, 44.1 kHz, Mono (spatialized in 2D via `AudioStreamPlayer2D`).
- **Core Synthesis Primitives**:
  - `Oscillator`: Sine, Triangle, Square, and Sawtooth waveforms with linear envelope generators (ADSR).
  - `Noise Generator`: White noise and pink noise filters with exponential decay for impacts, footsteps, and slashes.
  - `Comb & Low-Pass Filters`: Resonant filters simulating metallic clangs, bronze lanterns, and sword deflects.
  - `Frequency Modulator (FM)`: Twin-operator FM synthesis producing futuristic cyber-blade hums and acoustic drone waves.

---

## 2. Complete Sound Effect Registry & Noise Coupling

Every sound effect maps deterministically to a physical `NoiseEvent` on `NoiseBus`:

| Sound Identifier | Synthesis Recipe | Pitch Variation | Trigger Event | Coupled Noise Radius | Coupled Loudness | Mix Bus |
|---|---|---|---|---|---|---|
| `sfx_footstep` | Short pink noise burst (30ms) + 120Hz sine pop | $\pm 8\%$ | Hero walking on solid floor | `40.0 px` | `0.5` | `SFX` |
| `sfx_hard_landing`| 80Hz sine thud + white noise clap (120ms) | $\pm 4\%$ | Landing with $v_y > 520 \text{ px/s}$ | `96.0 px` | `1.0` | `SFX` |
| `sfx_pulse_whisper`| Soft 440Hz sine chime + gentle low-pass sweep | $\pm 0\%$ | Releasing Whisper pulse | `43.2 px` | `1.0` | `Acoustic` |
| `sfx_pulse_normal` | 220Hz resonant bell chime + expanding sub-rumble| $\pm 0\%$ | Releasing Normal pulse | `200.0 px` | `2.0` | `Acoustic` |
| `sfx_pulse_scream` | Deep 55Hz sub-bass blast + high-frequency crackle| $\pm 0\%$ | Releasing Scream pulse | `728.0 px` | `3.0` | `Acoustic` |
| `sfx_katana_slash` | High-pass filtered noise swoosh (90ms) | $\pm 6\%$ | Katana light strike startup | `180.0 px` | `1.5` | `Combat` |
| `sfx_naginata_thrust`| Mid-range air displacement pop + resonant spear ring| $\pm 5\%$ | Naginata heavy strike | `320.0 px` | `2.8` | `Combat` |
| `sfx_kunai_slice` | Rapid micro-frequency blade tick (40ms) | $\pm 7\%$ | Kunai flurry strike | `90.0 px` | `0.8` | `Combat` |
| `sfx_blade_clash` | Resonant dual-comb filtered metal strike (220ms) | $\pm 5\%$ | Striking enemy guard | `240.0 px` | `2.0` | `Combat` |
| `sfx_parry_deflect`| High 1800Hz pure bell ping + reverse noise whip | $\pm 2\%$ | Successful frame-tight parry | `260.0 px` | `2.2` | `Combat` |
| `sfx_assassination`| Sub-bass snap + muted wet slice (180ms) | $\pm 0\%$ | Stealth rear execution | `60.0 px` | `0.6` | `Combat` |
| `sfx_arrow_whistle`| Descending sinusoidal whistle (520 px/s) | $\pm 4\%$ | Yumi archer arrow in flight | `80.0 px` | `1.0` | `Combat` |
| `sfx_glass_shatter`| Dual-band granular noise crack + multiple pings | $\pm 6\%$ | Glass floor destroyed | `360.0 px` | `3.0` | `SFX` |
| `sfx_lantern_chime`| Harmonic bronze bell chime (decay 800ms) | $\pm 0\%$ | Sonar wavefront hitting lantern | `96.0 px` | `1.0` | `SFX` |
| `sfx_hint_beacon` | Modulated upward twin-sine ping (440Hz -> 880Hz)| $\pm 0\%$ | Pressing `H` emergency beacon | `120.0 px` | `1.2` | `SFX` |

---

## 3. Dynamic Combat Music Layering (`audio/music_layers.gd`)

The soundtrack is an interactive, multi-stem procedural drone and percussion engine that dynamically reacts to stealth tension and combat states:

```
  ┌─────────────────────────────────────────────────────────────────┐
  │ LAYER 1: SUBTERRANEAN VOID (Continuous Ambient)                 │
  │ • Deep 45Hz sub-bass drone + filtered tape hiss. Volume: 0 dB   │
  ├─────────────────────────────────────────────────────────────────┤
  │ LAYER 2: STEALTH TENSION (Investigate / Suspicion State)         │
  │ • Subtle acoustic koto pluck arpeggios + breath flutes.         │
  │ • Fades in over 0.5s when any enemy enters INVESTIGATE (>-6 dB) │
  ├─────────────────────────────────────────────────────────────────┤
  │ LAYER 3: COMBAT TAIKO PERCUSSION (Full Alert / Chase / Boss)     │
  │ • High-tempo (138 BPM) driving taiko drums + metallic clatter.  │
  │ • Fades in over 0.3s when GameState.detected() fires (0 dB)     │
  └─────────────────────────────────────────────────────────────────┘
```

### 3.1 Transition Cross-Fade Logic
1. **Combat Initiation**: When an enemy enters `CHASE` or `ATTACK`, or `GameState.detected()` fires:
   - Layer 3 (Taiko) fades from $-80 \text{ dB}$ to $0 \text{ dB}$ over **0.30 seconds** (exponential curve).
   - Audio bus ducking: Ambient Layer 1 ducks by $-4 \text{ dB}$ to maximize combat impact.
2. **Combat De-Escalation**: When all enemies return to `SEARCH` or `PATROL`:
   - Combat cooldown timer runs for **3.0 seconds**.
   - If no further alert occurs, Layer 3 smoothly fades out over **2.5 seconds** back to $-80 \text{ dB}$.

---

## 4. Audio Bus Layout & Dynamic Mixing

Configured in `default_bus_layout.tres`:

```
Master (Bus 0, Volume: 0 dB)
├── Music (Bus 1, Volume: -2 dB) [Send -> Master]
│   └── Reverb (Small Room, wet 0.15)
├── SFX (Bus 2, Volume: 0 dB) [Send -> Master]
│   └── Limiter (Threshold -0.5 dB, prevent clipping)
├── Combat (Bus 3, Volume: +1.5 dB) [Send -> Master]
│   └── Compressor (Ratio 4:1, Attack 10ms, Release 80ms)
└── AcousticPass (Bus 4, Volume: 0 dB) [Send -> Master]
    └── LowPassFilter (Cutoff 2400Hz, dynamically opens to 18kHz on pulses)
```

- **Dynamic Muffling in Darkness**: When the hero is in pure pitch blackness (no active pulse bubbles), the `AcousticPass` bus engages a low-pass filter (cutoff 1200 Hz), creating an intimate, muffled sensory environment. When a pulse expands, the cutoff opens to 18 kHz, delivering brilliant acoustic clarity.
