class_name MobaFonts
extends RefCounted

## Manages variable font weights for Outfit-Variable.ttf and system monospace matching Three.js CSS weights

const BASE_FONT_PATH := "res://assets/fonts/Outfit-Variable.ttf"
const WGHT_TAG := 2003265652 # 'wght' fourCC in OpenType

static var _base_font: FontFile = null
static var _cached_fonts: Dictionary = {}
static var _mono_bold: Font = null

static func _get_base_font() -> FontFile:
	if _base_font == null:
		_base_font = load(BASE_FONT_PATH) as FontFile
	return _base_font

static func get_outfit(weight: int = 500, extra_spacing_glyph: int = 0) -> Font:
	var key := "%d_%d" % [weight, extra_spacing_glyph]
	if _cached_fonts.has(key):
		return _cached_fonts[key]

	var base_f := _get_base_font()
	if not base_f:
		return ThemeDB.fallback_font

	var v := FontVariation.new()
	v.base_font = base_f
	v.variation_opentype = { WGHT_TAG: float(clamp(weight, 100, 900)) }
	if extra_spacing_glyph != 0:
		v.spacing_glyph = extra_spacing_glyph
	_cached_fonts[key] = v
	return v

static func outfit_medium() -> Font:
	return get_outfit(500)

static func outfit_semibold() -> Font:
	return get_outfit(600)

static func outfit_bold() -> Font:
	return get_outfit(700)

static func outfit_extrabold() -> Font:
	return get_outfit(800)

static func outfit_black() -> Font:
	return get_outfit(900)

static func monospace_bold() -> Font:
	if _mono_bold != null:
		return _mono_bold
	var sys := SystemFont.new()
	sys.font_names = PackedStringArray(["Consolas", "Courier New", "Liberation Mono", "monospace"])
	sys.font_weight = 700
	sys.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	sys.hinting = TextServer.HINTING_LIGHT
	sys.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	var base_f := _get_base_font()
	if base_f:
		sys.fallbacks = [ outfit_bold() ]
	_mono_bold = sys
	return _mono_bold
