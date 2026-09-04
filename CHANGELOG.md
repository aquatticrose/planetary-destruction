# Changelog

## [0.0.3] — Phase 2: Targeting

### Added
- Click-to-target:left-click the planet to raycast from the camera through the mouse position;detect the planet via its static collision body;convert the hit to local coordinates;compute the surface normal at the hit point.
- Target marker:small emissive sphere glued to the surface at the hit point;left-clicking empty space hides it gracefully(no errors.
- Debug UI readout:the overlay shows the target local coordinates and surface normal live.
- Decoupled via signals:the overlay listens to `target_selected`/`target_cleared` emitted by the Selector node;the Selector never knows the UI exists.

## [0.0.2] — Phase 1: The Planet

### Added
- Reusable planet scene:`scenes/planet/planet.tscn`(`SphereMesh` + `StandardMaterial3D`),with a `Planet` script exposing `radius`.
- Sun lighting:`DirectionalLight3D`(warm,soft shadows.
- Space background:darker procedural sky(re-skinned `WorldEnvironment`,ambient-from-sky preserved.
- Orbit camera:`scripts/core/planet_camera_controller.gd`:WASD/Arrow orbit, mouse-wheel zoom,,clamped pitch(+/-80 deg,and distance(never clips the surface;;camera auto-reads radius via `planet_path`.
- Basic UI overlay:`scripts/ui/overlay.gd`:control hint + live camera-distance readout.

## [0.0.1] — Phase 0: Godot Foundation

### Added
- Godot 4.7 project configuration:name,icon,Compatibility renderer,Jolt physics,PC/macOS target.
- `run/main_scene` pointing at `scenes/main/Main.tscn`.
- Project folder structure: `scenes/ scripts/ assets/ shaders/ data/ tests/ docs/`((with `.gitkeep` placeholders.
- Input actions:`orbit_left/right/up/down`,`camera_zoom_in/out`,`select`.
- `Main.tscn`:root node + `WorldEnvironment`(procedural sky,ambient light,filmic tonemapping.
- Basic debug logging(`DebugLog`)+ boot log.
- `.gitignore` ignoring Godot cache,Android exports,export output,and logs.
