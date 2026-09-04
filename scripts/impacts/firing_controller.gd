extends Node3D
## Phase 3 firing: in FIRING mode a left-click launches a fake projectile from the camera
## toward the currently-targeted surface point. On impact it records the world position and
## spawns a temporary impact effect (crater + particle burst). Also emits an ImpactData for
## systems that own persistent damage (the planet's DamageSystem) without poking them directly.

const InteractionMode := preload("res://scripts/core/interaction_mode.gd")

signal impact_applied(impact : Resource)

@export var camera_path : NodePath
@export var selector_path : NodePath
@export var planet_path : NodePath
@export var coordinator_path : NodePath
@export var projectile_scene : PackedScene
@export var impact_effect_scene : PackedScene
@export var sound_bank_path : NodePath

var _camera : Camera3D
var _selector : Node
var _planet : Node3D
var _coordinator : Node
var _sound_bank : Node
var _recorded_impacts : Array[Vector3] = []


func _ready() -> void:
	_camera = get_node_or_null(camera_path) as Camera3D
	_selector = get_node_or_null(selector_path)
	_planet = get_node_or_null(planet_path) as Node3D
	_coordinator = get_node_or_null(coordinator_path)
	_sound_bank = get_node_or_null(sound_bank_path)


func _input(event : InputEvent) -> void:
	if event.is_action_pressed("select") and _in_firing_mode():
		_fire()
		get_viewport().set_input_as_handled()


func _in_firing_mode() -> bool:
	return _coordinator != null and _coordinator.current_mode == InteractionMode.Mode.FIRING


func _fire() -> void:
	if _camera == null or _selector == null or _planet == null or projectile_scene == null:
		DebugLog.warn("Firing unavailable: missing references or projectile scene")
		return
	if not _selector.has_target:
		DebugLog.warn("Firing needs a target - pick a surface point first")
		return
	var from := _camera.global_position
	var to : Vector3 = _selector.target_position
	var proj := projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.launch(from, to)
	proj.impacted.connect(_on_impact)
	if _sound_bank != null:
		_sound_bank.play("shoot")
	DebugLog.info("Fired projectile from %s toward %s" % [from, to])


func _on_impact(at : Vector3) -> void:
	_recorded_impacts.append(at)
	if _sound_bank != null:
		_sound_bank.play("impact")
	DebugLog.info("Impact recorded at %s (total %d)" % [at, _recorded_impacts.size()])
	_spawn_impact_effect(at)
	if _planet != null:
		var impact := ImpactData.new()
		impact.world_position = at
		impact.local_position = _planet.world_to_local(at)
		impact.surface_normal = (at - _planet.global_position).normalized()
		impact_applied.emit(impact)


func _spawn_impact_effect(at : Vector3) -> void:
	if impact_effect_scene == null:
		return
	var normal := (at - _planet.global_position).normalized()
	var fx := impact_effect_scene.instantiate()
	get_tree().current_scene.add_child(fx)
	fx.setup(at, normal)