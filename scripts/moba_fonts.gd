class_name MobaFonts
extends RefCounted

## Manages variable font weights for Outfit-Variable.ttf matching Three.js CSS weights

const BASE_FONT_PATH := "res://assets/fonts/Outfit-Variable.ttf"
const WGHT_TAG := 2003265652 # 'wght' fourCC in OpenType

static var _cached_fonts: Dictionary = {}

static func get_outfit(weight: int = 500) -> Font:
	if _cached_fonts.has(weight):
		return _cached_fonts[weight]

	var base_f := load(BASE_FONT_PATH) as FontFile
	if not base_f:
		return ThemeDB.fallback_font

	var v := FontVariation.new()
	v.base_font = base_f
	v.variation_opentype = { WGHT_TAG: float(clamp(weight, 100, 900)) }
	_cached_fonts[weight] = v
	return v

static func outfit_medium() -> Font:
	return get_outfit(500)

static func outfit_bold() -> Font:
	return get_outfit(700)

static func outfit_extrabold() -> Font:
	return get_outfit(800)

static func outfit_black() -> Font:
	return get_outfit(900)
