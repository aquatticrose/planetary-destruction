extends Node
## Phase 7: gameplay-friendly Newtonian gravity (NOT a scientific simulator).
## Every physics tick, each CelestialBody attracts every other body, the
## resulting acceleration integrates into velocity, and velocity into position
## (semi-implicit Euler). Overlapping bodies merge into the more massive one —
## that both answers the "collision checks" checklist item and keeps the
## simulation stable (no r -> 0 force singularity).
## Timestep stability: _physics_process runs on Godot's fixed physics tick
## (60 Hz); delta is additionally clamped so a hitch can never explode a step.

@export var enabled : bool = true
## Gameplay-scaled gravitational constant (mass in Earth masses, distance in
## scene units). Tuned so test bodies fall visibly fast at radius ~3-6.
@export var gravity_constant : float = 10.0
## Softening epsilon: prevents infinite forces at tiny separations.
@export var softening : float = 0.05
## Merge overlapping bodies into the more massive one.
@export var merge_on_collision : bool = true
## Debug: draw gravity vectors + log force values (toggled with G in game).
@export var debug_enabled : bool = false
@export var debug_log_interval : float = 1.0

var _manager : Node
var _accel : Dictionary = {}
var _log_timer : float = 0.0


func _physics_process(delta : float) -> void:
	if _manager == null:
		_manager = get_tree().get_first_node_in_group(SimulationManager.GROUP_NAME)
		if _manager == null:
			return
	if not enabled:
		return
	_step(minf(delta, 1.0 / 30.0))


## One fixed-timestep gravity tick: attract -> integrate -> collide -> debug.
func _step(dt : float) -> void:
	var bodies : Array[CelestialBody] = _manager.get_bodies()
	if bodies.size() < 2:
		return
	# 1) Gravitational attraction -> acceleration per body (pairwise, symmetric).
	var new_accel : Dictionary = {}
	for body in bodies:
		new_accel[body] = Vector3.ZERO
	for i in bodies.size():
		var a : CelestialBody = bodies[i]
		for j in range(i + 1, bodies.size()):
			var b : CelestialBody = bodies[j]
			var offset : Vector3 = b.global_position - a.global_position
			var r2 : float = maxf(offset.length_squared(), softening * softening)
			var inv_r : float = 1.0 / sqrt(r2)
			var dir := offset * inv_r
			# a = G * M / r^2 (force/mass folded; F = m*a for the debug readout).
			new_accel[a] += dir * (gravity_constant * b.mass * inv_r * inv_r)
			new_accel[b] -= dir * (gravity_constant * a.mass * inv_r * inv_r)
	_accel = new_accel
	# 2) Velocity integration (semi-implicit Euler) then position integration.
	for body in bodies:
		if is_instance_valid(body):
			body.velocity += _accel[body] * dt
			body.global_position += body.velocity * dt
	# 3) Collision checks: merge overlaps (also removes force singularities).
	if merge_on_collision:
		_resolve_collisions(bodies)
	# 4) Debug values.
	if debug_enabled:
		_debug_tick(dt)


func _resolve_collisions(bodies : Array[CelestialBody]) -> void:
	for i in bodies.size():
		var a : CelestialBody = bodies[i]
		if not is_instance_valid(a):
			continue
		for j in range(i + 1, bodies.size()):
			var b : CelestialBody = bodies[j]
			if not is_instance_valid(b):
				continue
			if a.global_position.distance_to(b.global_position) > a.radius + b.radius:
				continue
			var big : CelestialBody = a if a.mass >= b.mass else b
			var small : CelestialBody = b if a.mass >= b.mass else a
			_merge(big, small)
			return  # one merge per tick is plenty for a prototype


func _merge(big : CelestialBody, small : CelestialBody) -> void:
	var total_mass : float = big.mass + small.mass
	# Momentum-conserving velocity + centre-of-mass position.
	big.velocity = (big.velocity * big.mass + small.velocity * small.mass) / total_mass
	big.global_position = (big.global_position * big.mass + small.global_position * small.mass) / total_mass
	big.mass = total_mass
	# Volume-preserving radius growth.
	big.radius = pow(big.radius * big.radius * big.radius + small.radius * small.radius * small.radius, 1.0 / 3.0)
	# Planets rebuild mesh/collider from radius; bare bodies just carry the value.
	if big.has_method("_apply_size"):
		big.call("_apply_size")
	DebugLog.info("%s absorbed %s (mass %.3f, radius %.2f)" % [big.name, small.name, big.mass, big.radius])
	small.despawn()


func _unhandled_input(event : InputEvent) -> void:
	if event.is_action_pressed("toggle_gravity_debug"):
		debug_enabled = not debug_enabled
		DebugLog.info("Gravity debug %s" % ("ON" if debug_enabled else "OFF"))


## Debug readout: the gravity acceleration last computed for a body.
func get_accel(body : CelestialBody) -> Vector3:
	return _accel.get(body, Vector3.ZERO)


## Debug readout: force magnitude on a body (F = m * a).
func get_force(body : CelestialBody) -> float:
	return body.mass * get_accel(body).length()


func _debug_tick(dt : float) -> void:
	_log_timer += dt
	if _log_timer < debug_log_interval:
		return
	_log_timer = 0.0
	for body in _manager.get_bodies():
		if is_instance_valid(body):
			DebugLog.info("Gravity %s: a=%.3f  F=%.4f  v=%.3f" % [
					body.name, get_accel(body).length(), get_force(body), body.velocity.length()])