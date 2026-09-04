extends Node3D
## Phase 3 revision: keyboard aiming instead of click-to-target.
## WASD continuously slides the crosshair over the planet surface, relative to
## the camera. The crosshair mesh lives inside the planet scene and always shows
## where the next shot will hit. This node owns ONLY aim state: it never fires
## and never touches the damage system.

@export var planet_path : NodePath
@export var camera_path : NodePath
## Crosshair mesh inside the planet scene (planet-local space).
@export var crosshair_path : NodePath
## Angular speed of the crosshair over the globe (radians/second).
@export var aim_speed : float = 1.6
## Keeps the crosshair slightly above the surface so it never z-fights.
@export var surface_offset : float = 1.02

var _planet : Node3D
var _camera : Camera3D
var _crosshair : Node3D
## Unit aim direction from the planet centre, in planet-local space.
var _aim_local : Vector3 = Vector3.FORWARD


func _ready() -> void:
	_planet = get_node_or_null(planet_path)
	_camera = get_node_or_null(camera_path) as Camera3D
	_crosshair = get_node_or_null(crosshair_path)
	# Deferred: the camera script positions itself in its own _ready, which runs
	# after this node's. Resetting later guarantees a valid camera position.
	call_deferred("reset_aim")


func _process(delta : float) -> void:
	var move := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if move != Vector2.ZERO:
		_move_aim(move, delta)
	_update_crosshair()


## WASD (via aim_* actions) rotates the aim direction over the sphere, using
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


func _world_aim_dir() -> Vector3:
	return (_planet.global_transform.basis * _aim_local).normalized()


func _update_crosshair() -> void:
	if _crosshair == null or _planet == null:
		return
	var radius := float(_planet.get("radius"))
	_crosshair.position = _aim_local * radius * surface_offset


## Public: world-space point the next shot would be aimed at.
func get_aim_world() -> Vector3:
	if _planet == null:
		return Vector3.ZERO
	var radius := float(_planet.get("radius"))
	return _planet.global_transform * (_aim_local * radius)


## Public: world-space surface normal at the current aim point.
func get_aim_normal_world() -> Vector3:
	return _world_aim_dir()


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
	_update_crosshair()