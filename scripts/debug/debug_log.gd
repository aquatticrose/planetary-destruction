class_name DebugLog
## Tiny typed helper for consistent debug logging..
## Phase 0 (Godot Foundation): adds timestamped console logging,
## used for boot messages andre later debugging..


static func info(message: String) -> void:
	print("[%s] [INFO] %s" % [_now(), message])


static func warn(message: String) -> void:
	print("[%s] [WARN] %s" % [_now(), message])


static func error(message: String) -> void:
	printerr("[%s] [ERROR] %s" % [_now(), message])


static func _now() -> String:
	return Time.get_datetime_string_from_system()
