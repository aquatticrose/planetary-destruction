# Changelog

## [0.2.0] — Phases 6 & 7: Celestial Bodies + Gravity

### Phase 7 — Gravity

### Added
- `GravitySimulation` (`scripts/simulation/gravity_simulation.gd`): gameplay-friendly Newtonian gravity, not a scientific simulator. Pairwise attraction (`a = G·M/r²`, softened so tiny separations can't explode forces), semi-implicit Euler velocity→position integration, and a stable fixed timestep (Godot's 60 Hz physics tick, delta-clamped). `gravity_constant` (default 10) is tuned for scene-scale units and fully tunable.
- **Collision checks:** overlapping bodies merge into the more massive one — momentum-conserving velocity, centre-of-mass position, volume-preserving radius growth. Planets rebuild their mesh/collider on absorb. Merging doubles as the stability mechanism (no r→0 force singularity).
- Debug **gravity vectors:** `GravityDebug` (`scripts/simulation/gravity_debug_draw.gd`) draws each body's acceleration as an orange world-space line (ImmediateMesh, rebuilt per frame). Pure presentation — reads the simulation's computed accelerations.
- Debug **force values:** with debug on, per-body acceleration, force (`F = m·a`) and speed are logged once per second.
- **G** (`toggle_gravity_debug`) toggles debug vectors + force logging.
- Demo content: `GravityDemo` spawns 3 small asteroids (code-generated visuals, `ASTEROID` type, auto-registered via the Phase 6 lifecycle) with mostly-radial + tangential velocities, so bodies visibly curve in and sometimes get absorbed. Delete the node to remove it. Deliberately NOT the Phase 8 orbit system.

### Changed
- Camera orbit target now tracks the planet's **live** position (bodies move).
- Preset `rotation_speed` is now live: `Planet.apply_data()` feeds it into the base-class `angular_velocity` (Terra spins slowly). Aim marker, impacts and damage stay glued to the rotating surface — all consumers already work in planet-local space.
- Registry stays consistent through organic merges (verified: a demo asteroid can absorb into the planet mid-session).
- Documented the gravity pairwise loop as O(n^2) with a scaling note for the Phase 10-11 fragment phase — no premature optimisation.

### Phase 6 — Celestial Bodies

### Added
- `CelestialBody` base class (`scripts/celestial/celestial_body.gd`): the reusable identity for every celestial object — planets, moons, stars, asteroids and fragments. Owns a typed `BodyType` enum, `mass`, `radius`, `velocity` and `angular_velocity` (self-rotation, applied per frame), plus a spawn/despawn lifecycle: bodies auto-register with the `SimulationManager` on entering the tree and unregister on exit; `despawn()` removes a body cleanly. No gravity/movement simulation yet — `velocity` is carried as state for the Phase 7 gravity tick.
- `SimulationManager` (`scripts/simulation/simulation_manager.gd`): central registry of all living `CelestialBody` instances (typed arrays; `get_bodies()`, `get_bodies_of_type()`, `body_count()`). Systems query the manager instead of hard-wiring node paths — Phase 7 gravity will iterate these bodies. Deliberately registration/listing only.

### Changed
- `Planet` now extends `CelestialBody`: mass/radius/rotation state and the spawn/despawn lifecycle come from the base class, and the planet registers with the `SimulationManager` automatically (visible in the boot log). Preset `mass` flows into the body. No public API changed — camera, aim, firing and overlay consume the same surface as before.
- `Main.tscn`: added the `Simulation` manager node.
- PlanetData's `rotation_speed` stays **data only** for now (the base class already supports per-body `angular_velocity`); wiring preset rotation into actual spin arrives with the Phase 7 simulation so aim behaviour is not changed mid-phase.

## [0.1.0] — Phase 5: Data-Driven Planets

### Added
- `PlanetData` resource (`data/planet_data.gd`): display name, radius, mass, gravity, rotation speed, temperature, atmosphere density, surface type, composition, generation seed and visual settings. Physics fields (mass/gravity/rotation) are **data only** for now — later phases consume them.
- `PlanetVisualSettings` resource (`data/planet_visual_settings.gd`): base colour, roughness, ember colour/strength, wrinkle strength, atmosphere colour (reserved).
- **Five planet presets** (`data/planets/*.tres`): **Terra** (Earth-like), **Luna** (barren moon), **Vulcanis** (volcanic), **Glacia** (icy), **Titanus** (gas giant) — selectable at runtime, no gameplay code duplicated.
- `Planet.apply_data()`: applies a preset to the surface mesh, collider and damage-shader visuals; mesh/shape resources are duplicated per instance so presets can never leak between planets.
- `PlanetDamage.apply_visuals()`: pushes preset visuals into the cached crater material (cached material survives impacts).
- Crater shader now exposes `base_color`, `roughness`, `ember_color`, `ember_strength` uniforms (defaults keep the Phase 4 warm-rock look).
- `PlanetSelector` (`scripts/core/planet_selector.gd`): **keys 1–5** swap the planet preset live (`preset_1..preset_5` input actions); starts on Terra (preset 1).
- Overlay shows a live "Planet: <name> (n/5)" readout; camera zoom limits re-derive from the active radius every frame, so big/small presets re-clamp the camera instantly.

### Changed
- `project.godot`: added `preset_1..preset_5` inputs (number keys 1–5).
- Zoom rebound from mouse wheel to **Q / E** (`camera_zoom_in/out`): holding the key zooms smoothly (exponential, `zoom_key_rate` tunable on the camera); clamped limits and preset-driven re-clamping unchanged.

## [0.0.5] — Phase 4: Planet Damage System

### Changed (interaction revision)
- Controls reworked into **two aim modes** routed by the interaction coordinator: **CROSSHAIR (default)** — a real crosshair sits fixed at the **screen centre**, the camera orbits with WASD/arrows to aim, **Space** fires along the view direction; **TARGETING (T)** — the Phase 2/3 click-to-target behaviour returns (LMB places the marker, WASD slides it camera-relative). **Esc** resets the aim and returns to CROSSHAIR.
- `AimController` (`scripts/core/aim_controller.gd`, replaces the Phase 2 Selector) now owns both modes: in CROSSHAIR it raycasts from the camera through the screen centre every frame and moves the 3D marker to the hit; in TARGETING it keeps the persistent WASD-slid aim. Guards against an unpositioned camera (deferred reset + zero-direction fallback).
- Projectiles pre-compute the **first surface intersection** along the shot direction (camera raycast at fire time) and impact exactly there — they can no longer tunnel through the planet toward a far-side target. `ImpactData` uses that actual hit position/normal, so the `ImpactData → PlanetDamage` pipeline is preserved.
- `SoundBank` now owns a small **pool of `AudioStreamPlayer`s** (4 per bank): rapid shots/impacts overlap naturally instead of cutting each other off; free players are reused and, when all are busy, the most-finished one is stolen. Random variation and no-immediate-repeat behaviour are unchanged, and the bank stays reusable for future weapons.
- `Main.tscn` wires two configured banks: `ShootBank` (shoot1/shoot2) and `ImpactBank` (impact / heavy-impact / deep-heavy-impact).

### Removed
- The `toggle_fire_mode` (F) input action and the per-click firing route — Space fires in both aim modes; **T** (`toggle_aim_mode`) now switches CROSSHAIR ⇄ TARGETING. (Click-to-target was removed in the first pass of this revision, then restored as TARGETING mode.)

### Added
- `ImpactData` resource (`data/impact_data.gd`): strength, radius, world/local position and surface normal of a single impact.
- Persistent `DamageMap` (`scripts/planet/damage_map.gd`): a per-planet bitmap (Image → ImageTexture) painted with procedural `FastNoiseLite` dapples, so repeated hits build up organic craters instead of perfect circles.
- `PlanetDamage` system (`scripts/planet/planet_damage.gd`): receives `impact_applied(ImpactData)` from the firing controller (decoupled via signal), accumulates the map, refreshes the crater shader, and raises the planet's global damage stage as thresholds are crossed (Healthy → Damaged → Cracked → Critical).
- Crater shader (`shaders/planet_damage.gdshader`): Compatibility-renderer spatial shader that darkens craters, adds an ember rim, and nudges the surface normal/position for a crack "wrinkle" displacement illusion — no expensive real mesh destruction.
- Firing now emits `ImpactData` on impact; `planet.gd` gained `world_to_local()`/`local_to_world()` conversion helpers.
- Overlay shows live "Damage: X.XX  Stage: <stage>" readout.
- Damage thresholds: stage changes at 1 / 4 / 10 / 20 total damage.

## [0.0.4] — Phase 3: First Destructive Interaction

### Added
- Minimal interaction-mode coordinator: typed `InteractionMode` enum (`ORBIT` / `TARGETING` / `FIRING`) plus a small coordinator that routes interaction intent. Default is Targeting; **F** toggles Firing; **Esc** returns to the default mode. Orbit/zoom unchanged; targeting logic reused (gated by mode).
- Fake projectile (`scenes/celestial/projectile.tscn`): constant-speed travel to the target point then "impact" — no physics bodies.
- Firing controller (`scripts/impacts/firing_controller.gd`): in Firing mode, click launches a projectile from the camera at the targeted surface point; on impact it records the world position and spawns an impact effect.
- Temporary impact effect (`scenes/effects/impact_effect.tscn`): a short-lived dark crater mark + one-shot particle burst that self-removes.
- Overlay now shows the current interaction mode and an updated control hint.
- Randomized sound banks (`scripts/core/sound_bank.gd`): a reusable `SoundBank` node plays exactly one randomly selected variation per event and avoids immediately repeating the same one. Firing plays a `shoot` sound (`shoot1.mp3`/`shoot2.mp3`); impact plays an `impact` sound (`impact.mp3`/`heavy-impact.mp3`/`deep-heavy-impact.mp3`). Future weapons can register their own banks via `register_bank()`.

## [0.0.3] — Phase 2: Targeting

### Added
- Click-to-target: left-click the planet to raycast from the camera through the mouse; detect the planet via its static collision body; convert the hit to local coordinates; compute the surface normal at the hit point.
- Target marker: small emissive sphere glued to the surface; left-clicking empty space hides it gracefully (no errors).
- Debug UI readout: the overlay shows target local coordinates and surface normal live.
- Decoupled via signals: the overlay listens to `target_selected`/`target_cleared` emitted by the Selector; the Selector never knows the UI exists.

## [0.0.2] — Phase 1: The Planet

### Added
- Reusable planet scene (`scenes/planet/planet.tscn`), `SphereMesh` + `StandardMaterial3D`, `Planet` script exposing `radius`.
- Sun lighting (`DirectionalLight3D`), warm soft shadows.
- Space background: darker procedural sky (ambient-from-sky preserved).
- Orbit camera (`scripts/core/planet_camera_controller.gd`): WASD/Arrow orbit, mouse-wheel zoom, clamped pitch +/-80 deg and distance (never clips the surface); camera auto-reads radius via `planet_path`.
- Basic UI overlay (`scripts/ui/overlay.gd`): control hint + live camera-distance readout.

## [0.0.1] — Phase 0: Godot Foundation

### Added
- Godot 4.7 project configuration: name, icon, Compatibility renderer, Jolt physics, PC/macOS target.
- `run/main_scene` pointing at `scenes/main/Main.tscn`.
- Project folder structure (scenes/, scripts/, assets/, shaders/, data/, tests/, docs/ with `.gitkeep` placeholders).
- Input actions: `orbit_left/right/up/down`, `camera_zoom_in/out`, `select`.
- `Main.tscn`: root node + `WorldEnvironment` (procedural sky, ambient light, filmic tonemapping).
- Basic debug logging (`DebugLog`) plus boot log.
- `.gitignore` ignoring Godot cache, Android exports, export output, and logs.