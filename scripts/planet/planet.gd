extends Node3D
## Reusable planet node.
## Phase 1: holds the core planet data (radius) that younger systems (orbit, gravity,
## destruction) reference. Appearance comes from the child Surface + DamageSystem.
## There is no physics or rotation yet; that arrives in later phases.

@export var radius: float = 1.0


## Converts a planet-local position (origin at the planet centre) to world space.
func local_to_world(local: Vector3) -> Vector3:
	return global_position + local


## Converts a world position to the planet's local space (origin at the planet centre).
func world_to_local(world: Vector3) -> Vector3:
	return world - global_position
