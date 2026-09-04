extends Node3D
## Minimal interaction coordinator: holds the current mode and routes the small set of
## interaction intents (Target vs Fire). Orbit/zoom are unaffected and stay in the camera.
## Deliberately NOT a full state machine - ESC resets to the default (TARGETING) mode.

const InteractionMode := preload("res://scripts/core/interaction_mode.gd")

signal mode_changed(mode : int)

var current_mode : int = InteractionMode.DEFAULT_MODE


func get_mode() -> int:
	return current_mode


func set_mode(mode : int) -> void:
	if current_mode == mode:
		return
	current_mode = mode
	mode_changed.emit(mode)


func _input(event : InputEvent) -> void:
	if event.is_action_pressed("toggle_fire_mode"):
		_toggle_fire_mode()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		set_mode(InteractionMode.DEFAULT_MODE)
		get_viewport().set_input_as_handled()


func _toggle_fire_mode() -> void:
	if current_mode == InteractionMode.Mode.FIRING:
		set_mode(InteractionMode.DEFAULT_MODE)
	else:
		set_mode(InteractionMode.Mode.FIRING)