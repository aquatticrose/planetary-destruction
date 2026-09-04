extends Node3D
## Reusable planet node..
## Phase 1: holds the core planet data (radius) that younger systems (orbit, gravity,
## destruction) will reference. Appearance comes from the MeshInstance3D child. There is
## no physics or rotation yet;; that arrives in later phases..

@export var radius: float = 1.0

