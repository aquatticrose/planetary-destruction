extends Control
## Debug/HUD overlay. Pure presentation: it polls the systems it watches and
## updates its labels every frame. It owns no interaction logic and listens to
## no game signals - everything it shows is read from exported node paths.

@export var camera_path : NodePath
@export var planet_path : NodePath
@export var aim_path : NodePath
@export var coordinator_path : NodePath
@export var damage_path : NodePath
## Phase 5: preset selector, for the planet-name readout.
@export var selector_path : NodePath

const MODE_NAMES : Array[String] = ["Crosshair", "Targeting"]
const STAGE_NAMES : Array[String] = ["Healthy", "Damaged", "Cracked", "Critical"]

@onready var _mode_label : Label = %ModeLabel
@onready var _info_label : Label = %InfoLabel
@onready var _aim_label : Label = %TargetLabel
@onready var _damage_label : Label = %DamageLabel
@onready var _preset_label : Label = %PresetLabel

var _camera : Camera3D
var _planet : Node3D
var _aim : Node3D
var _coordinator : Node
var _damage : Node
var _selector : Node


func _ready() -> void:
	_camera = get_node_or_null(camera_path) as Camera3D
	_planet = get_node_or_null(planet_path)
	_aim = get_node_or_null(aim_path)
	_coordinator = get_node_or_null(coordinator_path)
	_damage = get_node_or_null(damage_path)
	_selector = get_node_or_null(selector_path)


func _process(_delta : float) -> void:
	if _camera != null and _planet != null:
		var dist := _camera.global_position.distance_to(_planet.global_position)
		_info_label.text = "Camera distance: %.2f" % dist
	if _coordinator != null and _coordinator.has_method("get_mode"):
		_mode_label.text = "Mode: %s" % _mode_name(_coordinator.get_mode())
	if _aim != null and _planet != null and _aim.has_method("get_aim_world"):
		var local : Vector3 = _planet.world_to_local(_aim.get_aim_world())
		_aim_label.text = "Aim local: (%.2f, %.2f, %.2f)" % [local.x, local.y, local.z]
	if _damage != null:
		var stage := int(_damage.get("stage"))
		var total := float(_damage.get("damage_total"))
		var stage_name : String = STAGE_NAMES[clampi(stage, 0, STAGE_NAMES.size() - 1)]
		_damage_label.text = "Damage: %.2f  Stage: %s" % [total, stage_name]
	if _selector != null:
		var idx : int = _selector.get("current_index")
		var presets : Array = _selector.get("presets")
		if idx >= 0 and idx < presets.size():
			var pdata : Resource = presets[idx]
			_preset_label.text = "Planet: %s (%d/%d)" % [pdata.get("display_name"), idx + 1, presets.size()]


func _mode_name(mode : int) -> String:
	if mode >= 0 and mode < MODE_NAMES.size():
		return MODE_NAMES[mode]
	return "?"