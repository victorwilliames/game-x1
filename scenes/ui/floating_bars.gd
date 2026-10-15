class_name FloatingBars
extends Control

## Floating Health Bars matching style.css and Character.ts / Dummy.ts 1:1
## Projects 3D world positions of Caitlyn and Dummies to screen coordinates.

var hero: Node3D = null
var dummies: Array = []
var camera: Camera3D = null

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

	var font := ThemeDB.fallback_font
	var font_size_name := 11
	var font_size_hp := 10
	var font_size_lvl := 10

	# 1. Caitlyn (Player) Plate
	if hero and is_instance_valid(hero):
		var hero_head_pos := hero.global_position + Vector3(0, 5.2, 0)
		if not camera.is_position_behind(hero_head_pos):
			var screen_pt := camera.unproject_position(hero_head_pos)
			_draw_player_plate(screen_pt, font, font_size_name, font_size_hp, font_size_lvl)

	# 2. Dummies (Enemy) Plates
	for d in dummies:
		if d and is_instance_valid(d) and d.get("active") == true:
			var dummy_head_pos: Vector3 = d.global_position + Vector3(0, 3.4, 0)
			if not camera.is_position_behind(dummy_head_pos):
				var screen_pt := camera.unproject_position(dummy_head_pos)
				_draw_enemy_plate(d, screen_pt, font, font_size_name, font_size_hp)

func _draw_player_plate(pos: Vector2, font: Font, sz_name: int, sz_hp: int, sz_lvl: int) -> void:
	var total_w := 105.0
	var half_w := total_w * 0.5
	var top_left := Vector2(pos.x - half_w, pos.y - 30.0)

	var cur_hp: float = hero.get("hp") if hero.get("hp") != null else 1072.0
	var max_hp: float = hero.get("max_hp") if hero.get("max_hp") != null else 1072.0
	var hp_pct := clampf(cur_hp / maxf(max_hp, 1.0), 0.0, 1.0)
	var hp_str := "%d / %d (%d%%)" % [roundi(cur_hp), roundi(max_hp), roundi(hp_pct * 100.0)]

	# Name text centered
	var name_str := "Caitlyn"
	var name_w := font.get_string_size(name_str, HORIZONTAL_ALIGNMENT_CENTER, -1, sz_name).x
	draw_string_outline(font, Vector2(pos.x - name_w * 0.5, top_left.y + 10), name_str, HORIZONTAL_ALIGNMENT_CENTER, -1, sz_name, 3, Color.BLACK)
	draw_string(font, Vector2(pos.x - name_w * 0.5, top_left.y + 10), name_str, HORIZONTAL_ALIGNMENT_CENTER, -1, sz_name, Color.WHITE)

	# HP string centered
	var hp_w := font.get_string_size(hp_str, HORIZONTAL_ALIGNMENT_CENTER, -1, sz_hp).x
	draw_string_outline(font, Vector2(pos.x - hp_w * 0.5, top_left.y + 22), hp_str, HORIZONTAL_ALIGNMENT_CENTER, -1, sz_hp, 2, Color.BLACK)
	draw_string(font, Vector2(pos.x - hp_w * 0.5, top_left.y + 22), hp_str, HORIZONTAL_ALIGNMENT_CENTER, -1, sz_hp, Color(0, 1, 0.8, 1)) # #00ffcc

	# LoL Player Plate
	var plate_y := top_left.y + 26.0

	# Level box (16x16)
	var lvl_rect := Rect2(top_left.x, plate_y, 16, 16)
	draw_rect(lvl_rect, Color(0.07, 0.14, 0.21, 0.95)) # #122436
	draw_rect(lvl_rect, Color(0.76, 0.62, 0.33, 1.0), false, 1.5) # Gold border #c29d53
	var lvl_str := "5"
	var lvl_w := font.get_string_size(lvl_str, HORIZONTAL_ALIGNMENT_CENTER, -1, sz_lvl).x
	draw_string(font, Vector2(lvl_rect.position.x + (16 - lvl_w) * 0.5, lvl_rect.position.y + 12), lvl_str, HORIZONTAL_ALIGNMENT_CENTER, -1, sz_lvl, Color(0, 1, 0.8, 1))

	# Bars container (width = total_w - 18 = 87)
	var bar_x := top_left.x + 18.0
	var bar_w := total_w - 18.0

	# HP bar (height 9)
	var hp_bg := Rect2(bar_x, plate_y, bar_w, 10)
	draw_rect(hp_bg, Color(0.04, 0.06, 0.08, 0.95))
	var hp_fill := Rect2(bar_x, plate_y, bar_w * hp_pct, 10)
	draw_rect(hp_fill, Color(0.18, 0.8, 0.44, 1.0)) # #2ecc71

	# Ticks every 100 HP
	var num_ticks := int(max_hp / 100.0)
	for i in range(1, num_ticks):
		var tx := bar_x + (float(i * 100) / max_hp) * bar_w
		draw_line(Vector2(tx, plate_y), Vector2(tx, plate_y + 10), Color(0, 0, 0, 0.85), 1.0)

	# Mana bar (height 4)
	var mana_y := plate_y + 12.0
	var mana_bg := Rect2(bar_x, mana_y, bar_w, 4)
	draw_rect(mana_bg, Color(0.02, 0.03, 0.05, 0.95))
	var mana_fill := Rect2(bar_x, mana_y, bar_w, 4)
	draw_rect(mana_fill, Color(0.0, 0.75, 1.0, 1.0)) # #00bfff

func _draw_enemy_plate(dummy: Node3D, pos: Vector2, font: Font, sz_name: int, sz_hp: int) -> void:
	var total_w := 105.0
	var half_w := total_w * 0.5
	var top_left := Vector2(pos.x - half_w, pos.y - 28.0)

	var cur_hp: float = dummy.get("hp") if dummy.get("hp") != null else 600.0
	var max_hp: float = dummy.get("max_hp") if dummy.get("max_hp") != null else 600.0
	var hp_pct := clampf(cur_hp / maxf(max_hp, 1.0), 0.0, 1.0)
	var hp_str := "%d / %d (%d%%)" % [roundi(cur_hp), roundi(max_hp), roundi(hp_pct * 100.0)]

	var mode_str: String = dummy.get("mode") if dummy.get("mode") != null else "static"
	var name_str := "Dummy (Móvel)" if mode_str == "moving" else "Dummy (Estático)"

	# Name text centered
	var name_w := font.get_string_size(name_str, HORIZONTAL_ALIGNMENT_CENTER, -1, sz_name).x
	draw_string_outline(font, Vector2(pos.x - name_w * 0.5, top_left.y + 10), name_str, HORIZONTAL_ALIGNMENT_CENTER, -1, sz_name, 3, Color.BLACK)
	draw_string(font, Vector2(pos.x - name_w * 0.5, top_left.y + 10), name_str, HORIZONTAL_ALIGNMENT_CENTER, -1, sz_name, Color.WHITE)

	# HP string centered
	var hp_w := font.get_string_size(hp_str, HORIZONTAL_ALIGNMENT_CENTER, -1, sz_hp).x
	draw_string_outline(font, Vector2(pos.x - hp_w * 0.5, top_left.y + 22), hp_str, HORIZONTAL_ALIGNMENT_CENTER, -1, sz_hp, 2, Color.BLACK)
	draw_string(font, Vector2(pos.x - hp_w * 0.5, top_left.y + 22), hp_str, HORIZONTAL_ALIGNMENT_CENTER, -1, sz_hp, Color(0, 1, 0.8, 1))

	# Gold framed HP bar
	var bar_y := top_left.y + 25.0
	var bar_rect := Rect2(top_left.x, bar_y, total_w, 10)
	draw_rect(bar_rect, Color(0.04, 0.06, 0.08, 0.95))
	var fill_rect := Rect2(top_left.x, bar_y, total_w * hp_pct, 10)
	draw_rect(fill_rect, Color(0.9, 0.3, 0.23, 1.0)) # #e74c3c
	draw_rect(bar_rect, Color(0.76, 0.62, 0.33, 1.0), false, 1.5) # Gold frame #c29d53

	# Ticks every 100 HP
	var num_ticks := int(max_hp / 100.0)
	for i in range(1, num_ticks):
		var tx := top_left.x + (float(i * 100) / max_hp) * total_w
		draw_line(Vector2(tx, bar_y), Vector2(tx, bar_y + 10), Color(0, 0, 0, 0.85), 1.0)
