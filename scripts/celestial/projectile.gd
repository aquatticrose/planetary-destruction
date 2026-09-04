extends Node3D
## Fake prototype projectile (no physics body). It flies from its launch point
## to a PRE-COMPUTED first-surface intersection and then reports the impact.
## It can never pass through the planet because the impact point is fixed
## before launch by the firing controller's raycast.

signal impacted(world_position : Vector3, world_normal : Vector3)

@export var speed : float = 10.0

var _target : Vector3 = Vector3.ZERO
var _normal : Vector3 = Vector3.UP
var _travelling : bool = false


## Public: start the flight. `to` must be the first surface intersection along
## the shot path (already computed by the firing controller).
func launch(from : Vector3, to : Vector3, surface_normal : Vector3, flight_speed : float = 0.0) -> void:
	global_position = from
	_target = to
	_normal = surface_normal.normalized()
	if flight_speed > 0.0:
		speed = flight_speed
	if not to.is_equal_approx(from):
		var dir := (to - from).normalized()
		# look_at fails when the direction is parallel to the up vector.
		if absf(dir.dot(Vector3.UP)) < 0.999:
			look_at(to, Vector3.UP)
	_travelling = true


func _process(delta : float) -> void:
	if not _travelling:
		return
	var step := speed * delta
	var to_target := _target - global_position
	if to_target.length() <= step:
		global_position = _target
		_travelling = false
		impacted.emit(_target, _normal)
		queue_free()
	else:
		global_position += to_target.normalized() * step