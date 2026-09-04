class_name SimulationManager
extends Node
## Phase 6: central registry of all CelestialBodies in play. Systems query it
## instead of hard-wiring node paths (gravity in Phase 7 will iterate these
## bodies). Deliberately minimal: registration and listing only — no
## simulation tick yet.

const GROUP_NAME := "simulation_manager"

var bodies : Array[CelestialBody] = []


func _ready() -> void:
	add_to_group(GROUP_NAME)


func register_body(body : CelestialBody) -> void:
	if body == null or bodies.has(body):
		return
	bodies.append(body)


func unregister_body(body : CelestialBody) -> void:
	bodies.erase(body)


func get_bodies() -> Array[CelestialBody]:
	return bodies


func get_bodies_of_type(type : CelestialBody.BodyType) -> Array[CelestialBody]:
	var result : Array[CelestialBody] = []
	for body in bodies:
		if body.body_type == type:
			result.append(body)
	return result


func body_count() -> int:
	return bodies.size()