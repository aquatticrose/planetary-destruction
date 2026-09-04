extends Node3D
## Aim controller — the single owner of "where is the player aiming".
## Two modes, routed by InteractionCoordinator (interaction_mode.gd):
##  - CROSSHAIR (default): a fixed crosshair sits at the screen centre; every
##    frame a ray is cast from the camera through the screen centre onto the
##    planet and the 3D marker moves to that hit point. Aiming = orbiting.
##  - TARGETING (Phase 2/3): LMB on the planet places the marker, WASD slides
##    it over the globe (camera-relative), ESC resets it.
## This node owns ONLY aim state: it never fires and never touches damage.

const InteractionMode := preload("res://scripts/core/interaction_mode.gd")

@export var planet_path : NodePath
@export var camera_path : NodePath
## 3D marker mesh (planet-local space): crosshair point in CROSSHAIR mode,
## player-placed target in TARGETING mode.
@export var crosshair_path : NodePath
## Angular speed of the marker over the globe in TARGETING mode (rad/s).
@export var aim_speed : float = 1.6
## Keeps the marker slightly above the surface so it never z-fights.
@export var surface_offset : float = 1.02

var _planet : Node3D
var _camera : Camera3D
var _crosshair : Node3D
var _mode : int = InteractionMode.DEFAULT_MODE
## Unit aim direction from the planet centre, in planet-local space
## (TARGETING mode only; CROSSHAIR derives its point from a raycast).
var _aim_local : Vector3 = Vector3.FORWARD


func _ready() -> void:
	_planet = get_node_or_null(planet_path)
	_camera = get_node_or_null(camera_path) as Camera3D
	_crosshair = get_node_or_null(crosshair_path)
	# Deferred: the camera script positions itself in its own _ready, which runs
	# after this node's. Resetting later guarantees a valid camera position.
	call_deferred("reset_aim")


func _process(_delta : float) -> void:
	match _mode:
		InteractionMode.Mode.CROSSHAIR:
			_crosshair_raycast()
		InteractionMode.Mode.TARGETING:
			var move := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
			if move != Vector2.ZERO:
				_move_aim(move, _delta)
	_update_crosshair_visual()


## Called by the interaction coordinator when the mode changes.
func set_mode(mode : int) -> void:
	_mode = mode
	if mode == InteractionMode.Mode.CROSSHAIR:
		reset_aim()


## CROSSHAIR mode: cast from the camera through the exact screen centre and
## place the marker at the first planet hit. Missing the planet keeps the last
## valid point (the crosshair simply sits over space).
func _crosshair_raycast() -> void:
	if _planet == null or _camera == null:
		return
	var from := _camera.global_position
	var to := _camera.project_ray_normal(_camera.get_viewport().get_visible_rect().size * 0.5) * 100.0 + from
	var space := _camera.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return
	var collider : Object = hit.get("collider")
	if collider == null or not _planet.is_ancestor_of(collider):
		return
	var world_point : Vector3 = hit.get("position")
	# Store the hit as the aim direction so firing targets THIS point.
	_aim_local = (world_point - _planet.global_position).normalized()
	_update_crosshair_visual(world_point)


## TARGETING mode: WASD rotates the aim direction over the sphere, using
## camera-relative tangent axes so "right" always means screen-right.
func _move_aim(move : Vector2, delta : float) -> void:
	if _planet == null or _camera == null:
		return
	var normal := _world_aim_dir()
	if normal.length_squared() < 0.5:
		# Aim not initialised yet (e.g. camera still at the origin).
		reset_aim()
		return
	var cam_right := _camera.global_transform.basis.x
	var cam_up := _camera.global_transform.basis.y
	var tangent_right := cam_right - normal * normal.dot(cam_right)
	var tangent_up := cam_up - normal * normal.dot(cam_up)
	if tangent_right.length_squared() < 0.0001 or tangent_up.length_squared() < 0.0001:
		return
	var angle := aim_speed * delta
	var rotated := _world_aim_dir()
	rotated = rotated.rotated(tangent_up.normalized(), move.x * angle)
	rotated = rotated.rotated(tangent_right.normalized(), move.y * angle)
	rotated = rotated.normalized()
	# Keep the aim on the camera-facing hemisphere so the player never aims at
	# a point they cannot see (the far side would silently hit the near crust).
	var view := (_camera.global_position - _planet.global_position).normalized()
	if rotated.dot(view) > 0.05:
		_aim_local = (_planet.global_transform.basis.inverse() * rotated).normalized()


## Public: unit aim direction from the planet centre, in world space.
func _world_aim_dir() -> Vector3:
	return (_planet.global_transform.basis * _aim_local).normalized()


## Places the marker at a world surface point, lifted a hair along the normal
## so it never z-fights with the planet. Defaults to the current aim.
func _update_crosshair_visual(world_point : Vector3 = Vector3.INF) -> void:
	if _crosshair == null or _planet == null:
		return
	if world_point == Vector3.INF:
		world_point = get_aim_world()
	var normal := (world_point - _planet.global_position).normalized()
	_crosshair.global_position = world_point + normal * 0.02


## Public: world-space point the next shot would be aimed at.
func get_aim_world() -> Vector3:
	if _planet == null:
		return Vector3.ZERO
	var radius := float(_planet.get("radius"))
	return _planet.global_transform * (_aim_local * radius)


## Public: world-space surface normal at the current aim point.
func get_aim_normal_world() -> Vector3:
	return _world_aim_dir()


## Public: current aim point in planet-local space (unit radius direction).
func get_aim_local() -> Vector3:
	return _aim_local


## Public: re-centre the aim on the surface point closest to the camera.
func reset_aim() -> void:
	if _planet == null or _camera == null:
		_aim_local = Vector3.FORWARD
		return
	var dir := (_camera.global_position - _planet.global_position).normalized()
	if dir.length_squared() < 0.0001:
		# Camera sits exactly on the planet centre (not yet positioned).
		_aim_local = Vector3.FORWARD
		return
	_aim_local = (_planet.global_transform.basis.inverse() * dir).normalized()
	_update_crosshair_visual()