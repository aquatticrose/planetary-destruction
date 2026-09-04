# Changelog

## [0.0.2] - 2026-09-04 - Phase 1: The Planet

### Added
- Reusable planet scene (`scenes/planet/planet.tscn`): `SphereMesh` + `StandardMaterial3D`, with a `Planet` script exposing `radius`.
- Sun lighting: `DirectionalLight3D` (warm, soft shadows).
- Space background: darker procedural sky (re-skinned `WorldEnvironment`;ambient-from-sky preserved.).
- Orbit camera (`scripts/core/planet_camera_controller.gd`): WASD/Arrow orbit, mouse-wheel zoom, clamped pitch (+/-80 deg) and distance (never clips the surface).Camera auto-reads the planet radius from one source via `planet_path`.
- Basic UI overlay (`scripts/ui/overlay.gd`): control hint + live camera-distance readout..

## [0.0.1] - 2026-09-04 - Phase 0: Godot Foundation

### Added
- Godot 4.7 project configuration: name, icon, Compatibility renderer, Jolt physics, PC/macOS target.
- `run/main_scene` pointing at `scenes/main/Main.tscn`.
- Project folder structure:
- Input actions:
- `Main.tscn`: root node plus `WorldEnvironment` (procedural sky, ambient light, filmic tonemapping).
- Basic debug logging (`DebugLog`) plus boot log.
- `.gitignore` ignoring Godot cache, Android exports, export output, and logs.
