extends Control
## Fixed screen-centre crosshair, drawn with plain lines (no texture asset).
## Visible only in CROSSHAIR aim mode; the interaction coordinator toggles it.
## It is pure presentation: it owns no aim state and reads nothing.

@export var cross_color : Color = Color(0.9, 0.95, 1.0, 0.9)
@export var arm_length : float = 9.0
@export var gap : float = 4.0


func _draw() -> void:
	var c := size * 0.5
	draw_line(c + Vector2(-gap - arm_length, 0), c + Vector2(-gap, 0), cross_color, 2.0)
	draw_line(c + Vector2(gap, 0), c + Vector2(gap + arm_length, 0), cross_color, 2.0)
	draw_line(c + Vector2(0, -gap - arm_length), c + Vector2(0, -gap), cross_color, 2.0)
	draw_line(c + Vector2(0, gap), c + Vector2(0, gap + arm_length), cross_color, 2.0)
	draw_circle(c, 1.5, cross_color)