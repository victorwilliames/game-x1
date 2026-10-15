class_name FloatingBars
extends Control

## Floating Health Bars matching style.css and Character.ts / Dummy.ts 1:1
## Projects 3D world positions of Caitlyn and Dummies to screen coordinates.

var hero: Node3D = null
var dummies: Array = []
var camera: Camera3D = null

var font: Font = null

func _init() -> void:
	if ResourceLoader.exists("res://assets/fonts/Outfit-Variable.ttf"):
		var f := load("res://assets/fonts/Outfit-Variable.ttf") as FontFile
		if f:
			var sys_font := SystemFont.new()
			sys_font.font_names = PackedStringArray(["Segoe UI Emoji", "Noto Color Emoji", "Apple Color Emoji", "sans-serif"])
			f.fallbacks = [sys_font]
			var v := FontVariation.new()
			v.base_font = f
			v.variation_embolden = 0.25
			font = v
	if not font:
		font = ThemeDB.fallback_font

func setup(p_hero: Node3D, p_dummies: Array, p_camera: Camera3D) -> void:
	hero = p_hero
	dummies = p_dummies
	camera = p_camera
	mouse_filter = MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not camera or not is_instance_valid(camera):
		return

	var active_font := font if font else ThemeDB.fallback_font
	var font_size_name := 10
	var font_size_hp := 9
	var font_size_lvl := 9

	# 1. Caitlyn (Player) Plate
	if hero and is_instance_valid(hero):
		var hero_head_pos := hero.global_position + Vector3(0, 6.1, 0)
		if not camera.is_position_behind(hero_head_pos):
			var screen_pt := camera.unproject_position(hero_head_pos)
			_draw_player_plate(screen_pt, active_font, font_size_name, font_size_hp, font_size_lvl)

	# 2. Dummies (Enemy) Plates
	for d in dummies:
		if d and is_instance_valid(d) and d.get("active") == true:
			var dummy_head_pos: Vector3 = d.global_position + Vector3(0, 3.8, 0)
			if not camera.is_position_behind(dummy_head_pos):
				var screen_pt := camera.unproject_position(dummy_head_pos)
				_draw_enemy_plate(d, screen_pt, active_font, font_size_name, font_size_hp)

func _draw_player_plate(pos: Vector2, p_font: Font, sz_name: int, sz_hp: int, sz_lvl: int) -> void:
	pos = pos.round()
	var total_w := 105.0
	var half_w := total_w * 0.5
	var left := pos.x - half_w

	var cur_hp: float = hero.get("hp") if hero.get("hp") != null else 1072.0
	var max_hp: float = hero.get("max_hp") if hero.get("max_hp") != null else 1072.0
	var hp_pct := clampf(cur_hp / maxf(max_hp, 1.0), 0.0, 1.0)
	var hp_str := "%d / %d (%d%%)" % [roundi(cur_hp), roundi(max_hp), roundi(hp_pct * 100.0)]

	# 1. Name text: Caitlyn (top line)
	var name_str := "Caitlyn"
	var name_w := p_font.get_string_size(name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, sz_name).x
	var name_pos := Vector2(pos.x - name_w * 0.5, pos.y - 28.0)
	draw_string_outline(p_font, name_pos, name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, sz_name, 1, Color.BLACK)
	draw_string(p_font, name_pos, name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, sz_name, Color.WHITE)

	# 2. HP text: 1072 / 1072 (100%) (middle line)
	var hp_w := p_font.get_string_size(hp_str, HORIZONTAL_ALIGNMENT_LEFT, -1, sz_hp).x
	var hp_text_pos := Vector2(pos.x - hp_w * 0.5, pos.y - 17.0)
	draw_string_outline(p_font, hp_text_pos, hp_str, HORIZONTAL_ALIGNMENT_LEFT, -1, sz_hp, 1, Color.BLACK)
	draw_string(p_font, hp_text_pos, hp_str, HORIZONTAL_ALIGNMENT_LEFT, -1, sz_hp, Color(0.0, 1.0, 0.8, 1.0)) # #00ffcc

	# 3. LoL Player Plate (bottom, ending at pos.y)
	var plate_y := pos.y - 15.0

	# Level box (15x15)
	var lvl_rect := Rect2(left, plate_y, 15, 15)
	draw_rect(lvl_rect, Color(0.07, 0.14, 0.21, 0.95)) # #122436
	draw_rect(lvl_rect, Color(0.76, 0.62, 0.33, 1.0), false, 1.0) # Gold border #c29d53
	var lvl_str := "5"
	var lvl_w := p_font.get_string_size(lvl_str, HORIZONTAL_ALIGNMENT_CENTER, -1, sz_lvl).x
	draw_string(p_font, Vector2(lvl_rect.position.x + (15.0 - lvl_w) * 0.5, plate_y + 11.5), lvl_str, HORIZONTAL_ALIGNMENT_CENTER, -1, sz_lvl, Color(0.0, 1.0, 0.8, 1.0))

	# Bars container (width = 88)
	var bar_x := left + 17.0
	var bar_w := total_w - 17.0

	# HP bar (height 7)
	var hp_bg := Rect2(bar_x, plate_y, bar_w, 7)
	draw_rect(hp_bg, Color(0.04, 0.06, 0.08, 0.95))
	var hp_fill := Rect2(bar_x, plate_y, bar_w * hp_pct, 7)
	draw_rect(hp_fill, Color(0.18, 0.8, 0.44, 1.0)) # #2ecc71

	# Ticks every 100 HP
	var num_ticks := int(max_hp / 100.0)
	for i in range(1, num_ticks):
		var tx := bar_x + (float(i * 100) / max_hp) * bar_w
		draw_line(Vector2(tx, plate_y), Vector2(tx, plate_y + 7), Color(0.0, 0.0, 0.0, 0.85), 1.0)

	# Mana bar (height 3, separated by 1.5px from HP bar)
	var mana_y := plate_y + 9.0
	var mana_bg := Rect2(bar_x, mana_y, bar_w, 3)
	draw_rect(mana_bg, Color(0.02, 0.03, 0.05, 0.95))
	var mana_fill := Rect2(bar_x, mana_y, bar_w * hp_pct, 3)
	draw_rect(mana_fill, Color(0.0, 0.75, 1.0, 1.0)) # #00bfff

func _draw_enemy_plate(dummy: Node3D, pos: Vector2, p_font: Font, sz_name: int, sz_hp: int) -> void:
	pos = pos.round()
	var total_w := 105.0
	var half_w := total_w * 0.5
	var left := pos.x - half_w

	var cur_hp: float = dummy.get("hp") if dummy.get("hp") != null else 600.0
	var max_hp: float = dummy.get("max_hp") if dummy.get("max_hp") != null else 600.0
	var hp_pct := clampf(cur_hp / maxf(max_hp, 1.0), 0.0, 1.0)
	var hp_str := "%d / %d (%d%%)" % [roundi(cur_hp), roundi(max_hp), roundi(hp_pct * 100.0)]

	var mode_str: String = dummy.get("mode") if dummy.get("mode") != null else "static"
	var name_str := "Dummy (Móvel)" if mode_str == "moving" else "Dummy (Estático)"

	# 1. Gold framed HP bar at TOP: (height 9)
	var bar_y := pos.y - 28.0
	var bar_rect := Rect2(left, bar_y, total_w, 9)
	draw_rect(bar_rect, Color(0.04, 0.06, 0.08, 0.95))
	var fill_rect := Rect2(left, bar_y, total_w * hp_pct, 9)
	draw_rect(fill_rect, Color(0.9, 0.3, 0.23, 1.0)) # #e74c3c
	draw_rect(bar_rect, Color(0.76, 0.62, 0.33, 1.0), false, 1.5) # Gold frame #c29d53

	# Ticks every 100 HP
	var num_ticks := int(max_hp / 100.0)
	for i in range(1, num_ticks):
		var tx := left + (float(i * 100) / max_hp) * total_w
		draw_line(Vector2(tx, bar_y), Vector2(tx, bar_y + 9), Color(0.0, 0.0, 0.0, 0.85), 1.0)

	# 2. Name text centered (middle):
	var name_w := p_font.get_string_size(name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, sz_name).x
	var name_pos := Vector2(pos.x - name_w * 0.5, pos.y - 14.0)
	draw_string_outline(p_font, name_pos, name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, sz_name, 1, Color.BLACK)
	draw_string(p_font, name_pos, name_str, HORIZONTAL_ALIGNMENT_LEFT, -1, sz_name, Color.WHITE)

	# 3. HP text centered (bottom):
	var hp_w := p_font.get_string_size(hp_str, HORIZONTAL_ALIGNMENT_LEFT, -1, sz_hp).x
	var hp_pos := Vector2(pos.x - hp_w * 0.5, pos.y - 3.0)
	draw_string_outline(p_font, hp_pos, hp_str, HORIZONTAL_ALIGNMENT_LEFT, -1, sz_hp, 1, Color.BLACK)
	draw_string(p_font, hp_pos, hp_str, HORIZONTAL_ALIGNMENT_LEFT, -1, sz_hp, Color(0.0, 1.0, 0.8, 1.0))
