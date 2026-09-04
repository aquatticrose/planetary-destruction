extends Node3D
## Phase 2 targeting: converts a left-click into a 3D point on the planet surface.
## A physics ray is cast from the camera through the mouse; the hit is converted to local
## coordinates and a marker is glued to the surface. Selects only apply in TARGETING mode.
## Targeting only emits signals; the overlay listens. No simulation physics/gravity/destruction.

const InteractionMode := preload("res://scripts/core/interaction_mode.gd")

signal target_selected(world_position : Vector3, local_position : Vector3, surface_normal : Vector3)
signal target_cleared()

const CAST_DISTANCE : float = 100.0

@export var planet_path : NodePath
@export var camera_path : NodePath
@export var marker_path : NodePath
@export var coordinator_path : NodePath

var _planet : Node3D
var _camera : Camera3D
var _marker : MeshInstance3D
var _coordinator : Node

## Public state other systems (firing) read to know where the target is.
var has_target : bool = false
var target_position : Vector3 = Vector3.ZERO


func _ready() -> void:
	_planet = get_node_or_null(planet_path) as Node3D
	_camera = get_node_or_null(camera_path) as Camera3D
	_marker = get_node_or_null(marker_path) as MeshInstance3D
	_coordinator = get_node_or_null(coordinator_path)


func _input(event : InputEvent) -> void:
	if event.is_action_pressed("select") and _is_targeting_mode():
		_handle_select()
		get_viewport().set_input_as_handled()


func _is_targeting_mode() -> bool:
	return _coordinator != null and _coordinator.current_mode == InteractionMode.Mode.TARGETING


func _handle_select() -> void:
	if _camera == null or _planet == null or _marker == null:
		return
	var mouse_pos := get_viewport().get_mouse_position()
	var from := _camera.project_ray_origin(mouse_pos)
	var direction := _camera.project_ray_normal(mouse_pos)
	var to := from + direction * CAST_DISTANCE
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		_marker.visible = false
		has_target = false
		target_position = Vector3.ZERO
		target_cleared.emit()
		DebugLog.info("Target cleared (empty space)")
		return
	var world_position : Vector3 = result["position"]
	var surface_normal : Vector3 = result["normal"]
	var local_position : Vector3 = _planet.world_to_local(world_position)
	_marker.global_position = world_position
	_marker.visible = true
	has_target = true
	target_position = world_position
	target_selected.emit(world_position, local_position, surface_normal)
	DebugLog.info("Target: world=%s local=%s normal=%s" % [world_position, local_position, surface_normal])
