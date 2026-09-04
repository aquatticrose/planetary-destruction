extends Control
## Minimal overlay: shows camera distance, live target coordinates/normal, and the current
## interaction mode, so you can verify zoom, targeting and firing. Listens to Selector signals;
## targeting/firing never know this overlay exists.

const InteractionMode := preload("res://scripts/core/interaction_mode.gd")

@export var camera_path : NodePath
@export var planet_path : NodePath
@export var selector_path : NodePath
@export var coordinator_path : NodePath

var _camera : Camera3D
var _planet : Node3D
var _coordinator : Node

@onready var _info : Label = %InfoLabel
@onready var _target_info : Label = %TargetLabel
@onready var _mode : Label = %ModeLabel


func _ready() -> void:
	_camera = get_node_or_null(camera_path) as Camera3D
	_planet = get_node_or_null(planet_path) as Node3D
	_coordinator = get_node_or_null(coordinator_path)
	var selector := get_node_or_null(selector_path) as Node
	if selector != null:
		selector.target_selected.connect(_on_target_selected)
		selector.target_cleared.connect(_on_target_cleared)


func _process(_delta : float) -> void:
	if _coordinator != null:
		_mode.text = _mode_name(int(_coordinator.current_mode))
	if _camera == null or _planet == null:
		return
	var dist := _camera.global_position.distance_to(_planet.global_position)
	_info.text = "Camera distance: %.2f" % dist


func _on_target_selected(world_position : Vector3, local_position : Vector3, surface_normal : Vector3) -> void:
	_target_info.text = "Local: (%.2f,%.2f,%.2f)\nNormal: (%.2f,%.2f,%.2f)" % [local_position.x, local_position.y, local_position.z, surface_normal.x, surface_normal.y, surface_normal.z]


func _on_target_cleared() -> void:
	_target_info.text = "Target: none"


func _mode_name(mode : int) -> String:
	match mode:
		InteractionMode.Mode.ORBIT:
			return "Orbit"
		InteractionMode.Mode.TARGETING:
			return "Targeting"
		InteractionMode.Mode.FIRING:
			return "Firing"
		_:
			return "Unknown"