extends Button
class_name FullscreenButton

## Circular Hextech Fullscreen button matching game-x0 #fullscreen-btn

const COLOR_GOLD := Color(1.0, 0.847, 0.541, 1.0) # #ffd88a
const COLOR_GOLD_BORDER := Color(0.7608, 0.6157, 0.3255, 0.6) # #c29d53
const COLOR_BG := Color(0.0392, 0.0784, 0.1176, 0.7) # rgba(10, 20, 30, 0.7)
const COLOR_BG_HOVER := Color(0.7608, 0.6157, 0.3255, 0.2)

func _ready() -> void:
	custom_minimum_size = Vector2(42, 42)
	size = Vector2(42, 42)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_NONE
	flat = true
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("""
		(function() {
			if (!document.fullscreenElement) {
				document.documentElement.requestFullscreen().catch(function(e){});
			} else {
				if (document.exitFullscreen) document.exitFullscreen();
			}
		})();
		""")
	else:
		var mode = DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - 1.5

	# Background circle
	var bg_col := COLOR_BG_HOVER if is_hovered() else COLOR_BG
	draw_circle(center, radius, bg_col)

	# Gold border
	draw_arc(center, radius, 0.0, TAU, 48, COLOR_GOLD_BORDER, 1.5, true)

	# Hextech fullscreen icon (4 outward-facing corners)
	var icon_color := COLOR_GOLD
	var line_w := 2.0
	var offset := 7.0
	var arm := 5.0

	var x_l := center.x - offset
	var x_r := center.x + offset
	var y_t := center.y - offset
	var y_b := center.y + offset

	# Top-Left corner: (x_l, y_t + arm) -> (x_l, y_t) -> (x_l + arm, y_t)
	draw_line(Vector2(x_l, y_t + arm), Vector2(x_l, y_t), icon_color, line_w, true)
	draw_line(Vector2(x_l, y_t), Vector2(x_l + arm, y_t), icon_color, line_w, true)

	# Top-Right corner: (x_r - arm, y_t) -> (x_r, y_t) -> (x_r, y_t + arm)
	draw_line(Vector2(x_r - arm, y_t), Vector2(x_r, y_t), icon_color, line_w, true)
	draw_line(Vector2(x_r, y_t), Vector2(x_r, y_t + arm), icon_color, line_w, true)

	# Bottom-Left corner: (x_l, y_b - arm) -> (x_l, y_b) -> (x_l + arm, y_b)
	draw_line(Vector2(x_l, y_b - arm), Vector2(x_l, y_b), icon_color, line_w, true)
	draw_line(Vector2(x_l, y_b), Vector2(x_l + arm, y_b), icon_color, line_w, true)

	# Bottom-Right corner: (x_r - arm, y_b) -> (x_r, y_b) -> (x_r, y_b - arm)
	draw_line(Vector2(x_r - arm, y_b), Vector2(x_r, y_b), icon_color, line_w, true)
	draw_line(Vector2(x_r, y_b), Vector2(x_r, y_b - arm), icon_color, line_w, true)
