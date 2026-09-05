class_name GravitySimulation
extends Node
## Phase 7-8: Newtonian N-body gravity. Every physics tick, each
## CelestialBody attracts every other body (a = G * M / r^2 with softening),
## and the resulting accelerations integrate motion with the Velocity Verlet
## scheme. Overlapping bodies merge into the more massive one.
##
## Phase 8 upgrade: switched from semi-implicit Euler to Velocity Verlet
## (position, then recompute acceleration, then velocity). Verlet is symplectic,
## so orbital energy is conserved over long runs instead of drifting. A fixed-
## timestep accumulator decouples the simulation from the render frame rate for
## deterministic, reproducible orbits.
##
## SCALING NOTE: the pairwise loop is O(n^2). Intentional and fine for the
## small body counts of Phases 7-8. When Phase 10-11 introduces fragments/debris
## (potentially hundreds of bodies), this must be revisited — e.g. spatial
## bucketing, a Barnes-Hut approximation, or culling negligible masses — before
## it becomes a bottleneck. Do NOT optimise prematurely for the current scale.

@export var enabled : bool = true
## Gameplay-scaled gravitational constant (mass in Earth masses, distance in
## scene units). Tuned so test bodies fall visibly fast at radius ~3-6.
@export var gravity_constant : float = 10.0
## Softening epsilon squared: prevents infinite forces at tiny separations.
## Documented here as a deliberate close-encounter regularizer. At orbital
## distances (r >> eps) it has negligible effect on the force law.
@export var softening : float = 0.05
## Fixed simulation timestep (seconds). The accumulator steps the simulation
## at this constant rate regardless of render frame rate for deterministic orbits.
@export var fixed_timestep : float = 1.0 / 120.0
## Max simulation steps processed per render frame (spiral-of-death guard).
@export var max_steps_per_frame : int = 8
## Merge overlapping bodies into the more massive one.
@export var merge_on_collision : bool = true
## Debug: draw gravity vectors + log force values (toggled with G in game).
@export var debug_enabled : bool = false
@export var debug_log_interval : float = 1.0

var _manager : Node
var _accumulator : float = 0.0
var _log_timer : float = 0.0


func _physics_process(delta : float) -> void:
	if _manager == null:
		_manager = get_tree().get_first_node_in_group(SimulationManager.GROUP_NAME)
		if _manager == null:
			return
	if not enabled:
		return
	# Accumulate render delta and advance the simulation in fixed steps so the
	# result is deterministic and independent of frame rate.
	_accumulator += delta
	var steps := 0
	while _accumulator >= fixed_timestep and steps < max_steps_per_frame:
		_step(fixed_timestep)
		_accumulator -= fixed_timestep
		steps += 1
	# Drop excess backlog to avoid a spiral of death after a long stall.
	if _accumulator > fixed_timestep * max_steps_per_frame:
		_accumulator = 0.0


## One fixed-timestep gravity tick using Velocity Verlet:
##   1) x(t+dt) = x(t) + v(t)*dt + 0.5*a(t)*dt^2
##   2) recompute a(t+dt) from the new positions
##   3) v(t+dt) = v(t) + 0.5*(a(t) + a(t+dt))*dt
## Acceleration is stored on each body (body.acceleration) so the integrator
## and diagnostics share one source of truth.
func _step(dt : float) -> void:
	var bodies : Array[CelestialBody] = _manager.get_bodies()
	if bodies.size() < 2:
		return
	# Save a(t) before recomputing: the Verlet kick needs the average of the old
	# and new accelerations.
	var old_accel : Dictionary = {}
	for body in bodies:
		if is_instance_valid(body):
			old_accel[body] = body.acceleration
	# 1) Drift: x(t+dt) = x(t) + v(t)*dt + 0.5*a(t)*dt^2
	for body in bodies:
		if is_instance_valid(body):
			body.global_position += body.velocity * dt + old_accel[body] * (0.5 * dt * dt)
	# 2) Recompute accelerations a(t+dt) from the new positions.
	_compute_accelerations(bodies)
	# 3) Kick: v(t+dt) = v(t) + 0.5*(a(t) + a(t+dt))*dt
	for body in bodies:
		if is_instance_valid(body):
			body.velocity += (old_accel[body] + body.acceleration) * (0.5 * dt)
	# 4) Collision checks: merge overlaps (also removes force singularities).
	if merge_on_collision:
		_resolve_collisions(bodies)
	# 5) Debug values.
	if debug_enabled:
		_debug_tick(dt)


## Pairwise gravitational acceleration: a = G * M / r^2 along the offset,
## with softening to bound the force at close range. Writes the result directly
## onto each body's `acceleration` (the previous value is overwritten, which is
## correct for Verlet step 2).
func _compute_accelerations(bodies : Array[CelestialBody]) -> void:
	for body in bodies:
		if is_instance_valid(body):
			body.acceleration = Vector3.ZERO
	for i in bodies.size():
		var a : CelestialBody = bodies[i]
		if not is_instance_valid(a):
			continue
		for j in range(i + 1, bodies.size()):
			var b : CelestialBody = bodies[j]
			if not is_instance_valid(b):
				continue
			var offset : Vector3 = b.global_position - a.global_position
			var r2 : float = maxf(offset.length_squared(), softening * softening)
			var inv_r : float = 1.0 / sqrt(r2)
			var dir := offset * inv_r
			# a = G * M / r^2 (force/mass folded; F = m*a for the debug readout).
			var a_accel := dir * (gravity_constant * b.mass * inv_r * inv_r)
			var b_accel := dir * (gravity_constant * a.mass * inv_r * inv_r)
			if is_instance_valid(a):
				a.acceleration += a_accel
			if is_instance_valid(b):
				b.acceleration -= b_accel


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
	if is_instance_valid(body):
		return body.acceleration
	return Vector3.ZERO


## Debug readout: force magnitude on a body (F = m * a).
func get_force(body : CelestialBody) -> float:
	if is_instance_valid(body):
		return body.mass * body.acceleration.length()
	return 0.0


func _debug_tick(dt : float) -> void:
	_log_timer += dt
	if _log_timer < debug_log_interval:
		return
	_log_timer = 0.0
	for body in _manager.get_bodies():
		if is_instance_valid(body):
			DebugLog.info("Gravity %s: a=%.3f  F=%.4f  v=%.3f" % [
					body.name, get_accel(body).length(), get_force(body), body.velocity.length()])