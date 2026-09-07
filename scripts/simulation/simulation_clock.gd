class_name SimulationClock
extends Node
## Phase 9: the sole authority for simulation time. Presentation and input
## always use real engine time; GravitySimulation asks this clock how much
## simulation time to accumulate and reports each completed fixed step back.

signal pause_changed(is_paused: bool)
signal speed_changed(multiplier: float)

const SPEEDS: Array[float] = [0.25, 0.5, 1.0, 2.0, 5.0, 10.0]

@export var speed_index: int = 2
var paused: bool = false
var elapsed_simulation_time: float = 0.0


func _ready() -> void:
	speed_index = clampi(speed_index, 0, SPEEDS.size() - 1)


func scaled_delta(real_delta: float) -> float:
	return 0.0 if paused else real_delta * get_speed_multiplier()


func advance(completed_simulation_delta: float) -> void:
	elapsed_simulation_time += completed_simulation_delta


func get_speed_multiplier() -> float:
	return SPEEDS[speed_index]


func toggle_pause() -> void:
	paused = not paused
	pause_changed.emit(paused)


func change_speed(direction: int) -> void:
	var old_index := speed_index
	speed_index = clampi(speed_index + signi(direction), 0, SPEEDS.size() - 1)
	if speed_index != old_index:
		speed_changed.emit(get_speed_multiplier())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_simulation_pause"):
		toggle_pause()
	elif event.is_action_pressed("simulation_speed_down"):
		change_speed(-1)
	elif event.is_action_pressed("simulation_speed_up"):
		change_speed(1)
