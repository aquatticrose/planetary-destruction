class_name CelestialBody
extends Node3D
## Phase 6: reusable base class for every celestial object — planets, moons,
## stars, asteroids and fragments. Owns the shared physical identity
## (position via Node3D, velocity, mass, radius, rotation) and the
## spawn/despawn lifecycle, including automatic registration with the
## SimulationManager. Movement/gravity are NOT simulated here (Phase 7):
## velocity is carried as state for the future simulation tick.

signal spawned(body : CelestialBody)
signal despawned(body : CelestialBody)

enum BodyType { PLANET, MOON, STAR, ASTEROID, FRAGMENT }

@export var body_type : BodyType = BodyType.PLANET
## Relative mass (Earth masses for planets; arbitrary units for small bodies).
@export var mass : float = 1.0
@export var radius : float = 1.0
## World-space linear velocity. Integrated by the Phase 7 gravity tick.
@export var velocity : Vector3 = Vector3.ZERO
## Acceleration from the most recent gravity step (carried for the Verlet
## integrator and diagnostics). Updated by GravitySimulation.
@export var acceleration : Vector3 = Vector3.ZERO
## Self-rotation in radians/second per local axis (applied every frame).
@export var angular_velocity : Vector3 = Vector3.ZERO
## Zero means persistent. Fragments use a bounded simulation-time lifetime so
## debris cannot accumulate indefinitely in the O(n²) gravity solver.
@export var max_lifetime : float = 0.0
## The body this one orbits, if any (used for orbit initialisation and
## diagnostics). The relationship is physical, not kinematic: after init the
## body is released fully into the gravity simulation.
@export var parent : CelestialBody = null

var _manager : Node
var age : float = 0.0


func _ready() -> void:
	ensure_physical_shape()
	# Deferred: the manager may be a sibling whose _ready has not run yet.
	call_deferred("_register")


func _process(delta : float) -> void:
	if angular_velocity != Vector3.ZERO:
		rotation += angular_velocity * delta


## Finds the SimulationManager (by group) and registers this body.
func _register() -> void:
	_manager = get_tree().get_first_node_in_group(SimulationManager.GROUP_NAME)
	if _manager != null and _manager.has_method("register_body"):
		_manager.register_body(self)
		spawned.emit(self)
		DebugLog.info("%s spawned (type %d, mass %.2f)" % [name, body_type, mass])
	else:
		DebugLog.warn("CelestialBody '%s' has no SimulationManager to register with" % name)


## Lifecycle: remove this body from the simulation and free it. Unregister
## immediately rather than waiting for _exit_tree: queue_free() is deferred,
## and a physics tick may otherwise integrate or merge this body again before
## it leaves the scene tree. _exit_tree remains a safe fallback for teardown.
func despawn() -> void:
	if _manager != null and is_instance_valid(_manager) and _manager.has_method("unregister_body"):
		_manager.unregister_body(self)
	queue_free()


## Called by the fixed-step simulation, never presentation time. A paused
## simulation therefore also pauses debris cleanup.
func advance_lifetime(simulation_delta: float) -> void:
	if max_lifetime <= 0.0:
		return
	age += simulation_delta
	if age >= max_lifetime:
		despawn()


## Every celestial body has a queryable spherical hitbox. Gravity remains a
## custom N-body solver (rather than Godot rigid bodies), but the StaticBody3D
## makes bodies available to raycasts, targeting and future impact systems.
func ensure_physical_shape() -> void:
	var collider := get_node_or_null("Collider") as StaticBody3D
	if collider == null:
		collider = StaticBody3D.new()
		collider.name = "Collider"
		add_child(collider)
	var shape_node := collider.get_node_or_null("Shape") as CollisionShape3D
	if shape_node == null:
		shape_node = CollisionShape3D.new()
		shape_node.name = "Shape"
		collider.add_child(shape_node)
	var shape := shape_node.shape as SphereShape3D
	if shape == null:
		shape = SphereShape3D.new()
		shape_node.shape = shape
	shape.radius = maxf(radius, 0.001)


## Initialises this body in a circular orbit around `parent_body`. It is placed
## at `radius` along `direction` (a unit vector from the parent) and given the
## exact tangential speed for a circular orbit, v = sqrt(G * M / r), on top of
## the parent's own velocity. After this, the body is released entirely into
## the gravity simulation — nothing holds it on the orbit. `gravity_constant`
## is the G used by the simulation (passed in so this stays decoupled from the
## sim's configuration).
func initialize_orbit(parent_body : CelestialBody, radius : float, direction : Vector3, gravity_constant : float) -> void:
	parent = parent_body
	if parent == null:
		DebugLog.warn("initialize_orbit: null parent for '%s'" % name)
		return
	var dir_norm := direction.normalized()
	global_position = parent.global_position + dir_norm * radius
	# Tangent = a direction perpendicular to the radius. Prefer the global
	# up-axis cross product; fall back to another axis if the orbit is polar.
	var tangent := dir_norm.cross(Vector3.UP)
	if tangent.length_squared() < 0.0001:
		tangent = dir_norm.cross(Vector3.RIGHT)
	tangent = tangent.normalized()
	# Circular orbit speed for a negligible-mass body: v = sqrt(G * M / r).
	var speed := sqrt(maxf(gravity_constant * parent.mass / radius, 0.0))
	velocity = parent.velocity + tangent * speed
	acceleration = Vector3.ZERO


## Recomputes the circular-orbit state from new orbital parameters (used by
## manual orbit editing). Converts an orbital radius/direction edit into a
## one-off physical position + velocity, then returns the body to gravity.
func reinitialize_orbit(radius : float, direction : Vector3, gravity_constant : float) -> void:
	if parent == null:
		DebugLog.warn("reinitialize_orbit: '%s' has no parent" % name)
		return
	initialize_orbit(parent, radius, direction, gravity_constant)


func _exit_tree() -> void:
	if _manager != null and is_instance_valid(_manager) and _manager.has_method("unregister_body"):
		_manager.unregister_body(self)
	despawned.emit(self)
