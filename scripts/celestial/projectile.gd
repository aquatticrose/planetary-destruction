extends Node3D
## Fake projectile for Phase 3: constant-speed travel to a target point, then "impact".
## No physics bodies - moved manually and removed on arrival. Emits impacted(point).

signal impacted(at : Vector3)

@export var speed : float = 6.0

var _target : Vector3 = Vector3.ZERO
var _impact_threshold : float = 0.15


func launch(from : Vector3, to : Vector3) -> void:
	global_position = from
	_target = to


func _process(delta : float) -> void:
	var to_target := _target - global_position
	var dist := to_target.length()
	if dist <= _impact_threshold:
		impacted.emit(global_position)
		queue_free()
		return
	var step := speed * delta
	global_position += to_target.normalized() * minf(step, dist)