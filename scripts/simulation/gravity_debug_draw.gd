extends Node3D
## Phase 7 debug visual: draws each body's gravity acceleration as a line from
## the body centre (ImmediateMesh, rebuilt per frame). Pure presentation — it
## owns no physics and only reads the accelerations GravitySimulation computed.
## Visibility follows the simulation's debug_enabled flag (G in game).

@export var gravity_sim_path : NodePath
@export var vector_scale : float = 0.6
@export var max_length : float = 4.0
@export var line_color : Color = Color(1.0, 0.45, 0.2, 0.9)

var _sim : Node
var _mesh : ImmediateMesh
var _instance : MeshInstance3D


func _ready() -> void:
	_sim = get_node_or_null(gravity_sim_path)
	_mesh = ImmediateMesh.new()
	_instance = MeshInstance3D.new()
	_instance.mesh = _mesh
	_instance.top_level = true  # draw in world space
	add_child(_instance)


func _process(_delta : float) -> void:
	_mesh.clear_surfaces()
	if _sim == null or not _sim.debug_enabled:
		return
	var manager : Node = get_tree().get_first_node_in_group(SimulationManager.GROUP_NAME)
	if manager == null:
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_mesh.surface_set_color(line_color)
	for body in manager.get_bodies():
		if not is_instance_valid(body):
			continue
		var accel : Vector3 = _sim.get_accel(body)
		if accel.length_squared() < 0.0001:
			continue
		var from : Vector3 = body.global_position
		var to : Vector3 = from + accel.normalized() * minf(accel.length() * vector_scale, max_length)
		_mesh.surface_add_vertex(from)
		_mesh.surface_add_vertex(to)
	_mesh.surface_end()