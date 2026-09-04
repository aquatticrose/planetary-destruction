class_name DebugLog
## Tiny typed helper for consistent debug logging.
## Phase 0 (Godot Foundation): adds timestamped console logging,
## used for boot messages and later debugging.


static func info(message: String) -> void:
	print("[%s] [INFO] %s" % [DebugLog._now(), message])


static func warn(message: String) -> void:
	push_warning("[%s] [WARN] %s" % [DebugLog._now(), message])


static func error(message: String) -> void:
	push_error("[%s] [ERROR] %s" % [DebugLog._now(), message])


static func _now() -> String:
	return Time.get_datetime_string_from_system()
