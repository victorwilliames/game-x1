class_name StatusHUD
extends PanelContainer

## 1:1 Port of game-x0-moba #status-hud
## Dark translucent card (rgba(6, 12, 19, 0.85)) with gold border, Outfit 500/700, and monospace 700 spans.
## Controls rows are batched into 2 passes (all icons first, all text second) to reduce draw calls from 19 to ~7.

@onready var status_val: Label = %StatusVal
@onready var fps_val: Label = %FPSVal
@onready var controls_view: Control = %ControlsView

var main_font: Font = null
var bold_font: Font = null
var mono_bold_font: Font = null
var _last_fps: int = -1
var _icons_atlas: Texture2D = null

const SRC_MOUSE := Rect2(0, 0, 16, 16)
const SRC_KEYBOARD := Rect2(16, 0, 16, 16)

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
	# Configure card StyleBox matching #status-hud in style.css
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

	# Apply Outfit Medium (500) to body labels
	if main_font:
		_apply_style_recursive(self, main_font)

	# Apply monospace bold (700) to .hud-item span (#loading-status, #fps-counter)
	if mono_bold_font:
		if status_val:
			status_val.add_theme_font_override("font", mono_bold_font)
			status_val.add_theme_font_size_override("font_size", 13)
		if fps_val:
			fps_val.add_theme_font_override("font", mono_bold_font)
			fps_val.add_theme_font_size_override("font_size", 13)

	# Connect batched draw for ControlsView
	if controls_view:
		controls_view.draw.connect(_on_controls_view_draw)
		controls_view.queue_redraw()

func _apply_style_recursive(node: Node, font: Font) -> void:
	if node is Label:
		node.add_theme_font_override("font", font)
		node.add_theme_font_size_override("font_size", 13)
	for child in node.get_children():
		_apply_style_recursive(child, font)

func _on_controls_view_draw() -> void:
	if not controls_view:
		return

	# 1. Divider line matching style.css: border-top: 1px solid rgba(194, 157, 83, 0.3)
	controls_view.draw_line(Vector2(0, 3), Vector2(controls_view.size.x, 3), Color(0.7608, 0.6157, 0.3255, 0.3), 1.0)

	# 2. PASS 1: All icons from the single 32x16 atlas texture (1 single draw call!)
	if _icons_atlas:
		for i in range(CONTROL_ROWS.size()):
			var ry: float = 33.0 + float(i * 23)
			var dst := Rect2(0.0, ry + 1.0, 16.0, 16.0)
			controls_view.draw_texture_rect_region(_icons_atlas, dst, CONTROL_ROWS[i].icon)

	# 3. PASS 2: Header "Controles:" and all 6 control rows (batched font atlas pass)
	if bold_font:
		var ascent_bold := bold_font.get_ascent(13)
		controls_view.draw_string(bold_font, Vector2(0.0, 10.0 + ascent_bold), "Controles:", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.847, 0.541, 1.0))

	if main_font:
		var ascent_med := main_font.get_ascent(13)
		var text_color := Color(0.6275, 0.6667, 0.7098, 1.0)
		for i in range(CONTROL_ROWS.size()):
			var ry: float = 33.0 + float(i * 23)
			var text_pos := Vector2(23.0, ry + ascent_med + 1.0)
			controls_view.draw_string(main_font, text_pos, CONTROL_ROWS[i].text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, text_color)

func set_status(text: String) -> void:
	if status_val and status_val.text != text:
		status_val.text = text

func set_fps(fps: int) -> void:
	if fps != _last_fps and fps_val:
		_last_fps = fps
		fps_val.text = str(fps)
