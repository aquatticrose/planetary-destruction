# Planetary Destruction

A small, AI-assisted Godot planetary sandbox prototype.



## Engine and Target

- Godot **4.7.2** stable (pinned.)
- Language: GDScript (typed where practical.)
- Renderer: **Compatibility** (for reliable iteration on Intel/macOS.)
- Target platform: **PC / macOS** first.



## Setup


1. Install Godot 4.7.2 stable..
2. Open this project folder (`/path/to/planetary-destruction`)in Godot..
3. Open and run the main scene: `scenes/main/Main.tscn`.



## Current status

Phase 0 (Godot Foundation) complete:
- Godot project configured (Compatibility renderer, PC/macOS target.)
- Project folder structure created: `scenes/`, `scripts/`, `assets/`, `shaders/`, `data/`, `tests/`, `docs/`.
- Input actions configured (see below.)
- `Main.tscn` with basic environment and lighting..
- Basic debug logging via `DebugLog`.

## Input actions

These are wired in `project.godot` for future camera/orbit/zoom/targeting systems. They are not yet bound to gameplay logic,, which arrives in later phases..



| Action | Binding(s) |
| --- | --- |
| `orbit_left` | Left Arrow, A |
| `orbit_right` | Right Arrow, D |
| `orbit_up` | Up Arrow, W |
| `orbit_down` | Down Arrow, S |
| `camera_zoom_in` | Mouse wheel up |
| `camera_zoom_out` | Mouse wheel down |
| `select` | Left mouse button |

## Folder structure

```
assets/     re-usable art, models, textures, materials, audio, fonts
scenes/     main, planet, celestial, effects, ui
scripts/    core, simulation, planet, celestial, impacts, ui
shaders/    shader code
data/       data-driven definitions (Resources)
tests/      automated tests
docs/       technical documentation
```

## Roadmap

See `docs/` andthe project roadmap document for the full development plan..
