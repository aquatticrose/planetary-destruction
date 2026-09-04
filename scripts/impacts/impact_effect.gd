extends Node3D
## Temporary Phase-3 impact effect: a short-lived dark "crater" mark pressed into the surface
## plus a one-shot particle burst. Self-removes after a short lifetime. Presentation-only.

const LIFETIME : float = 2.0

var _age : float = 0.0

@onready var _crater : MeshInstance3D = %Crater
@onready var _burst : GPUParticles3D = %Burst


func setup(world_position : Vector3, normal : Vector3) -> void:
	global_position = world_position + normal * 0.01
	_crater.look_at(global_position + normal, Vector3.UP if absf(normal.y) < 0.99 else Vector3.RIGHT)
	_burst.emitting = true


func _process(delta : float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	var t := _age / LIFETIME
	_crater.scale = Vector3.ONE * (1.0 - 0.5 * t)