# Planetary Destruction

A small, AI-assisted Godot planetary sandbox prototype.

## Engine & Target

- Godot **4.7.2** stable (pinned)
- Language: GDScript (typed where practical)
- Renderer: **Compatibility** (for reliable iteration on Intel/macOS)
- Target platform: **PC / macOS** first

## Setup

1. Install Godot 4.7.2 stable.
2. Open this project folder in Godot.
3. Run the main scene: `scenes/main/Main.tscn`.

## Current status

- **Phase 0 (Godot Foundation)** — done: project config, folder structure, input actions, basic environment, debug logging.
- **Phase 1 (The Planet)** — done: sphere planet, sun, space background, orbit camera with zoom/limits, basic UI overlay.
- **Phase 2 (Targeting)** — done: click-to-target raycast, world/local coords, surface normal, glued target marker, coords/normal in debug UI.
- **Phase 3 (First Destructive Interaction)** — done: minimal interaction modes (Orbit/Targeting/Firing), fake projectile, impact crater + particle burst, impact position recorded. Impact sound deferred (no audio asset yet).
- Damage system, gravity, real destruction: planned (Phase 4+).

## Input / Modes

| Action | Binding(s) |
| --- | --- |
| `orbit_left/right/up/down` | A/D/W/S or Arrow keys |
| `camera_zoom_in/out` | Mouse wheel |
| `select` | Left mouse button |
| `toggle_fire_mode` | F |
| `cancel` (`ui_cancel`) | Esc |

A minimal interaction mode decides what a click does:

- **Targeting** (default): left-click the planet to place/update the target marker (local coords + normal shown in the overlay).
- **Firing**: press **F** to enable, then left-click to launch a projectile at the current target. Press Esc to return to Targeting.

## Folder structure

```
assets/     re-usable art, models, textures, materials, audio, fonts
scenes/     main, planet, celestial, effects, ui
scripts/    core, simulation, planet, celestial, impacts, ui, debug
shaders/    shader code
data/       data-driven definitions (Resources)
tests/      automated tests
docs/       technical documentation
```

## Roadmap

See `docs/` and the project roadmap document for the full development plan.