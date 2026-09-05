class_name TrajectoryTrail
extends Node3D
## TrajectoryTrail: records a body's actual world positions and draws them as a
## line strip. This is NOT a pre-baked orbit path — it shows where the body has
## really been, so it directly visualises the simulated trajectory (circular,
## elliptical, escaping, decaying — whatever physics produces).

@export var target_path : NodePath
## Seconds between recorded samples.
@export var sample_interval : float = 0.05
## Maximum number of points kept (oldest discarded).
@export var max_points : int = 600
@export var trail_color : Color = Color(0.4, 0.8, 1.0, 0.85)
## If true, the trail is drawn in world space (independent of this node's
## transform), which is what we want for an orbit around a moving parent.
@export var world_space : bool = true

var _target : Node3D
var _points : PackedVector3Array
var _mesh : ImmediateMesh
var _instance : MeshInstance3D
var _sample_timer : float = 0.0
var _last_pos : Vector3
var _has_last : bool = false


func _ready() -> void:
	_target = get_node_or_null(target_path) as Node3D
	_mesh = ImmediateMesh.new()
	_instance = MeshInstance3D.new()
	_instance.mesh = _mesh
	_instance.top_level = world_space
	add_child(_instance)
	set_process(_target != null)


func _process(_delta : float) -> void:
	if _target == null:
		return
	_sample_timer += _delta
	var pos := _target.global_position
	if _sample_timer >= sample_interval or not _has_last:
		_append_point(pos)
		_sample_timer = 0.0
		_has_last = true
	_last_pos = pos
	_redraw()


func _append_point(pos : Vector3) -> void:
	_points.append(pos)
	if _points.size() > max_points:
		_points.remove_at(0)


func _redraw() -> void:
	_mesh.clear_surfaces()
	if _points.size() < 2:
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	_mesh.surface_set_color(trail_color)
	for p in _points:
		_mesh.surface_add_vertex(p)
	_mesh.surface_end()


## Clears the recorded trail (e.g. after a manual orbit edit).
func clear_trail() -> void:
	_points.clear()
	_has_last = false
	_mesh.clear_surfaces()