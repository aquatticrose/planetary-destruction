# Planetary Destruction

A small, AI-assisted Godot planetary sandbox prototype.

## Engine & Target

- Godot **4.7.2** stable (pinned.
- Language: GDScript (typed where practical.
- Renderer: **Compatibility** (for reliable iteration on Intel/macOS.
- Target platform: **PC / macOS** first.

## Setup

1. Install Godot 4.7.2 stable.
2. Open this project folder (e.g. `/path/to/planetary-destruction`)in Godot.
3. Run the main scene: `scenes/main/Main.tscn`.

## Current status

- **Phase 0 (Godot Foundation)** — done: project configuration, folder structure, input actions, `Main.tscn` basic environment, debug logging.
- **Phase 1 (The Planet)** — done: sphere planet with material, sun lighting, space background, orbit camera with zoom/limits, basic UI overlay.
- **Phase 2 (Targeting)** — done: left-click raycast targeting, world/local coords, surface normal, glued target marker, coords/normal in debug UI.
- Targets, projectiles, damage, gravity, destruction: planned for later phases (3+.

## Input actions

| Action | Binding(s) |
| --- | --- |
| `orbit_left` | Left Arrow, A |
| `orbit_right` | Right Arrow, D |
| `orbit_up` | Up Arrow, W |
| `orbit_down` | Down Arrow, S |
| `camera_zoom_in` | Mouse wheel up |
| `camera_zoom_out` | Mouse wheel down |
| `select` | Left mouse button |

## Controls

- **Orbit** the camera around the planet:WASD or Arrow keys.
- **Zoom** with the mouse wheel (camera distance auto-clamped,never clips the surface.
- **Target**:left-click the planet to place a marker at the hit point;left-click empty space hides it.

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

See `docs/` and the project roadmap document for the full development plan.
