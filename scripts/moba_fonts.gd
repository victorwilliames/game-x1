class_name MobaFonts
extends RefCounted

## Manages variable font weights for Outfit-Variable.ttf and embedded Consolas-Bold.ttf
## Fonts are tuned for readable small 2D text; exact Chrome DOM parity requires visual validation.

const BASE_FONT_PATH := "res://assets/fonts/Outfit-Variable.ttf"
const MONO_FONT_PATH := "res://assets/fonts/Consolas-Bold.ttf"
const WGHT_TAG := 2003265652 # 'wght' fourCC in OpenType

static var _base_font: FontFile = null
static var _cached_fonts: Dictionary = {}
static var _mono_bold: Font = null

static func _get_base_font() -> FontFile:
	if _base_font == null:
		_base_font = load(BASE_FONT_PATH) as FontFile
		if _base_font:
			# Keep variable weight support; apply settings before FontVariation caching.
			# At 9px AUTO uses quarter-pixel positioning, unlike forcing that
			# rasterization at every larger font size.
			# Oversampling is the only change from the usual engine defaults.
			_base_font.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
			_base_font.hinting = TextServer.HINTING_LIGHT
			_base_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
			_base_font.oversampling = 2.0
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
	v.variation_opentype = { WGHT_TAG: float(clampi(weight, 100, 900)) }
	v.variation_embolden = 0.0
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
	var mono_file := load(MONO_FONT_PATH) as FontFile
	if mono_file:
		mono_file.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		mono_file.hinting = TextServer.HINTING_LIGHT
		mono_file.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
		mono_file.oversampling = 2.0
		var v := FontVariation.new()
		v.base_font = mono_file
		v.variation_embolden = 0.06
		_mono_bold = v
		return _mono_bold
	_mono_bold = outfit_bold()
	return _mono_bold
