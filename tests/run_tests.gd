extends SceneTree
## Headless regression suite for Planetary Destruction.
## Covers the scenarios that caught real regressions in Phases 3-7:
##   - interaction-mode routing (CROSSHAIR default / TARGETING toggle / camera flag)
##   - pooled sound overlap (one sound per event, rapid shots don't cut off)
##   - fire -> first-surface impact -> damage pipeline (no tunneling)
##   - celestial-body registration / spawn-despawn lifecycle
##   - gravity: attraction, velocity integration, collision merge, stability
##   - camera tracks a moving planet; preset rotation wired to angular velocity
##
## Run headlessly (no GPU):
##   Godot --headless --path <project> --script tests/run_tests.gd
## Exit code 0 = all pass, 1 = one or more failures.

const InteractionMode := preload("res://scripts/core/interaction_mode.gd")

var _main : Node
var _impacts : Array = []
var _failures : Array = []


func _initialize() -> void:
	_run()


func _check(ok : bool, label : String) -> void:
	if ok:
		print("PASS: " + label)
	else:
		_failures.append(label)
		print("FAIL: " + label)


func _spawn_body(pos : Vector3, vel : Vector3, mass : float, radius : float) -> CelestialBody:
	var body := CelestialBody.new()
	body.body_type = CelestialBody.BodyType.ASTEROID
	body.mass = mass
	body.radius = radius
	body.velocity = vel
	_main.add_child(body)
	body.global_position = pos
	return body
func _run() -> void:
	var packed := load("res://scenes/main/Main.tscn") as PackedScene
	_main = packed.instantiate()
	root.add_child(_main)
	var sim := _main.get_node("Gravity")
	var manager := _main.get_node("Simulation")
	var planet := _main.get_node("Planet")
	var camera := _main.get_node("Camera")
	var firing := _main.get_node("Firing")
	var damage := _main.get_node("Planet/DamageSystem")
	var selector := _main.get_node("PlanetSelector")
	var interaction := _main.get_node("Interaction")
	var crosshair_ui := _main.get_node("UI/Crosshair")
	var shoot_bank := _main.get_node("ShootBank")
	firing.impact_applied.connect(func(impact) -> void: _impacts.append(impact))

	for _i in 6:
		await process_frame
	for _i in 6:
		await physics_frame

	# --- Interaction-mode routing (caught: zoom swallowed by UI, mode flags) ----
	_check(interaction.get_mode() == InteractionMode.Mode.CROSSHAIR,
			"default interaction mode is CROSSHAIR")
	_check(crosshair_ui.visible, "crosshair UI visible in CROSSHAIR mode")
	_check(camera.get("wasd_enabled") == true, "camera WASD enabled in CROSSHAIR mode")
	interaction.set_mode(InteractionMode.Mode.TARGETING)
	_check(interaction.get_mode() == InteractionMode.Mode.TARGETING, "coordinator switches to TARGETING")
	_check(not crosshair_ui.visible, "crosshair UI hidden in TARGETING mode")
	_check(camera.get("wasd_enabled") == false, "camera WASD disabled in TARGETING mode")
	interaction.set_mode(InteractionMode.Mode.CROSSHAIR)
	_check(crosshair_ui.visible, "toggle back to CROSSHAIR shows the UI again")

	# --- Pooled sound overlap (caught: sounds cutting each other off) -----------
	firing._fire()
	await process_frame
	var projectiles : Array = firing.get_children().filter(
			func(c : Node) -> bool: return c.has_method("launch"))
	_check(projectiles.size() == 1, "one projectile spawned per shot")
	firing._fire()
	await process_frame
	var players_playing := 0
	for p in shoot_bank.get_children():
		if p is AudioStreamPlayer and p.playing:
			players_playing += 1
	_check(players_playing == 2, "rapid shots overlap (2 players playing, no cutoff)")

	# --- Fire -> first-surface impact -> damage (caught: tunneling regression) ---
	for _i in 150:
		await physics_frame
	_check(_impacts.size() == 2, "both shots impacted (got %d)" % _impacts.size())
	var surface_ok := true
	for impact in _impacts:
		if absf(impact.local_position.length() - float(planet.radius)) > 0.02:
			surface_ok = false
	_check(surface_ok, "impacts land on the first surface intersection (no tunneling)")
	_check(damage.get("damage_total") > 0.0, "PlanetDamage received the impacts")

	# --- Celestial-body registration / lifecycle -------------------------------
	var body_count_before : int = manager.body_count()
	var probe := _spawn_body(planet.global_position + Vector3(5, 0, 0), Vector3.ZERO, 0.001, 0.1)
	for _i in 2:
		await process_frame
	_check(manager.body_count() == body_count_before + 1, "spawned body auto-registers")
	probe.despawn()
	for _i in 2:
		await process_frame
	_check(manager.body_count() == body_count_before, "despawn unregisters the body")

	# --- Camera tracks a moving planet ----------------------------------------
	planet.global_position = Vector3(3.0, 0.0, 0.0)
	await process_frame
	await process_frame
	_check(camera.target.distance_to(planet.global_position) < 0.01,
			"camera target follows the moving planet")

	# --- Preset rotation wired to angular velocity (Phase 7) ------------------
	selector.apply_preset(0)  # Terra: rotation_speed 0.05
	_check(planet.angular_velocity.length_squared() > 0.0,
			"preset rotation_speed wired into angular velocity")

	# --- Gravity: attraction, velocity integration, stability ------------------
	var d0 : float = 4.0
	var faller := _spawn_body(planet.global_position + Vector3(d0, 0, 0), Vector3.ZERO, 0.001, 0.1)
	for _i in 60:
		await physics_frame
	var d1 : float = faller.global_position.distance_to(planet.global_position)
	_check(d1 < d0 - 0.1, "body fell toward the planet (d %.2f -> %.2f)" % [d0, d1])
	_check(faller.velocity.length() > 0.3, "velocity integrated from rest (v=%.3f)" % faller.velocity.length())
	var accel : Vector3 = sim.get_accel(faller)
	_check(accel.length() > 0.1, "gravity acceleration computed (a=%.3f)" % accel.length())
	_check(absf(sim.get_force(faller) - faller.mass * accel.length()) < 0.0001,
			"force value consistent (F = m*a)")
	_check(is_finite(faller.global_position.x) and faller.velocity.length() < 50.0,
			"simulation stayed stable (no blow-up)")

	# --- Collision check -> merge ---------------------------------------------
	var mass_before : float = planet.mass
	var merger := _spawn_body(planet.global_position + Vector3(planet.radius + 0.02, 0, 0),
			Vector3.ZERO, 0.002, 0.1)
	for _i in 4:
		await physics_frame
	_check(not is_instance_valid(merger) or merger.is_queued_for_deletion(),
			"overlapping body merged (collision check)")
	_check(planet.mass > mass_before, "planet absorbed the body's mass")

	# --- Debug toggle harmless -------------------------------------------------
	sim.debug_enabled = true
	await process_frame
	_check(sim.debug_enabled, "gravity debug toggle enables without error")
	sim.debug_enabled = false

	if _failures.is_empty():
		print("ALL TESTS PASSED")
		quit(0)
	else:
		print("%d TEST(S) FAILED" % _failures.size())
		quit(1)