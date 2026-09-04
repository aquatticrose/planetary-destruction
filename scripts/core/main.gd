extends Node3D
## Root script for the main scene..
## Phase 0: logs project startup. Phase 1 wires up the planet, sun, orbit
## camera and a basic UI overlay.each subsystem lives in its own script(full planet/,
## core/, ui/)..

func _ready() -> void:
	DebugLog.info("Main scene ready. Project booted successfully.")
