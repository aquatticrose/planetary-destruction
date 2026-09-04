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


func _init() -> void:
	body_type = BodyType.PLANET


func _ready() -> void:
	super() # base class: simulation manager registration
	if data != null:
		apply_data(data)


## Phase 5: apply a PlanetData preset to this planet (size + mass + visuals).
func apply_data(preset : PlanetData) -> void:
	if preset == null:
		return
	data = preset
	radius = maxf(0.05, preset.radius)
	mass = preset.mass
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


## Converts a planet-local position (origin at the planet centre) to world space.
func local_to_world(local: Vector3) -> Vector3:
	return global_position + local


## Converts a world position to the planet's local space (origin at the planet centre).
func world_to_local(world: Vector3) -> Vector3:
	return world - global_position
