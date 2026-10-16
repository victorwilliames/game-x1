class_name StatusHUD
extends PanelContainer

## 1:1 Port of game-x0-moba #status-hud
## Dark translucent card (rgba(6, 12, 19, 0.85)) with gold border, Outfit 500/700, and monospace 700 spans.

@onready var status_val: Label = %StatusVal
@onready var fps_val: Label = %FPSVal
@onready var controls_header: Label = %ControlsHeader

var main_font: Font = null
var bold_font: Font = null
var mono_bold_font: Font = null
var _last_fps: int = -1

func _init() -> void:
	main_font = MobaFonts.outfit_medium()
	bold_font = MobaFonts.outfit_bold()
	mono_bold_font = MobaFonts.monospace_bold()

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

	# Apply Outfit Medium (500) to body labels and crisp nearest filter to icons
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

	# Apply Outfit Bold (700) to Controles header
	if bold_font and controls_header:
		controls_header.add_theme_font_override("font", bold_font)
		controls_header.add_theme_font_size_override("font_size", 13)

func _apply_style_recursive(node: Node, font: Font) -> void:
	if node is Label:
		node.add_theme_font_override("font", font)
		node.add_theme_font_size_override("font_size", 13)
	elif node is TextureRect:
		node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for child in node.get_children():
		_apply_style_recursive(child, font)

func set_status(text: String) -> void:
	if status_val and status_val.text != text:
		status_val.text = text

func set_fps(fps: int) -> void:
	if fps != _last_fps and fps_val:
		_last_fps = fps
		fps_val.text = str(fps)
