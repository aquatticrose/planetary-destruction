extends Node3D
## Phase 7 demo content: spawns a few small asteroids near the planet so the
## gravity simulation has something to attract. Deliberately throwaway and
## easy to remove (delete this node) — this is NOT the Phase 8 orbit system:
## bodies just get an initial velocity and fall/curve in under gravity.

@export var planet_path : NodePath
@export var asteroid_count : int = 3
@export var min_distance : float = 3.5
@export var max_distance : float = 6.0

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	# Deferred: let the planet apply its preset (mass/radius) first.
	call_deferred("_spawn")


func _spawn() -> void:
	var planet : Node3D = get_node_or_null(planet_path)
	if planet == null:
		return
	for i in asteroid_count:
		var asteroid := CelestialBody.new()
		asteroid.name = "Asteroid_%d" % (i + 1)
		asteroid.body_type = CelestialBody.BodyType.ASTEROID
		asteroid.mass = _rng.randf_range(0.001, 0.003)
		asteroid.radius = _rng.randf_range(0.08, 0.14)
		_add_visual(asteroid)
		add_child(asteroid)
		var dir := _random_unit_vector()
		asteroid.global_position = planet.global_position + dir * _rng.randf_range(min_distance, max_distance)
		# Mostly-radial with a tangential component: bodies visibly curve in.
		var tangential := dir.cross(Vector3.UP)
		if tangential.length_squared() < 0.01:
			tangential = Vector3.RIGHT
		asteroid.velocity = dir * _rng.randf_range(0.15, 0.45) \
				+ tangential.normalized() * _rng.randf_range(0.6, 1.1)
		# (Registration with the SimulationManager happens in CelestialBody._ready.)


func _add_visual(body : Node3D) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = body.radius
	mesh.height = body.radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	mesh.material = StandardMaterial3D.new()
	mesh.material.albedo_color = Color(0.55, 0.55, 0.58)
	var visual := MeshInstance3D.new()
	visual.name = "Visual"
	visual.mesh = mesh
	body.add_child(visual)


func _random_unit_vector() -> Vector3:
	var v := Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0))
	return v.normalized() if v.length_squared() > 0.0001 else Vector3.FORWARD