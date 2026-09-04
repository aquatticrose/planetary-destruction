extends Control
## Minimal overlay: shows camera distance, live target coordinates/normal, the current
## interaction mode, and the planet's damage state, so you can verify zoom/targeting/firing
## and the Phase-4 damage system. Listens to Selector + DamageSystem signals; those systems
## never know this overlay exists.

const InteractionMode := preload("res://scripts/core/interaction_mode.gd")

@export var camera_path : NodePath
@export var planet_path : NodePath
@export var selector_path : NodePath
@export var coordinator_path : NodePath
@export var damage_path : NodePath

var _camera : Camera3D
var _planet : Node3D
var _coordinator : Node
var _damage : Node
var _last_damage : float = 0.0
var _last_stage : int = 0

@onready var _info : Label = %InfoLabel
@onready var _target_info : Label = %TargetLabel
@onready var _mode : Label = %ModeLabel
@onready var _damage_info : Label = %DamageLabel


func _ready() -> void:
	_camera = get_node_or_null(camera_path) as Camera3D
	_planet = get_node_or_null(planet_path) as Node3D
	_coordinator = get_node_or_null(coordinator_path)
	_damage = get_node_or_null(damage_path)
	var selector := get_node_or_null(selector_path) as Node
	if selector != null:
		selector.target_selected.connect(_on_target_selected)
		selector.target_cleared.connect(_on_target_cleared)
	if _damage != null:
		_damage.planet_damaged.connect(_on_damaged)
		_damage.damage_state_changed.connect(_on_stage_changed)


func _process(_delta : float) -> void:
	if _coordinator != null:
		_mode.text = _mode_name(int(_coordinator.current_mode))
	_damage_info.text = "Damage: %.2f  Stage: %s" % [_last_damage, _stage_name(_last_stage)]
	if _camera == null or _planet == null:
		return
	var dist := _camera.global_position.distance_to(_planet.global_position)
	_info.text = "Camera distance: %.2f" % dist


func _on_damaged(_pos : Vector3, total : float) -> void:
	_last_damage = total


func _on_stage_changed(stage : int) -> void:
	_last_stage = stage


func _on_target_selected(_world_position : Vector3, local_position : Vector3, surface_normal : Vector3) -> void:
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


func _stage_name(stage : int) -> String:
	match stage:
		0:
			return "Healthy"
		1:
			return "Damaged"
		2:
			return "Cracked"
		3:
			return "Critical"
		_:
			return "Unknown"