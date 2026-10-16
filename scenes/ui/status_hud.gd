class_name StatusHUD
extends PanelContainer

## 1:1 port of game-x0-moba #status-hud.
## Draws status/FPS + controls on a single canvas. Geometry, icon atlas,
## medium Outfit body glyphs, bold heading and monospace values are grouped
## to avoid separate StatusRow/FPSRow Label draw calls.
## Text is only reshaped/redrawn when its value changes (FPS sampled every 0.5s).

@onready var controls_view: Control = %ControlsView

var main_font: Font = null
var bold_font: Font = null
var mono_bold_font: Font = null
var _icons_atlas: Texture2D = null

var _status_text: String = "Pronto!"
var _fps_text: String = "60"
var _last_fps: int = -1

const FONT_SIZE := 13
# Original VBox layout: two ~16px status rows + 5px spacing each.
const CONTROLS_TOP := 42.0
const SRC_MOUSE := Rect2(0, 0, 16, 16)
const SRC_KEYBOARD := Rect2(16, 0, 16, 16)
const BODY_COLOR := Color(0.6275, 0.6667, 0.7098, 1.0)
const GOLD_COLOR := Color(1.0, 0.847, 0.541, 1.0)

const CONTROL_ROWS: Array[Dictionary] = [
	{"icon": SRC_MOUSE, "text": "Clique Direito: Mover Caitlyn / Atacar Alvo"},
	{"icon": SRC_KEYBOARD, "text": "Tecla [X]: Ataque Direcional (Wild Rift)"},
	{"icon": SRC_KEYBOARD, "text": "Tecla [A] + Clique Esq: Attack Move (LoL)"},
	{"icon": SRC_KEYBOARD, "text": "Tecla [Y]: Alternar Trava de Câmera"},
	{"icon": SRC_KEYBOARD, "text": "[Space]: Recentrar Câmera no Campeão"},
	{"icon": SRC_MOUSE, "text": "Scroll: Zoom | MMB Drag: Arrastar Câmera"},
]

func _init() -> void:
	main_font = MobaFonts.outfit_medium()
	bold_font = MobaFonts.outfit_bold()
	mono_bold_font = MobaFonts.monospace_bold()
	if ResourceLoader.exists("res://assets/ui/icons/icons_atlas.png"):
		_icons_atlas = load("res://assets/ui/icons/icons_atlas.png")

func _ready() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(6.0 / 255.0, 12.0 / 255.0, 19.0 / 255.0, 0.85)
	sb.border_color = Color(194.0 / 255.0, 157.0 / 255.0, 83.0 / 255.0, 0.4)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 20
	sb.content_margin_top = 14
	sb.content_margin_right = 20
	sb.content_margin_bottom = 14
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 15
	sb.shadow_offset = Vector2(0, 8)
	add_theme_stylebox_override("panel", sb)

	if controls_view:
		controls_view.draw.connect(_on_controls_view_draw)
		controls_view.queue_redraw()

func _on_controls_view_draw() -> void:
	if not controls_view:
		return

	# One filled quad instead of PRIMITIVE_LINES for the gold divider.
	controls_view.draw_rect(
		Rect2(0.0, CONTROLS_TOP + 3.0, controls_view.size.x, 1.0),
		Color(0.7608, 0.6157, 0.3255, 0.3)
	)

	# Pass 1: all mouse/keyboard icons share one atlas.
	if _icons_atlas:
		for i in range(CONTROL_ROWS.size()):
			var ry: float = CONTROLS_TOP + 33.0 + float(i * 23)
			controls_view.draw_texture_rect_region(
				_icons_atlas,
				Rect2(0.0, ry + 1.0, 16.0, 16.0),
				CONTROL_ROWS[i].icon
			)

	# Pass 2: medium Outfit body text (static labels and control descriptions).
	if main_font:
		var ascent_med := main_font.get_ascent(FONT_SIZE)
		controls_view.draw_string(main_font, Vector2(0.0, ascent_med), "Status: ", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, BODY_COLOR)
		controls_view.draw_string(main_font, Vector2(0.0, 21.0 + ascent_med), "FPS: ", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, BODY_COLOR)
		for i in range(CONTROL_ROWS.size()):
			var ry: float = CONTROLS_TOP + 33.0 + float(i * 23)
			controls_view.draw_string(
				main_font,
				Vector2(23.0, ry + ascent_med + 1.0),
				CONTROL_ROWS[i].text,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				FONT_SIZE,
				BODY_COLOR
			)

	# Pass 3: bold Outfit heading.
	if bold_font:
		controls_view.draw_string(
			bold_font,
			Vector2(0.0, CONTROLS_TOP + 10.0 + bold_font.get_ascent(FONT_SIZE)),
			"Controles:",
			HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, GOLD_COLOR
		)

	# Pass 4: changing values use the original monospace bold font.
	if mono_bold_font and main_font:
		var ascent_mono := mono_bold_font.get_ascent(FONT_SIZE)
		var status_x := main_font.get_string_size("Status: ", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		var fps_x := main_font.get_string_size("FPS: ", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		controls_view.draw_string(mono_bold_font, Vector2(status_x, ascent_mono), _status_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, GOLD_COLOR)
		controls_view.draw_string(mono_bold_font, Vector2(fps_x, 21.0 + ascent_mono), _fps_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, GOLD_COLOR)

func set_status(value: String) -> void:
	if _status_text == value:
		return
	_status_text = value
	if controls_view:
		controls_view.queue_redraw()

func set_fps(fps: int) -> void:
	if fps == _last_fps:
		return
	_last_fps = fps
	_fps_text = str(fps)
	if controls_view:
		controls_view.queue_redraw()
