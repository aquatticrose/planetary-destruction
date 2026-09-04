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
- **Interaction revision** — two aim modes: **CROSSHAIR (default)** with a screen-centre crosshair (WASD/arrows orbit the camera to aim) and **TARGETING (T)** restoring click-to-target; Space fires in both, projectiles always impact at the **first surface intersection** (no tunneling), pooled sound banks so rapid shots/impacts overlap.
- **Phase 5 (Data-Driven Planets)** — done: `PlanetData`/`PlanetVisualSettings` resources, five live-switchable presets (Terra, Luna, Vulcanis, Glacia, Titanus) on **keys 1–5**, preset-driven size/visuals/camera limits, planet readout in the overlay.
- **Phase 6 (Celestial Bodies)** — done: reusable `CelestialBody` base class (typed body types, mass/radius/velocity/rotation, spawn/despawn lifecycle) and a `SimulationManager` registry; the planet is now a `CelestialBody` with automatic registration — infrastructure for the gravity simulation.
- **Phase 7 (Gravity)** — done: gameplay-friendly Newtonian gravity (pairwise attraction, velocity integration, fixed timestep), merging collision response, debug gravity vectors + force values on **G**, demo asteroids that fall/curve into the planet, camera tracks moving bodies, preset rotation now live.
- Orbital simulation (parents/moons/orbits), real mesh destruction: planned (Phase 8+).

## Input / Controls

| Action | Binding(s) |
| --- | --- |
| `orbit_left/right/up/down` | Arrow keys (orbit) |
| `aim_left/right/up/down` | WASD (aim marker in TARGETING mode; extra orbit in CROSSHAIR mode) |
| `camera_zoom_in/out` | Q / E (hold to zoom smoothly) |
| `fire` | Space |
| `toggle_aim_mode` | T |
| `toggle_gravity_debug` | G (gravity vectors + force values) |
| `preset_1..preset_5` | Number keys 1–5 (planet presets) |
| `cancel` (`ui_cancel`) | Esc |

**CROSSHAIR mode (default):** a real crosshair is fixed at the screen centre; orbit the camera (WASD/arrows) so the crosshair covers the point you want to hit, then **Space** fires along the view direction. **TARGETING mode (T):** LMB places the target marker on the planet, WASD slides it (camera-relative), Space fires at it. **Esc** resets the aim and returns to CROSSHAIR.

## Folder structure

```
assets/     re-usable art, models, textures, materials, audio, fonts
scenes/     main, planet, celestial, effects, ui
scripts/    core, simulation, planet, celestial, impacts, ui, debug
shaders/    shader code
data/       data-driven definitions (Resources); planet presets in data/planets/
tests/      automated tests
docs/       technical documentation
```

## Roadmap

See `docs/` and the project roadmap document for the full development plan.