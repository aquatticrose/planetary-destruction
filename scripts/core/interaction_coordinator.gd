extends Node3D
## Minimal interaction coordinator (Phase 3 revision).
## Owns the current InteractionMode and the ESC reset. Per-click routing is gone:
## aiming (WASD) and firing (Space) are always-on, keyboard-driven behaviours
## owned by AimController and FiringController. The mode enum is kept small and
## available so future modal interactions have a place to live.

const InteractionMode := preload("res://scripts/core/interaction_mode.gd")

signal mode_changed(new_mode : int)

## Aim controller to reset when the player presses ESC.
@export var aim_path : NodePath

var current_mode : int = InteractionMode.DEFAULT_MODE


func _ready() -> void:
	mode_changed.emit(current_mode)


func _unhandled_input(event : InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		reset_interaction()


## ESC: cancel the current action, re-centre the aim and return to the default mode.
func reset_interaction() -> void:
	current_mode = InteractionMode.DEFAULT_MODE
	var aim := get_node_or_null(aim_path)
	if aim != null and aim.has_method("reset_aim"):
		aim.reset_aim()
	mode_changed.emit(current_mode)
	DebugLog.info("Interaction reset (mode Targeting)")


func get_mode() -> int:
	return current_mode