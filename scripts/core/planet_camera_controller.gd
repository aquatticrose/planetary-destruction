extends Camera3D
## Orbit-around-the-planet camera controller.
## Smooth orbit (WASD/Arrow keys) and Q/E zoom, with clamped limits that
## keep the camera from clipping the planet. The controller only reads the
## planet's public radius; camera logic stays separate from planet logic.

@export var target : Vector3 = Vector3.ZERO
@export var distance : float =	4.0
@export var planet_radius : float =	1.0
@export var min_distance : float =	2.2
@export var max_distance : float =	12.0
@export var min_pitch_deg : float =	-80.0
@export var max_pitch_deg : float =	80.0
@export var orbital_speed : float =	2.5
@export var zoom_speed : float =	1.15
## Q/E (held) zoom rate: exponential steps per second at full deflection.
@export var zoom_key_rate : float =	2.0
## Optional node path to the planet root, so the radius auto-derives from
## one source. If unset, `planet_radius` above is used directly.
@export var planet_path : NodePath

var _planet : Node3D
var yaw : float =	0.0
var pitch : float =	0.0


## Effective zoom limits, re-derived from the planet radius every frame so
## data-driven preset switching (Phase 5) re-clamps the camera instantly.
var _eff_min : float = 2.2
var _eff_max : float = 12.0


func _ready() -> void:
	if not planet_path.is_empty():
		_planet = get_node_or_null(planet_path) as Node3D
	_refresh_limits()
	distance = clampf(distance, _eff_min, _eff_max)
	_update_camera()


## Keeps min distance above the (current) surface and max sane; radius follows
## the active PlanetData preset.
func _refresh_limits() -> void:
	if _planet != null:
		planet_radius = float(_planet.get("radius"))
	_eff_min = maxf(min_distance, planet_radius + 1.2)
	_eff_max = maxf(max_distance, _eff_min + 0.5)


## When true (CROSSHAIR aim mode), WASD also orbits the camera, so aiming and
## viewing are one action: the screen-centre crosshair always shows the aim.
## Toggled by the interaction coordinator; arrows always orbit.
var wasd_enabled : bool = false

func _process(delta : float) -> void:
	_refresh_limits()
	var horizontal := Input.get_axis("orbit_left", "orbit_right")
	var vertical := Input.get_axis("orbit_down", "orbit_up")
	if wasd_enabled:
		horizontal += Input.get_axis("aim_left", "aim_right")
		vertical += Input.get_axis("aim_up", "aim_down")
	yaw += horizontal * orbital_speed * delta
	pitch += vertical * orbital_speed * delta
	pitch = clampf(pitch, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
	# Q/E zoom: held keys zoom smoothly (exponential), limits clamp in _update_camera.
	var zoom_dir := Input.get_axis("camera_zoom_out", "camera_zoom_in")
	if absf(zoom_dir) > 0.0:
		distance *= pow(zoom_speed, -zoom_dir * zoom_key_rate * delta)
	_update_camera()


func _update_camera() -> void:
	distance = clampf(distance, _eff_min, _eff_max)
	var cp := cos(pitch)
	var offset := distance * Vector3(cp * sin(yaw), sin(pitch), cp * cos(yaw))
	global_position = target + offset
	look_at(target, Vector3.UP)
