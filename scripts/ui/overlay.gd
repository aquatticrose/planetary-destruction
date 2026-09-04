extends Control
## Minimal overlay:shows camera distance plus live target coordinates/normal,so you can
## verify Phase 1 zoom and Phase 2 targeting. Listens to signals emitted by the Selector
## node(targeting) - targeting never knows this overlay exists.,

@export var camera_path : NodePath
@export var planet_path : NodePath
@export var selector_path : NodePath

var _camera : Camera3D
var _planet : Node3D

@onready var _info : Label = %InfoLabel
@onready var _target_info : Label = %TargetLabel


func _ready() -> void:
	_camera = get_node_or_null(camera_path) as Camera3D
	_planet = get_node_or_null(planet_path) as Node3D
	var selector := get_node_or_null(selector_path) as Node
	if selector != null:
		selector.target_selected.connect(_on_target_selected)
		selector.target_cleared.connect(_on_target_cleared)


func _process(_delta : float) -> void:
	if _camera == null or _planet == null:
		return
	var dist := _camera.global_position.distance_to(_planet.global_position)
	_info.text ="Camera distance: %.2f" % dist


func _on_target_selected(world_position : Vector3, local_position: Vector3, surface_normal: Vector3) -> void:
	_target_info.text ="Local: (%.2f,%.2f,%.2f)\nNormal:(%.2f,%.2f,%.2f)" % [local_position.x, local_position.y, local_position.z, surface_normal.x, surface_normal.y, surface_normal.z]


func _on_target_cleared() -> void:
	_target_info.text ="Target: none"
