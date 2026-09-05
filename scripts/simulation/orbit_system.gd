class_name OrbitSystem
extends Node3D
## Phase 8: orbit authoring, visualisation and diagnostics. Spawns moons and
## stars, initialises circular orbits from physical parameters (v = sqrt(GM/r)),
## attaches trajectory trails, and exposes orbital diagnostics. All motion is
## produced by the gravity simulation — this node only sets initial conditions
## and reads state. No kinematic orbit controller is used: after init, bodies
## are released fully into the N-body simulation.

@export var planet_path : NodePath
@export var gravity_path : NodePath
## Spawns one demo moon on ready so there is an orbit to see immediately.
@export var spawn_demo_moon : bool = true

var _planet : CelestialBody
var _gravity : GravitySimulation
var _spawned : Array[CelestialBody] = []
var _selected : CelestialBody = null


func _ready() -> void:
	_planet = get_node_or_null(planet_path) as CelestialBody
	_gravity = get_node_or_null(gravity_path) as GravitySimulation
	if _planet == null or _gravity == null:
		DebugLog.warn("OrbitSystem: planet or gravity path not wired")
		return
	if spawn_demo_moon:
		spawn_moon(_planet, 2.5, Vector3.RIGHT)


func _unhandled_input(event : InputEvent) -> void:
	if _gravity == null:
		return
	if event.is_action_pressed("spawn_moon"):
		if _planet != null:
			spawn_moon(_planet, 2.0 + _spawned.size() * 0.8, Vector3.RIGHT)
	elif event.is_action_pressed("spawn_star"):
		spawn_star_and_orbit(6.0, Vector3.RIGHT)
	elif event.is_action_pressed("clear_orbits"):
		clear_orbits()
	elif event.is_action_pressed("orbit_radius_up"):
		_edit_radius(0.5)
	elif event.is_action_pressed("orbit_radius_down"):
		_edit_radius(-0.5)
	elif event.is_action_pressed("orbit_reverse"):
		_reverse_orbit()


## Spawns a moon in a circular orbit around `parent`. The orbit speed is derived
## from the actual gravitational parameters (v = sqrt(GM/r)); after init the
## moon is released fully into the gravity simulation.
func spawn_moon(parent : CelestialBody, radius : float, direction : Vector3, mass := 0.01, body_radius := 0.15, color := Color(0.6, 0.6, 0.65)) -> CelestialBody:
	var moon := CelestialBody.new()
	moon.name = "Moon_%d" % (_spawned.size() + 1)
	moon.body_type = CelestialBody.BodyType.MOON
	moon.mass = mass
	moon.radius = body_radius
	_add_visual(moon, color)
	add_child(moon)
	moon.initialize_orbit(parent, radius, direction, _gravity.gravity_constant)
	_spawned.append(moon)
	_selected = moon
	_attach_trail(moon)
	DebugLog.info("Spawned %s: circular orbit radius %.2f around %s (v=%.2f)" % [moon.name, radius, parent.name, moon.velocity.length()])
	return moon


## Spawns a star at the origin and places the planet in a circular orbit around
## it. Clears any existing moons first (the planet moves, so old moon orbits would
## no longer be valid). After init, the planet is released into the sim.
func spawn_star_and_orbit(orbital_radius : float, direction : Vector3, star_mass := 200.0, star_radius := 1.5) -> CelestialBody:
	if _planet == null:
		return null
	clear_orbits()
	var star := CelestialBody.new()
	star.name = "Star"
	star.body_type = CelestialBody.BodyType.STAR
	star.mass = star_mass
	star.radius = star_radius
	star.angular_velocity = Vector3.UP * 0.02
	_add_visual(star, Color(1.0, 0.85, 0.4))
	add_child(star)
	star.global_position = global_position
	star.velocity = Vector3.ZERO
	_spawned.append(star)
	_planet.initialize_orbit(star, orbital_radius, direction, _gravity.gravity_constant)
	_selected = _planet
	_attach_trail(_planet)
	DebugLog.info("Spawned %s (mass %.1f): planet orbiting at radius %.2f (v=%.2f)" % [star.name, star_mass, orbital_radius, _planet.velocity.length()])
	return star


## Removes all spawned bodies and their trails.
func clear_orbits() -> void:
	for body in _spawned:
		if is_instance_valid(body):
			body.despawn()
	_spawned.clear()
	_selected = null


## Manual orbit editing: converts a radius change into a one-off physical state
## (new position + circular-orbit velocity), then returns the body to gravity.
func _edit_radius(delta : float) -> void:
	if _selected == null or _selected.parent == null:
		return
	var offset : Vector3 = _selected.global_position - _selected.parent.global_position
	var current_radius : float = offset.length()
	var new_radius : float = maxf(_selected.parent.radius + _selected.radius + 0.1, current_radius + delta)
	_selected.reinitialize_orbit(new_radius, offset.normalized(), _gravity.gravity_constant)
	DebugLog.info("Edited %s orbit radius: %.2f -> %.2f" % [_selected.name, current_radius, new_radius])


## Manual orbit editing: reverses orbital direction by flipping velocity.
func _reverse_orbit() -> void:
	if _selected == null:
		return
	_selected.velocity = -_selected.velocity
	DebugLog.info("Reversed %s orbital direction" % _selected.name)


## Orbital diagnostics for a body relative to its parent. Returns distance,
## speeds, radial/tangential velocity, specific orbital energy and whether the
## orbit is bound. Pure readouts — nothing here influences the simulation.
func get_diagnostics(body : CelestialBody) -> Dictionary:
	var d := {}
	d["name"] = body.name
	d["mass"] = body.mass
	d["speed"] = body.velocity.length()
	d["acceleration"] = body.acceleration.length()
	if body.parent != null and is_instance_valid(body.parent):
		var offset : Vector3 = body.global_position - body.parent.global_position
		var r : float = maxf(offset.length(), 1e-3)
		d["distance"] = r
		var parent_mass : float = body.parent.mass
		d["circular_speed"] = sqrt(_gravity.gravity_constant * parent_mass / r)
		var vrel : Vector3 = body.velocity - body.parent.velocity
		d["relative_speed"] = vrel.length()
		var rhat := offset.normalized()
		d["radial_velocity"] = vrel.dot(rhat)
		d["tangential_velocity"] = (vrel - rhat * d["radial_velocity"]).length()
		# Specific orbital energy: negative = bound, positive = escaping.
		d["specific_energy"] = 0.5 * vrel.length_squared() - _gravity.gravity_constant * parent_mass / r
		d["bound"] = d["specific_energy"] < 0.0
	return d


## Adds a glowing sphere visual to a body.
func _add_visual(body : CelestialBody, color : Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = body.radius
	sphere.height = body.radius * 2.0
	sphere.radial_segments = 24
	sphere.rings = 16
	mesh_instance.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	mesh_instance.material_override = mat
	body.add_child(mesh_instance)


## Attaches a trajectory trail to a body so its actual path is visualised.
func _attach_trail(body : CelestialBody) -> void:
	var trail := TrajectoryTrail.new()
	trail.name = "Trail"
	trail.target_path = ".."
	trail.trail_color = Color(0.4, 0.9, 1.0, 0.8)
	trail.max_points = 900
	body.add_child(trail)