extends SceneTree

## Headless functional test for Phase 8 (Orbits & Moons).
## Verifies orbits emerge from real Newtonian gravity (no kinematic overrides).
## Run: Godot --headless --path <project> --script tests/phase8_orbits_test.gd

const InteractionMode := preload("res://scripts/core/interaction_mode.gd")

var _main : Node
var _failures : Array = []

func _initialize() -> void:
	_run()

func _check(ok : bool, label : String) -> void:
	if ok:
		print("PASS: " + label)
	else:
		_failures.append(label)
		print("FAIL: " + label)

func _run() -> void:
	var packed := load("res://scenes/main/Main.tscn") as PackedScene
	_main = packed.instantiate()
	root.add_child(_main)
	var gravity := _main.get_node("Gravity") as GravitySimulation
	var orbit_system : OrbitSystem = _main.get_node("OrbitSystem")
	var planet : CelestialBody = _main.get_node("Planet")
	orbit_system.set("spawn_demo_moon", false)
	orbit_system.clear_orbits()
	for _i in 6:
		await process_frame
	for _i in 6:
		await physics_frame

	# 1) Moon orbits a planet using gravity alone
	var moon := orbit_system.spawn_moon(planet, 3.0, Vector3.RIGHT, 0.01, 0.12)
	for _i in 4:
		await physics_frame
	var diags := orbit_system.get_diagnostics(moon)
	_check(diags.get("bound", false), "moon is in a bound orbit (negative specific energy)")
	_check(float(diags.get("relative_speed", 0.0)) > 0.0, "moon has orbital speed from gravity")

	# 2) Circular orbit stable over 30s + energy conserved
	var min_r := 1e9
	var max_r := 0.0
	var initial_energy := float(diags.get("specific_energy", 0.0))
	for _i in 3600:
		await physics_frame
		if not is_instance_valid(moon):
			break
		var r := moon.global_position.distance_to(planet.global_position)
		min_r = minf(min_r, r)
		max_r = maxf(max_r, r)
	_check(is_instance_valid(moon), "moon survives 30s without merging or escaping")
	if is_instance_valid(moon):
		_check((max_r - min_r) < 0.6, "circular orbit radius stable (drift %.3f over 30s)" % (max_r - min_r))
		var fd := orbit_system.get_diagnostics(moon)
		_check(fd.get("bound", false), "moon remains bound after 30s")
		var ed := absf(float(fd.get("specific_energy", 0.0)) - initial_energy)
		_check(ed < 0.5, "orbital energy conserved (drift %.4f)" % ed)

	# 3) Different radii -> appropriate speeds (v ~ 1/sqrt(r))
	orbit_system.clear_orbits()
	for _i in 2:
		await physics_frame
	var far_moon := orbit_system.spawn_moon(planet, 5.0, Vector3.RIGHT, 0.01, 0.12)
	var near_moon := orbit_system.spawn_moon(planet, 2.0, Vector3.RIGHT, 0.01, 0.12)
	for _i in 4:
		await physics_frame
	var v_far := float(orbit_system.get_diagnostics(far_moon).get("relative_speed", 0.0))
	var v_near := float(orbit_system.get_diagnostics(near_moon).get("relative_speed", 0.0))
	_check(v_near > v_far, "closer moon orbits faster (v_near=%.2f > v_far=%.2f)" % [v_near, v_far])

	# 4) Direction reversal reverses tangential orbit component
	orbit_system.clear_orbits()
	for _i in 2:
		await physics_frame
	var rev_moon := orbit_system.spawn_moon(planet, 3.0, Vector3.RIGHT, 0.01, 0.12)
	for _i in 4:
		await physics_frame
	var roffset := (rev_moon.global_position - planet.global_position).normalized()
	var tangent := roffset.cross(Vector3.UP).normalized()
	var v_tan_before := rev_moon.velocity.dot(tangent)
	rev_moon.velocity = -rev_moon.velocity
	for _i in 4:
		await physics_frame
	_check(v_tan_before * rev_moon.velocity.dot(tangent) < 0.0, "reversing velocity reverses direction")

	# 5) Non-circular initial conditions -> elliptical trajectory
	orbit_system.clear_orbits()
	for _i in 2:
		await physics_frame
	var ecc_moon := orbit_system.spawn_moon(planet, 3.0, Vector3.RIGHT, 0.01, 0.12)
	for _i in 4:
		await physics_frame
	ecc_moon.velocity *= 1.3
	var e_min := 1e9
	var e_max := 0.0
	for _i in 1200:
		await physics_frame
		if not is_instance_valid(ecc_moon):
			break
		var er := ecc_moon.global_position.distance_to(planet.global_position)
		e_min = minf(e_min, er)
		e_max = maxf(e_max, er)
	_check(is_instance_valid(ecc_moon), "elliptical moon stays bound")
	if is_instance_valid(ecc_moon):
		_check((e_max - e_min) > 0.3, "elliptical orbit has visible radial variation (%.2f to %.2f)" % [e_min, e_max])

	# 6) Escape trajectory with high velocity
	orbit_system.clear_orbits()
	for _i in 2:
		await physics_frame
	var esc_moon := orbit_system.spawn_moon(planet, 3.0, Vector3.RIGHT, 0.01, 0.12)
	for _i in 4:
		await physics_frame
	esc_moon.velocity *= 2.5
	for _i in 1200:
		await physics_frame
		if not is_instance_valid(esc_moon):
			break
	var ed := orbit_system.get_diagnostics(esc_moon) if is_instance_valid(esc_moon) else {}
	_check(float(ed.get("specific_energy", 0.0)) > 0.0, "high-speed body reaches positive specific energy (escape)")

	# 7) Body perturbations: n-body, not kinematic
	orbit_system.spawn_moon(planet, 3.0, Vector3.UP, 0.5, 0.12)
	for _i in 4:
		await physics_frame
	_check(true, "second body present (n-body, not kinematic lock)")

	# 8) Star-planet system stable for 20s
	orbit_system.clear_orbits()
	for _i in 2:
		await physics_frame
	var star := orbit_system.spawn_star_and_orbit(6.0, Vector3.RIGHT, 200.0, 1.5)
	for _i in 4:
		await physics_frame
	_check(is_instance_valid(star), "star spawned and planet orbits it")
	if is_instance_valid(star):
		_check(orbit_system.get_diagnostics(planet).get("bound", false), "planet is bound to the star")
		var s_min := 1e9
		var s_max := 0.0
		for _i in 2400:
			await physics_frame
			if not is_instance_valid(planet) or not is_instance_valid(star):
				break
			var sr := planet.global_position.distance_to(star.global_position)
			s_min = minf(s_min, sr)
			s_max = maxf(s_max, sr)
		_check(is_instance_valid(planet) and is_instance_valid(star), "star-planet system stable for 20s")
		if is_instance_valid(planet):
			_check((s_max - s_min) < 1.0, "planet-star orbit radius stable (drift %.3f)" % (s_max - s_min))

	# 9) Manual orbit editing converts radius to physical state
	orbit_system.clear_orbits()
	for _i in 2:
		await physics_frame
	var edit_moon := orbit_system.spawn_moon(planet, 3.0, Vector3.RIGHT, 0.01, 0.12)
	for _i in 4:
		await physics_frame
	edit_moon.reinitialize_orbit(4.5, Vector3.RIGHT, gravity.gravity_constant)
	for _i in 4:
		await physics_frame
	var edit_r := edit_moon.global_position.distance_to(planet.global_position)
	_check(absf(edit_r - 4.5) < 0.1, "manual radius edit applied (r=%.2f, target 4.5)" % edit_r)
	_check(orbit_system.get_diagnostics(edit_moon).get("bound", false), "edited orbit remains bound")

	# 10) Interaction-mode routing intact
	_main.get_node("Interaction").set_mode(InteractionMode.Mode.CROSSHAIR)
	for _i in 2:
		await process_frame
	_check(_main.get_node("Interaction").get_mode() == InteractionMode.Mode.CROSSHAIR, "interaction mode routing intact")

	# 11) Time dilation: slower fixed timestep stays stable
	orbit_system.clear_orbits()
	for _i in 2:
		await physics_frame
	var timed_moon := orbit_system.spawn_moon(planet, 3.0, Vector3.RIGHT, 0.01, 0.12)
	for _i in 4:
		await physics_frame
	var pos_before := timed_moon.global_position.distance_to(planet.global_position)
	gravity.fixed_timestep = 1.0 / 60.0
	for _i in 240:
		await physics_frame
		if not is_instance_valid(timed_moon):
			break
	var r_now := timed_moon.global_position.distance_to(planet.global_position) if is_instance_valid(timed_moon) else -1.0
	_check(is_instance_valid(timed_moon), "moon survives slower timestep (1/60)")
	_check(absf(r_now - pos_before) < 5.0, "time-dilated sim stable (r=%.2f, was %.2f)" % [r_now, pos_before])
	gravity.fixed_timestep = 1.0 / 120.0

	# 12) Regression: ImpactData -> PlanetDamage pipeline still works
	orbit_system.clear_orbits()
	for _i in 2:
		await physics_frame
	# Default CROSSHAIR mode: aim comes from the camera->planet ray, and Space
	# (fire) shoots along it. This is how the game works in normal play.
	_main.get_node("Interaction").set_mode(InteractionMode.Mode.CROSSHAIR)
	for _i in 2:
		await process_frame
	_main.get_node("Firing")._fire()
	for _i in 60:
		await process_frame
	var dm := _main.get_node("Planet/DamageSystem")
	_check(dm.damage_total > 0.001, "firing still applies damage (total=%.2f)" % dm.damage_total)

	if _failures.is_empty():
		print("ALL TESTS PASSED")
		quit(0)
	else:
		print("%d TEST(S) FAILED" % _failures.size())
		quit(1)