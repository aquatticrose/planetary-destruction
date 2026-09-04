extends Node3D
## Phase 3 revision: keyboard firing (Space) along the current aim direction.
## Pipeline: AimController (crosshair) -> this node -> FIRST surface intersection
## -> projectile flight -> ImpactData -> PlanetDamage.
## Responsibilities stay separated: this node never moves the crosshair and
## never edits damage state directly; it only emits ImpactData and spawns
## presentation effects (impact VFX + one sound per event).

signal impact_applied(impact : ImpactData)

@export var camera_path : NodePath
@export var planet_path : NodePath
@export var aim_path : NodePath
@export var projectile_scene : PackedScene
@export var impact_effect_scene : PackedScene
@export var shoot_bank_path : NodePath
@export var impact_bank_path : NodePath
## How far in front of the camera the projectile becomes visible.
@export var muzzle_offset : float = 0.6
## Ray length used to find the first surface intersection.
@export var max_shot_range : float = 100.0

var _camera : Camera3D
var _planet : Node3D
var _aim : Node3D
var _shoot_bank : Node
var _impact_bank : Node


func _ready() -> void:
	_camera = get_node_or_null(camera_path) as Camera3D
	_planet = get_node_or_null(planet_path)
	_aim = get_node_or_null(aim_path)
	_shoot_bank = get_node_or_null(shoot_bank_path)
	_impact_bank = get_node_or_null(impact_bank_path)


func _unhandled_input(event : InputEvent) -> void:
	if event.is_action_pressed("fire"):
		_fire()


## Fires along the camera->crosshair direction. The impact happens at the FIRST
## planet surface the shot path meets, so a projectile can never tunnel through
## the planet to reach a target on the far side.
func _fire() -> void:
	if _camera == null or _planet == null or _aim == null:
		DebugLog.warn("Firing is not wired (camera/planet/aim missing)")
		return
	var origin := _camera.global_position
	var dir : Vector3 = (_aim.get_aim_world() - origin).normalized()
	var hit := _first_surface_hit(origin, dir)
	if hit.is_empty():
		DebugLog.warn("Shot missed the planet (no surface intersection along aim)")
		return
	_play(_shoot_bank)
	var projectile := projectile_scene.instantiate() as Node3D
	add_child(projectile)
	projectile.launch(origin + dir * muzzle_offset, hit.position, hit.normal)
	projectile.impacted.connect(_on_projectile_impacted)


## Raycast from the camera along the shot direction against the planet collider.
func _first_surface_hit(origin : Vector3, dir : Vector3) -> Dictionary:
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, origin + dir * max_shot_range)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return space.intersect_ray(query)


## The projectile reached the pre-computed surface point: record the impact.
func _on_projectile_impacted(world_position : Vector3, world_normal : Vector3) -> void:
	_play(_impact_bank)
	_spawn_effect(world_position, world_normal)
	var impact := ImpactData.new()
	impact.world_position = world_position
	impact.local_position = _planet.world_to_local(world_position)
	impact.surface_normal = world_normal
	impact.strength = 1.0
	impact_applied.emit(impact)
	DebugLog.info("Impact recorded at %s (local %s)" % [world_position, impact.local_position])


func _spawn_effect(world_position : Vector3, world_normal : Vector3) -> void:
	if impact_effect_scene == null:
		return
	var fx := impact_effect_scene.instantiate() as Node3D
	add_child(fx)
	fx.global_position = world_position
	if fx.has_method("play_impact"):
		fx.play_impact(world_normal)


## Exactly one sound per event, randomly selected by the bank.
func _play(bank : Node) -> void:
	if bank != null and bank.has_method("play_random"):
		bank.play_random()