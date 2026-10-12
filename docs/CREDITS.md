# SIGNAL LOST — Project Credits & Third-Party Attributions

- **Purpose**: Authoritative attribution log, open-source software license notices, typography credits, and procedural asset documentation.
- **Audience**: General Public, Legal, Engine Contributors, QA Engineers.
- **Status**: Approved.
- **Last Updated**: 2026-10-12.
- **Depends On**: [00_CURRENT_STATE_AUDIT.md](file:///c:/vibe-game/docs/00_CURRENT_STATE_AUDIT.md).

---

## 1. Engine & Core Frameworks

### Godot Engine
- **Version**: Godot Engine 4.7.2-stable (official build `ed1daf0bf`).
- **Copyright**: © 2007-present Juan Linietsky, Ariel Manzur, and the Godot Engine contributors.
- **License**: MIT License.
```
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 2. Typography & Font Licenses

### Rajdhani Font Family
- **Designer**: Indian Type Foundry (ITF).
- **Styles Used**: Rajdhani-Medium, Rajdhani-SemiBold (`res://assets/fonts/`).
- **License**: SIL Open Font License, Version 1.1 (OFL 1.1).
- **Attribution**: Bundled under `res://assets/fonts/OFL.txt`.

---

## 3. Audio & Visual Assets Independence

- **Audio Synthesis**: 100% of sound effects and dynamic multi-layer music are synthesized algorithmically in-engine via `SfxLibrary` and `audio/synth.gd`. Zero external copyrighted audio files are distributed with this software.
- **Visuals & Art**: 100% of character silhouettes, environment geometry, parallax backgrounds, and visual effects are authored programmatically via GLSL Compatibility shaders (`shaders/`) and vector polygon primitives (`Polygon2D`, `Line2D`). Zero external binary bitmap images or proprietary 3D meshes are used.

---

## 4. Development & Production Team

- **Game Design & Creative Direction**: Joshua Mathew / Antigravity AI Pair Programming System.
- **Technical Direction & Architecture**: DeepMind Advanced Agentic Coding Assistant.
- **Automated QA & Tooling**: Playwright MCP, Godot Headless Engine Harness.
