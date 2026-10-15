class_name StatusHUD
extends PanelContainer

## 1:1 Port of game-x0-moba #status-hud
## Dark translucent card (rgba(6, 12, 19, 0.85)) with gold border and Outfit font.

@onready var status_val: Label = %StatusVal
@onready var fps_val: Label = %FPSVal
@onready var controls_header: Label = %ControlsHeader

var main_font: Font = null
var bold_font: Font = null

func _init() -> void:
	if ResourceLoader.exists("res://assets/fonts/Outfit-Variable.ttf"):
		var base_f := load("res://assets/fonts/Outfit-Variable.ttf") as FontFile
		if base_f:
			var var_normal := FontVariation.new()
			var_normal.base_font = base_f
			var_normal.variation_embolden = 0.15
			main_font = var_normal

			var var_bold := FontVariation.new()
			var_bold.base_font = base_f
			var_bold.variation_embolden = 0.45
			bold_font = var_bold

func _ready() -> void:
	# Configure card StyleBox
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
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 5)
	add_theme_stylebox_override("panel", sb)

	# Apply fonts recursively
	if main_font:
		_apply_font_recursive(self, main_font)

	# Apply bold font to header and values
	if bold_font:
		if status_val:
			status_val.add_theme_font_override("font", bold_font)
		if fps_val:
			fps_val.add_theme_font_override("font", bold_font)
		if controls_header:
			controls_header.add_theme_font_override("font", bold_font)

func _apply_font_recursive(node: Node, font: Font) -> void:
	if node is Label:
		node.add_theme_font_override("font", font)
		node.add_theme_font_size_override("font_size", 13)
	for child in node.get_children():
		_apply_font_recursive(child, font)

func set_status(text: String) -> void:
	if status_val:
		status_val.text = text

func set_fps(fps: int) -> void:
	if fps_val:
		fps_val.text = str(fps)
