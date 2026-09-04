class_name ImpactData
extends Resource
## Phase 4: data that fully describes a single impact on a planet.
## The firing controller builds one and hands it to the damage system (PlanetDamage).
## Kept as a plain Resource so it can be logged, tested, and later saved/replayed.

@export var strength : float = 1.0
@export var radius : float = 0.12
@export var world_position : Vector3 = Vector3.ZERO
@export var local_position : Vector3 = Vector3.ZERO
@export var surface_normal : Vector3 = Vector3.UP