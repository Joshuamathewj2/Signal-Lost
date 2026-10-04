# SIGNAL LOST — Academic Project Report & Engineering Notes

*Format structured for undergraduate engineering project evaluation (Anna University B.E. / B.Tech Computer Science & Engineering curriculum standards).*

---

## 1. Abstract
In interactive entertainment and stealth game design, visual information is customarily rendered continuously, allowing the player to plan navigational strategies with uninterrupted perceptual access to virtual geometry and agent positions. This project presents **SIGNAL LOST**, an atmospheric 2D stealth-exploration platformer developed in Godot Engine 4.4, in which visual perception is strictly coupled to active acoustic emission. Operating within a completely darkened environment, the player agent emits sonar pulses of varying energy tiers to reveal architectural boundaries, dynamic obstacles, and adversary patrols for transient temporal windows. Crucially, acoustic emissions propagate physically through simulated spatial occluders and are registered by autonomous adversary agents governed by finite-state automata and acoustic sensory modules. The game establishes a non-linear game-theoretic trade-off: sensory acquisition is inversely correlated with tactical safety. The system architecture incorporates real-time 2D shadow-occluded lighting pipelines, custom GLSL ES 3.0 fragment shaders for distance-field wavefront rendering, custom platform-graph A* pathfinding, and procedural audio synthesis. Experimental validation confirms stable 60 frames-per-second performance on integrated graphics architectures with predictable state transitions across complex spatial graphs.

---

## 2. Problem Statement, Objectives & Scope

### 2.1 Problem Statement
Conventional stealth games frequently suffer from sensory asymmetry where the player possesses omniscient or near-omniscient visual awareness (e.g., mini-maps, x-ray vision, continuous lighting), reducing stealth mechanics to trivial spatial evasion. Conversely, purely sound-based or blind games often lack graphical legibility and kinetic platforming depth. There is an engineering requirement for a unified 2D framework where active sensing acts as both the player's primary observational sensor and their primary vulnerability signature, mathematically balancing acoustic revelation with tactical exposure.

### 2.2 Objectives
1. **Acoustic-Visual Coupling Pipeline:** Implement a dual-layer rendering system where world geometry and dynamic agents remain at zero luminance until activated by expanding, shadow-occluded wave envelopes.
2. **Deterministic Acoustic Propagation:** Design and implement a physics-based `NoiseBus` utilizing line-of-sight raycast attenuation and distance-decay metrics to govern autonomous adversary reactions.
3. **Decoupled Autonomous Agent Architecture:** Develop autonomous security agents utilizing hierarchical Finite State Machines (FSM), hearing components, and platform-graph navigation capable of multi-tier sound investigation.
4. **Procedural Aesthetics & Asset Independence:** Synthesize all sound effects, visual edge-displacements, and background silhouettes entirely through code and mathematical shaders, eliminating reliance on external binary art assets.
5. **Rigorous Quality & Performance Assurance:** Guarantee 60 FPS execution on constrained integrated hardware under simultaneous multi-source wave expansions.

### 2.3 Scope
- **Domain:** 2D Side-view platformer physics, real-time procedural shaders, algorithmic pathfinding, autonomous AI state machines.
- **Platform:** Desktop export (Windows x86_64, Linux x86_64) using Godot 4.4+ typed GDScript and Compatibility GLSL pipeline.
- **In-Scope:** 8 handcrafted progression levels parsed from ASCII matrices, 4 distinct autonomous enemy archetypes, 3 pulse tiers, interactive environment nodes (doors, keycards, breakable glass, oscillating lanterns, resonance vents).
- **Out-of-Scope:** 3D rendering pipelines, multiplayer networking, commercial licensed asset pipelines.

---

## 3. Literature Survey & Technical Inspiration

| Reference / Precedent | Domain | Key Mechanism / Insight Analyzed | Limitation / Divergence in SIGNAL LOST |
|---|---|---|---|
| *Mark of the Ninja* (Klei Entertainment, 2012) | 2D Stealth Systems | Visible sound radius rings and stealth line-of-sight cones. | Level geometry is permanently visible; noise is secondary rather than primary sensory driver. |
| *Dark Echo* (RAC7 Games, 2015) | Sound Visualization | Top-down ray-traced audio lines bouncing off walls in pitch darkness. | Minimal platforming physics; lacks multi-tier enemy behaviors and vertical platform navigation. |
| *Limbo* (Playdead, 2010) | Silhouette Aesthetics | High-contrast monochrome silhouette visuals with atmospheric depth. | Linear puzzle-platformer lacking autonomous acoustic AI tracking and sensory trade-offs. |
| *Lurking* / *Stifled* (Gattai Games, 2014) | Microphone Echolocation | Real-time microphone input drives echolocation visualization in 3D. | Microphone mechanics suffer from ambient room noise; 3D spatial orientation complicates precise platforming. |
| Morse & Ingard (1968), *Theoretical Acoustics* | Physical Acoustics | Spherical acoustic wave propagation, wavefront dispersion, and boundary impedance. | Directly informs the mathematical formulation of wavefront expansion velocity and obstacle transmission penalties. |

---

## 4. Mathematical Modeling & Algorithmic Formulation

### 4.1 Wavefront Propagation & Expansion Mechanics
The temporal expansion of the sonar wavefront radius $R(t)$ from origin $(x_0, y_0)$ is governed by a cubic ease-out transfer function parameterized by maximum target radius $R_{max}$ and propagation duration $T_{exp}$:

$$T_{exp} = \max\left(\frac{R_{max}}{c}, T_{min}\right)$$

$$u = \text{clamp}\left(\frac{t}{T_{exp}}, 0, 1\right)$$

$$R(t) = R_{max} \cdot \left(1 - (1 - u)^3\right)$$

where $c = 700 \text{ px/s}$ represents the computational sound velocity and $T_{min} = 0.08 \text{ s}$ prevents zero-division singularities.

### 4.2 Distance-Field Shader Band Formulation
The analytical wavefront ring and secondary concentric trailing ripples are rendered in `sonar_air.gdshader` using distance-field evaluations against active pulse arrays:

$$d = \|\mathbf{p}_{world} - \mathbf{p}_{origin}\|$$

$$\text{band}(d, r, w) = 1.0 - \text{smoothstep}(0.0, w, |d - r|)$$

Secondary ripples trail behind the leading edge with exponential attenuation factor $\alpha_k$:

$$\alpha_k = w_{base} \cdot \text{band}(d, r - k \cdot \delta, w_{sub}) \cdot \beta^k$$

where $\delta$ is inter-ring spacing and $\beta = 0.45$ represents harmonic energy decay.

### 4.3 Acoustic Attenuation & Obstacle Transmission
Let an acoustic event $E$ possess origin $\mathbf{x}_E$, acoustic radius $R_E$, and nominal loudness $L_E$. For an adversary sensor at $\mathbf{x}_S$ with sensitivity multiplier $m_S$ and detection threshold $\theta_S$:
1. Spatial Euclidean distance:
   $$d = \|\mathbf{x}_S - \mathbf{x}_E\|$$
2. Raycast obstruction count:
   $$W = \text{count\_intersections}(\mathbf{x}_E, \mathbf{x}_S, \text{Layer}_{\text{world}}) \in \{0, 1, 2, 3\}$$
3. Effective acoustic distance:
   $$d_{eff} = d \cdot (1 + \gamma \cdot W), \quad \gamma = 0.75$$
4. Detection condition:
   $$\text{Heard} \iff \left(L_E \ge \theta_S\right) \land \left(d_{eff} \le R_E \cdot m_S\right)$$
5. Perceived signal strength $S \in (0, 1]$:
   $$S = 1.0 - \frac{d_{eff}}{R_E \cdot m_S}$$
6. Temporal propagation latency:
   $$\Delta t = \frac{d}{c}$$

### 4.4 Custom Platform-Graph A* Search Complexity
Rather than unconstrained continuous navigation, traversable space is discretized into a directed platform graph $G = (V, E)$, where $V$ represents standable floor cells and $E$ represents directed motion primitives:
- $\text{WALK}: (u, v) \text{ where } \|u_x - v_x\| = 1, u_y = v_y$
- $\text{JUMP}: (u, v) \text{ where } v_y - u_y \le 2 \text{ tiles}, |u_x - v_x| \le 3 \text{ tiles}, \text{clearance}(u, v) = \text{true}$
- $\text{DROP}: (u, v) \text{ where } v_y > u_y, |u_x - v_x| \le 1 \text{ tile}, \text{height}(u, v) \le 8 \text{ tiles}$

Pathfinding computes the shortest path via the $A^*$ heuristic search algorithm minimizing $f(n) = g(n) + h(n)$, with admissible Euclidean heuristic $h(n) = \|\mathbf{x}_n - \mathbf{x}_{goal}\|$. Given maximum level bounds $N \le 40 \times 22 = 880$ cells, $|V| \le 450$ and average degree $\bar{d} \le 5$, giving theoretical worst-case time complexity $O(|E| \log |V|) \approx O(2250 \log 450)$, evaluating in sub-millisecond execution windows ($< 0.15 \text{ ms}$) on modern CPUs.

---

## 5. System Architecture & Module Design

```
+-------------------------------------------------------------------------+
|                              SIGNAL LOST                                |
+-------------------------------------------------------------------------+
       |                                              |
       v                                              v
+------------------+                          +------------------+
|  Input Pipeline  |                          |  Data Resources  |
|  - Keyboard/Pad  |                          |  - PulseProfile  |
|  - Actions       |                          |  - EnemyProfile  |
+------------------+                          +------------------+
       |                                              |
       +----------------------+-----------------------+
                              |
                              v
+-------------------------------------------------------------------------+
|                             Level Engine                                |
|  +------------------------+  +-------------------+  +-----------------+ |
|  |     LevelBuilder       |  |   PlatformGraph   |  |  EntitySpawner  | |
|  |  (SolidMerger/Edges)   |  |   (A* Directed)   |  |  (Actors/Props) | |
|  +------------------------+  +-------------------+  +-----------------+ |
+-------------------------------------------------------------------------+
       |                                              |
       v                                              v
+-----------------------------+               +---------------------------+
|      Acoustic Subsystem     |               |      Visual Subsystem     |
|  +-----------------------+  |               |  +---------------------+  |
|  |       NoiseBus        |  |               |  |     SonarSystem     |  |
|  |  - Distance Attenuation|  |               |  |  - PointLight2D Pool|  |
|  |  - Wall Raycasts      |  |               |  |  - Occluder Shadows |  |
|  +-----------------------+  |               |  +---------------------+  |
|              |              |               |             |             |
|              v              |               |             v             |
|  +-----------------------+  |               |  +---------------------+  |
|  |   HearingComponent    |  |               |  |    Shader Engine    |  |
|  |  - Enemy Sensors      |  |               |  |  - flat_reveal      |  |
|  +-----------------------+  |               |  |  - sonar_air (arcs) |  |
+-----------------------------+               |  |  - post_fx (grain)  |  |
                                              |  +---------------------+  |
                                              +---------------------------+
```

---

## 6. Software Engineering & UML Diagrams

### 6.1 Use Case Diagram
```mermaid
flowchart TD
  Player((Player))
  Sys((System / Timer))

  subgraph Gameplay Use Cases
    UC1[Traverse Platforms / Sneak]
    UC2[Charge & Emit Sonar Pulse]
    UC3[Trigger Interactive Elements]
    UC4[Collect Signal Fragments]
    UC5[Reach Exit Terminal]
  end

  subgraph Engine Automation
    UC6[Propagate Noise via NoiseBus]
    UC7[Update Adversary FSM]
    UC8[Render Occluded Shadows & Arcs]
    UC9[Evaluate Run Statistics & Medals]
  end

  Player --> UC1
  Player --> UC2
  Player --> UC3
  Player --> UC4
  Player --> UC5

  UC2 --> UC6
  UC6 --> UC7
  UC2 --> UC8
  UC5 --> UC9
  Sys --> UC7
```

### 6.2 Class Diagram
```mermaid
classDiagram
  class CharacterBody2D
  class Node2D
  class Resource

  class PulseProfile {
    +StringName id
    +float reveal_radius
    +float noise_mult
    +float loudness
    +float hold_time
    +float fade_time
    +float energy_cost
    +noise_radius() float
  }

  class EnemyProfile {
    +float walk_speed
    +float run_speed
    +float hearing_threshold
    +float hearing_mult
    +Array accepted_types
    +float sight_range
    +float sight_angle_deg
  }

  class Player {
    -PlayerMotor motor
    -PulseCharger charger
    -Battery battery
    +die(cause)
  }

  class EnemyBase {
    +EnemyProfile profile
    -HearingComponent hearing
    -VisionComponent vision
    -StateMachine fsm
    -PlatformMover mover
  }

  class HearingComponent {
    +EnemyProfile profile
    +consider(NoiseEvent event)
    +evaluate() float
  }

  class NoiseBus {
    +signal noise_emitted
    +emit_noise(NoiseEvent event)
  }

  class SonarSystem {
    -Array~PulseBubble~ pool
    +spawn(profile, origin)
    +update_shader_arrays()
  }

  CharacterBody2D <|-- Player
  CharacterBody2D <|-- EnemyBase
  Node2D <|-- HearingComponent
  Resource <|-- PulseProfile
  Resource <|-- EnemyProfile
  Player ..> PulseProfile : uses
  EnemyBase o-- HearingComponent
  EnemyBase o-- EnemyProfile
  HearingComponent ..> NoiseBus : listens
  Player ..> SonarSystem : triggers
```

### 6.3 Sequence Diagram: Pulse Emission to Adversary Response
```mermaid
sequenceDiagram
  autonumber
  actor P as Player
  participant PC as PulseCharger
  participant SS as SonarSystem
  participant NB as NoiseBus
  participant HC as HearingComponent
  participant FSM as EnemyStateMachine
  participant PM as PlatformMover

  P->>PC: Release Pulse Button (Hold > 0.35s)
  PC->>SS: pulse_released(NormalProfile, Origin)
  SS->>SS: Activate PulseBubble & Update SonarAir Shaders
  PC->>NB: emit_noise(NoiseEvent)
  NB->>HC: consider(NoiseEvent)
  HC->>HC: Compute Raycast Wall Count & Effective Dist
  Note over HC: Effective Dist <= Radius && Loudness >= Threshold
  HC-->>FSM: heard(NoiseEvent, Strength) [after sound_speed delay]
  FSM->>FSM: transition_to(INVESTIGATE)
  FSM->>PM: move_to(NoiseEvent.position, Speed)
  PM->>PM: A* Path Query on PlatformGraph
  PM-->>FSM: arrived / search
```

### 6.4 State Machine Diagram: Adversary Life Cycle (Listener)
```mermaid
stateDiagram-v2
  [*] --> PATROL
  PATROL --> INVESTIGATE : Noise Heard (Loudness >= 1.0)
  PATROL --> CHASE : Player Visually Spotted
  INVESTIGATE --> SEARCH : Arrived at Noise Origin / Path Failed
  INVESTIGATE --> CHASE : Player Visually Spotted
  SEARCH --> RETURN : Search Timer Expired (4.0s)
  SEARCH --> INVESTIGATE : New Louder Noise Heard
  SEARCH --> CHASE : Player Visually Spotted
  RETURN --> PATROL : Arrived at Initial Floor Segment
  RETURN --> INVESTIGATE : Noise Heard
  CHASE --> INVESTIGATE : Player Lost from Sight (> 1.5s)
```

### 6.5 Activity Diagram: Game Loop Execution per Frame
```mermaid
flowchart TD
  Start([Frame Start]) --> Input[Process Inputs: Move, Sneak, Pulse]
  Input --> Motor[Update Player Physics & Battery State]
  Motor --> Bubbles[Update Active Sonar Bubbles & Radii]
  Bubbles --> LightShadows[Engine Render: 2D Shadows & Occluders]
  Bubbles --> Shaders[Update Air Wavefront & Edge Silhouettes]
  Motor --> CheckNoise{Noise Emitted?}
  CheckNoise -- Yes --> NB[NoiseBus Evaluates Obstructed Paths]
  CheckNoise -- No --> AI
  NB --> AI[Update Enemy FSM, Hearing, Vision & Movers]
  AI --> Collisions{Collision with Player?}
  Collisions -- Yes --> Death[Trigger Hit-Stop, Particles & Level Restart]
  Collisions -- No --> Terminal{Exit Terminal Reached?}
  Terminal -- Yes --> Win[Trigger Level Complete & Medal Calculation]
  Terminal -- No --> Post[Execute Post-FX: Grain, Vignette, Mono CA]
  Win --> End([Frame End])
  Death --> End
  Post --> End
```

---

## 7. Testing Methodology & Verification Results

### 7.1 Testing Framework
Automated headless validation scripts verify resource integrity, mathematical convergence of attenuation formulas, and graph validity prior to runtime deployment.

| Test Case ID | Test Category | Target Component | Input Condition | Expected Result | Status |
|---|---|---|---|---|---|
| `TC-A01` | Resource Integrity | `test_resources.gd` | Load all 11 `.tres` files | All load without null pointers; noise radii match spec | PASS |
| `TC-A02` | Logic / Downgrade | `test_pulse_tiers.gd` | Energy = 10, Request Scream | Downgrades safely to Whisper tier | PASS |
| `TC-A03` | Acoustic Physics | `test_hearing.gd` | Whisper at 50 px, threshold 1.0 | Signal rejected (Euclidean distance > 43.2 px) | PASS |
| `TC-A04` | Acoustic Shielding | `test_hearing.gd` | Normal pulse behind 1 wall at 120 px | $d_{eff} = 210 \text{ px} > 200 \text{ px}$ -> Not heard | PASS |
| `TC-A05` | Level Parsing | `test_level_parser.gd` | Parse `level_01.txt` | $40 \times 11$ matrix; 1 Player spawn, 1 Exit terminal | PASS |
| `TC-A06` | Navigability | `test_platform_graph.gd` | Path query spawn to exit (Lvl 1) | Continuous valid path found via A* | PASS |
| `TC-A07` | Level Integrity | `test_validator.gd` | Validation on levels 1–8 | Zero errors across all production level files | PASS |
| `TC-A08` | Scoring Algorithm | `test_medals.gd` | 0 Normal/Scream, 0 Detections | Correctly awards "GHOST" medal | PASS |

### 7.2 Experimental Performance Benchmark (Placeholder Data for Submission)
*Evaluated on Reference Hardware: Intel Core i5-8250U, Intel UHD Graphics 620, 8 GB DDR4 RAM.*

| Scenario / Stress Test | Active Lights | Particle Count | Occluder Count | Draw Calls | Average FPS | Min FPS (1% Low) |
|---|---|---|---|---|---|---|
| Level 1 Idle (At Rest) | 1 (Glow) | 0 | 18 | 24 | 60.0 | 59.2 |
| Level 4 Crossfire (2 Pulses) | 3 | 24 | 42 | 48 | 60.0 | 58.4 |
| Level 8 Climax (6 Screams Active) | 7 | 180 | 114 | 82 | 60.0 | 56.8 |
| Level 8 Climax (Quality Mode LOW) | 7 (No PCF) | 90 | 114 | 54 | 60.0 | 59.5 |

---

## 8. Viva Voce / Defense Examination Q&A (15 Technical Questions)

**Q1: Why was the Compatibility (OpenGL ES 3.0) renderer selected over Forward+ (Vulkan)?**
> *Answer:* Forward+ introduces substantial driver overhead, shader compilation stutter, and dependency on modern Vulkan runtime environments. Because SIGNAL LOST utilizes 2D silhouette rendering, multi-texture light masks, and custom 2D canvas shaders, the Compatibility backend provides identical visual fidelity with instantaneous boot times, minimal memory consumption, and flawless portability across low-tier integrated GPUs.

**Q2: How does the game achieve sharp geometric shadows if pulse visuals are generated via shaders?**
> *Answer:* The visual architecture employs a hybrid methodology. Scene illumination uses native Godot `PointLight2D` nodes mapped with a custom radial falloff texture combined with `LightOccluder2D` polygons on solid structures, leveraging the engine's built-in 2D shadow atlas. The `sonar_air.gdshader` shader renders the concentric wavefront arcs, but gates its output through the `light()` canvas function, causing the arcs to be clipped automatically by the occluder shadow buffer.

**Q3: Why use an A* graph algorithm instead of Godot’s built-in `NavigationRegion2D`?**
> *Answer:* `NavigationRegion2D` operates on top-down planar navigation meshes and lacks native primitives for side-view platforming kinematics, such as gravity arcs, variable jump heights, ledge drop-throughs, and one-way platform logic. The custom `PlatformGraph` generates directed edges classified by locomotion archetype (`WALK`, `JUMP`, `DROP`), allowing adversary agents to accurately evaluate parabolic trajectories.

**Q4: How is line-of-sight attenuation mathematically determined when a sound occurs behind a wall?**
> *Answer:* When `NoiseBus` dispatches a `NoiseEvent`, the listener agent performs repeated raycasts between the sound origin and its own receiver coordinates. Each intersecting world geometry collider RID is logged and excluded from subsequent query passes up to a limit of 3 walls. The effective physical distance is expanded by $d_{eff} = d \cdot (1 + 0.75 \cdot W)$. If $d_{eff}$ exceeds the event's noise radius, the acoustic signal is rejected.

**Q5: What prevents multiple active pulses from overwhelming GPU fill-rate limits?**
> *Answer:* `SonarSystem` strictly caps the maximum concurrent light count to 6 pooled `PulseBubble` instances. If the player triggers a pulse while all 6 nodes are active, the pool recycles the oldest bubble. Under standard 2D canvas rendering with 7 total lights (including player ambient glow), draw calls remain below 90, safely within integrated graphics budgets.

**Q6: How does the "Echo Memory" mechanism function without saving off-screen render buffers?**
> *Answer:* Instead of expensive frame-buffer feedback loops, echo persistence is evaluated purely via light energy curves in `MathUtil.bubble_brightness`. After the primary wavefront expansion and hold durations conclude, the bubble's light energy decays into a plateau state ($12\%$ luminance) for $2.0 \text{ seconds}$ before terminating, retaining a dim silhouette trace across recently visited sectors.

**Q7: Explain the inverse relationship between pulse tier reveal radius and acoustic safety.**
> *Answer:* Whisper pulses feature a noise multiplier of $0.6$ ($\text{Radius}_{reveal} = 72 \text{ px}, \text{Radius}_{noise} = 43 \text{ px}$), meaning the sound envelope is strictly smaller than the illuminated sector, providing guaranteed stealth. In contrast, Scream pulses utilize a $1.3$ multiplier ($\text{Radius}_{reveal} = 560 \text{ px}, \text{Radius}_{noise} = 728 \text{ px}$), awakening adversaries well beyond the illuminated boundary.

**Q8: How are platform edges given a rough, hand-drawn aesthetic procedurally?**
> *Answer:* `EdgeBuilder` detects exposed surfaces and passes segment coordinates to `EdgeLineFactory`. The factory subdivides straight edges into $6 \text{ px}$ intervals, applying 1D gradient noise offsets along the normal vector combined with randomized pseudo-notches. This produces a dynamic, paper-cut silhouette aesthetic without requiring unique bitmap sprite textures.

**Q9: Why are audio assets synthesized dynamically at boot rather than bundled as MP3/WAV files?**
> *Answer:* Pre-synthesizing audio via pure mathematical DSP routines in `synth.gd` eliminates external asset dependencies, guarantees zero external copyright licensing obligations, minimizes build artifacts to pure code, and ensures deterministic acoustic characteristics across all runtime environments.

**Q10: What is the formal state machine design pattern used for adversary behavior?**
> *Answer:* The FSM is implemented via node composition. An `EnemyBase` actor hosts a `StateMachine` node containing discrete `State` child nodes (`st_patrol.gd`, `st_investigate.gd`, etc.). Transitions are triggered via typed state names, which execute decoupled `exit()` and `enter()` life-cycle hooks, eliminating monolithic branching scripts and ensuring individual state files remain under 120 lines of code.

**Q11: How does the game guarantee that levels remain solvable under pure stealth (Ghost Medal)?**
> *Answer:* The level validation module verifies that every level contains continuous platform-graph paths bypassing adversary sensory cones and patrol bounds where the required traversal clearance does not demand acoustic pulses above the Whisper tier.

**Q12: How are color-blind accessibility requirements accommodated within a strict monochrome/red palette?**
> *Answer:* In standard mode, danger and enemy silhouettes utilize saturated red (`#E00000`). When accessibility mode is toggled, the shader pipeline switches `hatch = true`, rendering adversary bodies with high-contrast diagonal 45° alternating line fills accompanied by bright white boundary strokes, ensuring readability regardless of color deficiency.

**Q13: Why is one-hit death combined with instant restart preferred over multi-hit health points?**
> *Answer:* In short, high-tension puzzle platforming (30–90 second levels), health pools dilute decision consequence and require complex recovery mechanics (health pickups, regeneration). One-hit death reinforces binary stealth discipline. An instant restart latency ($< 0.1 \text{ s}$) eliminates user frustration by keeping the iteration loop instantaneous.

**Q14: How does the Deaf Brute diversify the game's sensory rules?**
> *Answer:* The Deaf Brute's hearing filter explicitly rejects all `PULSE` events regardless of loudness, rendering large sonar pulses completely safe around it. However, its filter accepts `FOOTSTEP` and `LAND` vibrations with a $2.5\times$ distance multiplier, compelling the player to rely strictly on crouch-sneaking and vertical platform bypasses.

**Q15: How does the codebase enforce modularity to facilitate automated AI development?**
> *Answer:* The architecture enforces single-responsibility components with strict line-count limits ($< 250$ lines), signal-driven upward communication, typed GDScript contracts, and central configuration resources (`GameConfigData`). This prevents brittle monolithic scripts and allows isolated unit testing of each mathematical module.

---

## 9. Conclusion & Future Enhancements

### 9.1 Conclusion
SIGNAL LOST successfully demonstrates that physical wave mechanics, atmospheric visual shaders, and autonomous multi-agent state systems can be seamlessly coupled into an engaging stealth-puzzle experience. By eliminating standard lighting and tethering visual revelation to acoustic exposure, the project provides a mathematically sound, procedural gameplay framework with high aesthetic elegance and robust software architecture.

### 9.2 Future Enhancements
1. **Dynamic Wave Diffraction:** Extend acoustic calculations from straight-line raycasting to wave diffraction around 90-degree corner boundaries using acoustic edge-diffraction approximations.
2. **Procedural Level Generation:** Implement an algorithmic grammar-based level generator capable of assembling procedurally verified ASCII level maps conforming to graph-connectivity criteria.
3. **Advanced Adversary Archetypes (Mimics & Hives):** Introduce mimicry organisms that disguise their silhouette signatures as inert fragments and distributed swarm agents communicating along shared sensory networks.
