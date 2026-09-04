extends Node3D
## Minimal interaction coordinator.
## Owns the current InteractionMode and routes the one genuinely modal thing:
## which aim system is active and what WASD means.
##  - CROSSHAIR (default): fixed crosshair at screen centre; WASD orbits the
##    camera to aim; Space fires along the view direction.
##  - TARGETING (Phase 2/3): LMB places the target marker, WASD slides it,
##    Space fires at it.
## T toggles between the modes; ESC resets to the default mode.

const InteractionMode := preload("res://scripts/core/interaction_mode.gd")

signal mode_changed(new_mode : int)

@export var aim_path : NodePath
## Camera gets WASD orbit only in CROSSHAIR mode (there, aiming = orbiting).
@export var camera_path : NodePath
## Screen-centre crosshair UI, visible only in CROSSHAIR mode.
@export var crosshair_ui_path : NodePath

var current_mode : int = InteractionMode.DEFAULT_MODE


func _ready() -> void:
	_apply_mode(current_mode)


func _unhandled_input(event : InputEvent) -> void:
	if event.is_action_pressed("toggle_aim_mode"):
		if current_mode == InteractionMode.Mode.CROSSHAIR:
			set_mode(InteractionMode.Mode.TARGETING)
		else:
			set_mode(InteractionMode.Mode.CROSSHAIR)
	elif event.is_action_pressed("ui_cancel"):
		reset_interaction()


func set_mode(mode : int) -> void:
	if mode == current_mode:
		return
	current_mode = mode
	_apply_mode(mode)


## Applies the modal side effects: camera WASD orbit flag and crosshair UI
## visibility. The aim controller polls the mode itself each frame.
func _apply_mode(mode : int) -> void:
	var camera := get_node_or_null(camera_path)
	if camera != null:
		camera.set("wasd_enabled", mode == InteractionMode.Mode.CROSSHAIR)
	var crosshair_ui := get_node_or_null(crosshair_ui_path)
	if crosshair_ui != null:
		crosshair_ui.set("visible", mode == InteractionMode.Mode.CROSSHAIR)
	mode_changed.emit(mode)


## ESC: cancel the current action, re-centre the aim and return to the default.
func reset_interaction() -> void:
	current_mode = InteractionMode.DEFAULT_MODE
	var aim := get_node_or_null(aim_path)
	if aim != null and aim.has_method("reset_aim"):
		aim.reset_aim()
	_apply_mode(current_mode)
	DebugLog.info("Interaction reset (mode Crosshair)")


func get_mode() -> int:
	return current_mode