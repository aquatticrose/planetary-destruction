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
## World-space linear velocity. Data only until the Phase 7 gravity tick.
@export var velocity : Vector3 = Vector3.ZERO
## Self-rotation in radians/second per local axis (applied every frame).
@export var angular_velocity : Vector3 = Vector3.ZERO

var _manager : Node


func _ready() -> void:
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


## Lifecycle: remove this body from the simulation and free it. Unregistration
## happens in _exit_tree, so both this path and scene teardown are covered.
func despawn() -> void:
	queue_free()


func _exit_tree() -> void:
	if _manager != null and is_instance_valid(_manager) and _manager.has_method("unregister_body"):
		_manager.unregister_body(self)
	despawned.emit(self)