# Changelog

## [0.0.5] — Phase 4: Planet Damage System

### Changed (interaction revision)
- Controls reworked: **WASD continuously aims a crosshair** over the planet surface (camera-relative), **Space fires** along the current aim, **Esc** resets the aim. Click-to-target and the F fire-mode toggle are gone; the orbit camera moves to the arrow keys, zoom is unchanged.
- New `AimController` (`scripts/core/aim_controller.gd`, replaces the Phase 2 Selector): keeps a persistent local aim direction on the planet, slides it camera-relative each frame, and exposes the world-space aim point; guards against an unpositioned camera (deferred reset + zero-direction fallback).
- Projectiles pre-compute the **first surface intersection** along the shot direction (camera raycast at fire time) and impact exactly there — they can no longer tunnel through the planet toward a far-side target. `ImpactData` uses that actual hit position/normal, so the `ImpactData → PlanetDamage` pipeline is preserved.
- `SoundBank` now owns a small **pool of `AudioStreamPlayer`s** (4 per bank): rapid shots/impacts overlap naturally instead of cutting each other off; free players are reused and, when all are busy, the most-finished one is stolen. Random variation and no-immediate-repeat behaviour are unchanged, and the bank stays reusable for future weapons.
- `Main.tscn` wires two configured banks: `ShootBank` (shoot1/shoot2) and `ImpactBank` (impact / heavy-impact / deep-heavy-impact).

### Removed
- Click-to-target selector (`scripts/core/targeting.gd`) and the `toggle_fire_mode` (F) input action — replaced by continuous WASD aiming + Space firing.

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