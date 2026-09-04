extends Node3D
## Root script for the main scene..
## Phase 0 (Godot Foundation): logs project startup..
##The planet, camera,and controls belong to later phases
##and are intentionally not created here yet..

const DebugLog := preload("res://scripts/debug/debug_log.gd")


func _ready() -> void:
	DebugLog.info("Main scene ready. Project booted successfully.")
