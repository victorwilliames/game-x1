class_name FloatingDamage
extends Control

## Floating damage numbers matching Game.ts and style.css 1:1
## Orange bold 26px for normal (55), Red bold 34px for crits (96!), rises 3.2 u/s, fades over 0.8s.

class DamageItem:
	var text: String
	var is_crit: bool
	var pos_3d: Vector3
	var x_offset: float
	var y_offset: float = 0.0
	var timer: float = 0.8
	var max_timer: float = 0.8

var items: Array[DamageItem] = []
var camera: Camera3D = null
var font: Font = null

func _init() -> void:
	if ResourceLoader.exists("res://assets/fonts/Outfit-Variable.ttf"):
		var f := load("res://assets/fonts/Outfit-Variable.ttf") as FontFile
		if f:
			var sys_font := SystemFont.new()
			sys_font.font_names = PackedStringArray(["Segoe UI Emoji", "Noto Color Emoji", "Apple Color Emoji", "sans-serif"])
			f.fallbacks = [sys_font]
			font = f
	if not font:
		font = ThemeDB.fallback_font

func setup(p_camera: Camera3D) -> void:
	camera = p_camera
	mouse_filter = MOUSE_FILTER_IGNORE

func spawn_damage(amount: float, pos: Vector3) -> void:
	var item := DamageItem.new()
	item.is_crit = randf() < 0.25
	var final_val := roundi(amount * 1.75) if item.is_crit else roundi(amount)
	item.text = str(final_val) + ("!" if item.is_crit else "")
	item.pos_3d = pos
	item.x_offset = (randf() - 0.5) * 1.5
	item.timer = 0.8
	item.max_timer = 0.8
	items.append(item)

func _process(delta: float) -> void:
	if items.is_empty():
		return

	for i in range(items.size() - 1, -1, -1):
		var item := items[i]
		item.timer -= delta
		if item.timer <= 0.0:
			items.remove_at(i)
		else:
			item.y_offset += delta * 3.2

	queue_redraw()

func _draw() -> void:
	if not camera or not is_instance_valid(camera):
		return

	var active_font := font if font else ThemeDB.fallback_font

	for item in items:
		var world_pt := item.pos_3d + Vector3(item.x_offset, 1.8 + item.y_offset, 0.0)
		if camera.is_position_behind(world_pt):
			continue

		var screen_pt := camera.unproject_position(world_pt)
		var alpha := clampf(item.timer / item.max_timer, 0.0, 1.0)
		var font_sz := 34 if item.is_crit else 26
		var col := Color(1.0, 0.2, 0.0, alpha) if item.is_crit else Color(1.0, 0.62, 0.0, alpha) # #ff3300 or #ff9f00
		var outline_col := Color(0, 0, 0, alpha)

		var text_sz := active_font.get_string_size(item.text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz)
		var draw_pos := Vector2(screen_pt.x - text_sz.x * 0.5, screen_pt.y + text_sz.y * 0.3)

		draw_string_outline(active_font, draw_pos, item.text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz, 6, outline_col)
		draw_string(active_font, draw_pos, item.text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz, col)
