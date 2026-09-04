extends Node3D
## Phase 5 sandbox: swap the planet's PlanetData preset at runtime with keys 1-5.
## Owns no planet behaviour — it only forwards a preset to Planet.apply_data().

@export var planet_path : NodePath
@export var presets : Array[PlanetData] = []

var current_index : int = -1
var _planet : Node3D


func _ready() -> void:
	_planet = get_node_or_null(planet_path)
	# Start the sandbox data-driven with the first preset.
	if not presets.is_empty():
		apply_preset(0)


func _unhandled_input(event : InputEvent) -> void:
	for i in presets.size():
		if event.is_action_pressed("preset_%d" % (i + 1)):
			apply_preset(i)
			return


func apply_preset(index : int) -> void:
	if index < 0 or index >= presets.size() or _planet == null:
		return
	var preset := presets[index]
	if _planet.has_method("apply_data"):
		_planet.apply_data(preset)
	current_index = index
	DebugLog.info("Preset applied: %s" % preset.display_name)