extends CelestialBody
## Reusable planet node (Phase 6: now a CelestialBody — mass/radius/rotation and
## the spawn/despawn lifecycle come from the base class, and registration with
## the SimulationManager is automatic).
## Phase 5: data-driven. A PlanetData Resource defines the planet; apply_data()
## applies it to the surface mesh, collider and damage-shader visuals, and feeds
## mass into the body. gravity/rotation_speed remain DATA ONLY until the
## Phase 7 gravity simulation.
## Appearance comes from the child Surface + DamageSystem.

## Active preset. Assign in the editor, or call apply_data() at runtime (keys 1-5).
@export var data : Resource
## Phase 10: intentionally bounded; every fragment is a full gravitational body.
@export_range(6, 48, 2) var destruction_fragment_count : int = 24
@export var destruction_impulse : float = 1.5

var _destroyed : bool = false


func _init() -> void:
	body_type = BodyType.PLANET


func _ready() -> void:
	super() # base class: simulation manager registration
	if data != null:
		apply_data(data)
	var damage := get_node_or_null("DamageSystem")
	if damage != null and damage.has_signal("destruction_requested"):
		damage.destruction_requested.connect(destroy)


## Phase 5: apply a PlanetData preset to this planet (size + mass + visuals).
func apply_data(preset : PlanetData) -> void:
	if preset == null:
		return
	data = preset
	radius = maxf(0.05, preset.radius)
	mass = preset.mass
	# Phase 7: preset rotation is now live (base-class angular velocity).
	angular_velocity = Vector3.UP * preset.rotation_speed
	_apply_size()
	var damage := get_node_or_null("DamageSystem")
	if damage != null and preset.visual != null and damage.has_method("apply_visuals"):
		damage.apply_visuals(preset.visual)
	DebugLog.info("Planet data applied: %s (radius %.2f)" % [preset.display_name, radius])


## Resizes the surface mesh and collider to the current radius. The resources
## are duplicated first so several planet instances can never share/overwrite.
func _apply_size() -> void:
	var surface := get_node_or_null("Surface") as MeshInstance3D
	if surface != null:
		var mesh := surface.mesh as SphereMesh
		if mesh != null:
			if not mesh.resource_local_to_scene:
				mesh = mesh.duplicate()
				surface.mesh = mesh
			mesh.radius = radius
			mesh.height = radius * 2.0
	var shape_node := get_node_or_null("Collider/Shape") as CollisionShape3D
	if shape_node != null:
		var shape := shape_node.shape as SphereShape3D
		if shape != null:
			if not shape.resource_local_to_scene:
				shape = shape.duplicate()
				shape_node.shape = shape
			shape.radius = radius
	ensure_physical_shape()


## Converts a planet-local position (origin at the planet centre) to world space.
func local_to_world(local: Vector3) -> Vector3:
	return global_position + local


## Converts a world position to the planet's local space (origin at the planet centre).
func world_to_local(world: Vector3) -> Vector3:
	return world - global_position


## Replaces this planet with bounded, independently simulated fragments. Their
## total mass equals the planet's mass and paired radial impulses sum to zero,
## preserving the original centre-of-mass velocity before external gravity acts.
func destroy() -> void:
	if _destroyed:
		return
	_destroyed = true
	var container := get_parent()
	if container == null:
		return
	var count := max(6, destruction_fragment_count)
	if count % 2 != 0:
		count -= 1
	var fragment_mass := mass / float(count)
	var fragment_radius := radius * pow(1.0 / float(count), 1.0 / 3.0) * 0.72
	for pair_index in count / 2:
		var direction := _fragment_direction(pair_index, count / 2)
		_spawn_fragment(container, direction, fragment_mass, fragment_radius)
		_spawn_fragment(container, -direction, fragment_mass, fragment_radius)
	DebugLog.info("%s fragmented into %d physical bodies (total mass %.3f)" % [name, count, mass])
	despawn()


func _spawn_fragment(container: Node, direction: Vector3, fragment_mass: float, fragment_radius: float) -> void:
	var fragment := CelestialBody.new()
	fragment.name = "Fragment"
	fragment.body_type = CelestialBody.BodyType.FRAGMENT
	fragment.mass = fragment_mass
	fragment.radius = fragment_radius
	fragment.max_lifetime = 120.0
	fragment.global_position = global_position + direction * (radius * 0.82)
	fragment.velocity = velocity + direction * destruction_impulse
	fragment.angular_velocity = direction.cross(Vector3.UP) * 3.0
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = fragment_radius
	sphere.height = fragment_radius * 2.0
	sphere.radial_segments = 12
	sphere.rings = 8
	mesh.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.34, 0.22, 0.16)
	material.roughness = 0.9
	mesh.material_override = material
	fragment.add_child(mesh)
	container.add_child(fragment)


func _fragment_direction(index: int, pair_count: int) -> Vector3:
	var y := 1.0 - 2.0 * (float(index) + 0.5) / float(pair_count)
	var radial := sqrt(maxf(0.0, 1.0 - y * y))
	var angle := TAU * float(index) / 1.61803398875
	return Vector3(cos(angle) * radial, y, sin(angle) * radial).normalized()
