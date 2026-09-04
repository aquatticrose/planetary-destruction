extends Control
## Minimal overlay that verifies zoom/limits: shows the current camera distance plus a static
## control hint. Phase 1 (basic UI): no gameplay HUD yet,, that arrives in later phases..

@export var camera_path: NodePath
@export var planet_path: NodePath


var _camera: Camera3D
var _planet: Node3D

@onready var _info: Label = %InfoLabel


func _ready() -> void:
	_camera = get_node_or_null(camera_path) as Camera3D
	_planet = get_node_or_null(planet_path) as Node3D


func _process(_delta: float) -> void:
	if _camera == null or _planet == null:
		return
	var dist := _camera.global_position.distance_to(_planet.global_position)
	_info.text = "Camera distance: %.2f" % dist

