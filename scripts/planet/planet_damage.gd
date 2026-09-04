extends Node3D
## Phase 4 planet damage system.
## Sits inside the planet scene. Builds an ImpactData into the persistent damage map, updates
## the crater shader, and raises the planet's damage state as thresholds are crossed.
## Presentation and simulation stay separate: this module ONLY owns the damage map + look; it
## never decides how a target was picked or a projectile flown.

signal planet_damaged(impact_position : Vector3, total_damage : float)
signal damage_state_changed(stage : int)

## Global damage at which the planet moves between damage states.
const STAGE_HEALTHY : int = 0
const STAGE_DAMAGED : int = 1
const STAGE_CRACKED : int = 2
const STAGE_CRITICAL : int = 3

const STAGE_THRESHOLDS : Array[float] = [1.0, 4.0, 10.0, 20.0]

const DAMAGE_UV_SCALE : float = 0.5
const DEFAULT_DAMAGE_RADIUS : float = 0.12

## Optional node that emits impact_applied(ImpactData) - e.g. the firing controller.
@export var impactor_path : NodePath
@export var surface_path : NodePath

var _surface : MeshInstance3D
var _map : DamageMap
var _material : ShaderMaterial
var _visual : Resource

var damage_total : float = 0.0
var stage : int = STAGE_HEALTHY


func _ready() -> void:
	_map = DamageMap.new()
	if not impactor_path.is_empty():
		var impactor := get_node_or_null(impactor_path)
		if impactor != null:
			impactor.impact_applied.connect(_on_impact_applied)
	_surface = get_node_or_null(surface_path) as MeshInstance3D
	_ensure_material()


## Receives ImpactData emitted by the firing controller and applies it to this planet.
func _on_impact_applied(impact : Resource) -> void:
	apply_damage(impact)


## Public: record one impact. `impact` is expected to be an ImpactData Resource. Returns total.
func apply_damage(impact : Resource) -> float:
	var strength : float = 1.0
	var radius : float = DEFAULT_DAMAGE_RADIUS
	var local_pos : Vector3 = Vector3.ZERO
	var world_pos : Vector3 = Vector3.ZERO
	if impact != null:
		strength = float(impact.get("strength"))
		radius = float(impact.get("radius"))
		local_pos = impact.get("local_position")
		world_pos = impact.get("world_position")
	if radius <= 0.0:
		radius = DEFAULT_DAMAGE_RADIUS
	var uv := _local_to_uv(local_pos)
	_map.add_damage(uv, radius, strength)
	_map.texture_update()
	_ensure_material()
	damage_total = _map.total_damage
	_update_stage()
	planet_damaged.emit(world_pos, damage_total)
	DebugLog.info("Planet damage now %.2f (stage %d)" % [damage_total, stage])
	return damage_total


## Converts a point on the planet (local space) to texture coordinates in (0..1).
func _local_to_uv(v : Vector3) -> Vector2:
	var d := clampf(v.length(), 0.001, 1.0)
	var lat := asin(clampf(v.y / d, -1.0, 1.0))
	var lon := atan2(v.z, v.x)
	var u : float = (lon / TAU + 0.5) * DAMAGE_UV_SCALE
	return Vector2(u, 0.5 + (lat / PI) * DAMAGE_UV_SCALE)


## Ensures the surface uses one cached crater material. Created once; later
## calls only refresh the damage texture, so data-driven visual params (Phase 5)
## survive impacts.
func _ensure_material() -> void:
	if _surface == null or _map == null:
		return
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = load("res://shaders/planet_damage.gdshader") as Shader
		_apply_visual_params()
		_surface.set_surface_override_material(0, _material)
	_material.set_shader_parameter("damage_tex", _map.texture)


## Phase 5: applies PlanetVisualSettings (from PlanetData) to the crater material.
func apply_visuals(visual : Resource) -> void:
	_visual = visual
	if _material != null:
		_apply_visual_params()


func _apply_visual_params() -> void:
	if _material == null or _visual == null:
		return
	_material.set_shader_parameter("base_color", _visual.get("base_color"))
	_material.set_shader_parameter("roughness", float(_visual.get("roughness")))
	_material.set_shader_parameter("ember_color", _visual.get("ember_color"))
	_material.set_shader_parameter("ember_strength", float(_visual.get("ember_strength")))
	_material.set_shader_parameter("wrinkle_strength", float(_visual.get("wrinkle_strength")))


func _update_stage() -> void:
	var s : int = 0
	for t in STAGE_THRESHOLDS:
		if damage_total >= t:
			s += 1
	if s > STAGE_CRITICAL:
		s = STAGE_CRITICAL
	if s != stage:
		stage = s
		damage_state_changed.emit(stage)