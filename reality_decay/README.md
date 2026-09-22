# REALITY DECAY

**A retro-futuristic puzzle + narrative game built in Godot 4.x**

---

## Overview

You are the lone operator of an abandoned deep-space station orbiting a dying alien
city. Reality is crumbling in real-time. You have limited power and must choose which
2 of 4 alien city districts to save before total collapse.

---

## Project Structure

```
reality_decay/
├── project.godot              ← Godot 4 project config + input map + autoloads
├── icon.svg
├── scenes/
│   └── main.tscn              ← Master scene (attaches console_ui.gd)
├── scripts/
│   ├── game_manager.gd        ← State machine: STARTUP → MONITORING → DECISION → ENDING
│   ├── district_manager.gd    ← 4 districts, stability, decay, lock system
│   ├── decay_system.gd        ← Glitch level mapping helpers (static functions)
│   ├── input_handler.gd       ← Dial drag + button click + keyboard shortcuts
│   ├── ui_manager.gd          ← HUD labels, power bar, glitch overlays, waveform
│   ├── audio_manager.gd       ← SFX pool + music playback
│   └── console_ui.gd          ← Procedural UI construction + wiring
└── assets/
    ├── sprites/               ← 16-bit pixel art (place assets here)
    ├── audio/                 ← .wav / .ogg files (see audio_manager.gd for names)
    └── fonts/                 ← Pixel fonts (.ttf / .fnt)
```

---

## Autoloads (Singletons)

| Singleton        | File                          | Role                                   |
|------------------|-------------------------------|----------------------------------------|
| `GameManager`    | `scripts/game_manager.gd`     | State machine, power, actions          |
| `DistrictManager`| `scripts/district_manager.gd` | District stability + decay loop        |
| `AudioManager`   | `scripts/audio_manager.gd`    | SFX pool + music playback              |
| `UIManager`      | `scripts/ui_manager.gd`       | HUD updates + glitch effects           |
| `InputHandler`   | `scripts/input_handler.gd`    | Mouse/keyboard input routing           |

---

## Gameplay Controls

| Action              | Control                                |
|---------------------|----------------------------------------|
| Stabilize district  | Click + drag dial LEFT or RIGHT        |
| Save district       | Click **SAVE DISTRICT** (blue button)  |
| Emergency halt      | Click **EMERGENCY HALT** (red button)  |
| Pause game          | `Space`                                |
| Restart             | `R`                                    |
| Mute audio          | `M`                                    |
| Toggle HUD          | `G`                                    |

---

## Game Flow

```
STARTUP (5s)
    → CRT boot, initializing text
MONITORING (up to ~5 min)
    → Manage 4 districts; use dials, blue/red buttons
    → Decay accelerates every 30 s
    → Power hits 0 → forced collapse
DECISION (2s per save)
    → Visual lock confirmation per saved district
ENDING
    → Ending A / B / C based on saves + power
    → Score displayed (max 160)
```

---

## Difficulty Settings

| Level  | Starting Power | Decay Rate (% / s) |
|--------|----------------|--------------------|
| Easy   | 120            | 0.8                |
| Normal | 100            | 1.0                |
| Hard   | 80             | 1.3                |

---

## Endings

| Ending | Condition                     | Text                                  |
|--------|-------------------------------|---------------------------------------|
| **A**  | 2 districts saved             | TWO REALITIES PRESERVED               |
| **B**  | 1 district saved              | ONE REALITY PRESERVED, ONE LOST       |
| **C**  | 0 saved / power depleted      | REALITY FULLY DECAYED                 |

---

## Audio Assets Required

Place files in `assets/audio/`. See `audio_manager.gd` for the full map.

**SFX**
- `dial_click.wav`
- `blue_button.wav`
- `red_button.wav`
- `low_power_warning.wav`
- `decision_beep.wav`
- `startup_init.wav`
- `collapse.wav`

**Music (looping .ogg)**
- `ambient_loop.ogg`
- `ending_hopeful.ogg`
- `ending_melancholic.ogg`
- `ending_catastrophic.ogg`

---

## Pixel Art Assets Required

Place in `assets/sprites/`. See design brief Section 7 for dimensions.

- Console frame (isometric)
- 4× analog dial sprites (64×64px, idle + active states)
- Blue button (48×48px, normal + glow + pressed)
- Red button (48×48px, normal + pulse + pressed)
- 4× district city tilesets (16×16px)
- 3× glitch overlay sprite sheets (light / medium / heavy)
- Space station window background
- Purple nebula (animated)
- CRT scanline overlay texture
- Operator wired-glove hand sprite

---

## Development Phases

| Phase | Timeline | Focus                                                  |
|-------|----------|--------------------------------------------------------|
| 1     | Wk 1–2   | ✅ Core scripts + state machine (this commit)           |
| 2     | Wk 3     | Pixel art assets + glitch shader                       |
| 3     | Wk 4     | Audio composition + waveform visualization             |
| 4     | Wk 5     | Juice / animations / difficulty balance / tutorial     |
| 5     | Wk 6     | Polish, builds, QA, release                            |

---

## Running the Project

1. Open **Godot 4.x** (4.3+ recommended)
2. Import the project via `project.godot`
3. Press **F5** (or Play) — main scene is `scenes/main.tscn`
4. Audio/sprite placeholders will print warnings until assets are added; gameplay
   mechanics are fully functional without them.
