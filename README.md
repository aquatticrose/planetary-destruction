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
- **Phase 3 (First Destructive Interaction)** — done: minimal interaction modes (Orbit/Targeting/Firing), fake projectile, impact crater + particle burst, impact position recorded, and randomized shoot/impact sound banks.
- **Phase 4 (Planet Damage System)** — done: persistent damage map + crater shader (darkened craters, ember rim, crack wrinkle displacement), `ImpactData` resource, planet damage stages (Healthy → Damaged → Cracked → Critical), and a live damage readout in the overlay.
- **Interaction revision** — WASD aiming crosshair + Space firing (click-to-target retired), projectiles always impact at the **first surface intersection** (no tunneling), pooled sound banks so rapid shots/impacts overlap.
- Gravity, real destruction, data-driven planets: planned (Phase 5+).

## Input / Controls

| Action | Binding(s) |
| --- | --- |
| `orbit_left/right/up/down` | Arrow keys |
| `aim_left/right/up/down` | WASD |
| `camera_zoom_in/out` | Mouse wheel |
| `fire` | Space |
| `cancel` (`ui_cancel`) | Esc |

Aiming is continuous: WASD slides an aim crosshair over the planet surface (camera-relative; the orange dot marks exactly where the next shot will land). **Space** fires along the current aim. **Esc** resets the aim to face the camera.

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