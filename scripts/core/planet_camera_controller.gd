extends Camera3D
## Orbit-around-the-planet camera controller..
## Phase 1: smooth orbit(WASD/Arrow keys)and mouse-wheel zoom, with clamped
## limitsthatkeep the camera from clipping the planet. The controller only reads the planet's
## public radius;; camera logic stays separate from planet logic..

@export var target : Vector3 = Vector3.ZERO
@export var distance : float =	4.0
@export var planet_radius : float =	1.0
@export var min_distance : float =	2.2
@export var max_distance : float =	12.0
@export var min_pitch_deg : float =	-80.0
@export var max_pitch_deg : float =	80.0
@export var orbital_speed : float =	2.5
@export var zoom_speed : float =	1.15
## Optional node path to the planet root,, so the radius auto-derives from one source..
## If unset, `planet_radius` above is used directly..
@export var planet_path : NodePath

var _planet : Node3D
var yaw : float =	0.0
var pitch : float =	0.0


func _ready() -> void:
	if not planet_path.is_empty():
		_planet = get_node_or_null(planet_path) as Node3D
		if _planet != null:
			planet_radius = float(_planet.get("radius"))
	## Keep the zooming base level above the surface and sane upper bound..
	min_distance = max(min_distance, planet_radius +	1.2)
	max_distance = max(max_distance, min_distance +	0.5)
	distance = clampf(distance, min_distance, max_distance)
	_update_camera()


func _process(delta : float) -> void:
	var horizontal := Input.get_axis("orbit_left", "orbit_right")
	var vertical := Input.get_axis("orbit_down", "orbit_up")
	yaw -= horizontal * orbital_speed * delta
	pitch += vertical * orbital_speed * delta
	pitch = clampf(pitch, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
	_update_camera()


func _input(event : InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance /= zoom_speed
			_update_camera()
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance *= zoom_speed
			_update_camera()
			get_viewport().set_input_as_handled()


func _update_camera() -> void:
	distance = clampf(distance, min_distance, max_distance)
	var cp := cos(pitch)
	var offset := distance * Vector3(cp * sin(yaw), sin(pitch), cp * cos(yaw))
	global_position = target + offset
	look_at(target, Vector3.UP)
