class_name FloatingBars
extends Control

## Floating Health Bars matching style.css and Character.ts / Dummy.ts 1:1
## Uses cached TextLine shaping and dirty-state tracking to eliminate per-frame text shaping overhead.

var hero: Node3D = null
var dummies: Array = []
var camera: Camera3D = null

var font_bold: Font = null
var font_extrabold: Font = null
var font_black: Font = null

const SZ_NAME := 9
const SZ_HP := 9
const SZ_LVL := 9

# Cached TextLines for Player (Caitlyn)
var _tl_player_name: TextLine = TextLine.new()
var _tl_player_hp: TextLine = TextLine.new()
var _tl_player_lvl: TextLine = TextLine.new()
var _cached_player_hp_str: String = ""
var _cached_player_pos: Vector2 = Vector2(-9999, -9999)
var _cached_player_vis: bool = false

# Cached TextLines and states per Dummy
class DummyBarCache:
	var tl_name: TextLine = TextLine.new()
	var tl_hp: TextLine = TextLine.new()
	var hp_str: String = ""
	var mode_str: String = ""
	var pos: Vector2 = Vector2(-9999, -9999)
	var vis: bool = false
	var hp_val: int = -1

var _dummy_caches: Array[DummyBarCache] = []

const SHADOW_OFFSETS: Array[Vector2] = [
	Vector2(-1, -1),
	Vector2(1, -1),
	Vector2(-1, 1),
	Vector2(1, 1),
]

func _init() -> void:
	font_bold = MobaFonts.outfit_bold()
	font_extrabold = MobaFonts.outfit_extrabold()
	font_black = MobaFonts.outfit_black()

	_tl_player_name.add_string("Caitlyn", font_extrabold, SZ_NAME)
	_tl_player_lvl.add_string("5", font_black, SZ_LVL)

func setup(p_hero: Node3D, p_dummies: Array, p_camera: Camera3D) -> void:
	hero = p_hero
	dummies = p_dummies
	camera = p_camera
	mouse_filter = MOUSE_FILTER_IGNORE
	_rebuild_dummy_caches()
	queue_redraw()

func _rebuild_dummy_caches() -> void:
	_dummy_caches.clear()
	for i in range(dummies.size()):
		var c := DummyBarCache.new()
		_dummy_caches.append(c)

func _process(_delta: float) -> void:
	if not camera or not is_instance_valid(camera):
		return

	if _dummy_caches.size() != dummies.size():
		_rebuild_dummy_caches()

	var dirty := false

	# 1. Check Caitlyn state & screen position
	if hero and is_instance_valid(hero):
		var hero_head_pos := hero.global_position + Vector3(0, 5.2, 0)
		var vis := not camera.is_position_behind(hero_head_pos)
		if vis != _cached_player_vis:
			_cached_player_vis = vis
			dirty = true
		if vis:
			var pt := camera.unproject_position(hero_head_pos).round()
			if pt != _cached_player_pos:
				_cached_player_pos = pt
				dirty = true
			var cur_hp: float = hero.get("hp") if hero.get("hp") != null else 1072.0
			var max_hp: float = hero.get("max_hp") if hero.get("max_hp") != null else 1072.0
			var hp_pct := clampf(cur_hp / maxf(max_hp, 1.0), 0.0, 1.0)
			var hp_str := "%d / %d (%d%%)" % [roundi(cur_hp), roundi(max_hp), roundi(hp_pct * 100.0)]
			if hp_str != _cached_player_hp_str:
				_cached_player_hp_str = hp_str
				_tl_player_hp.clear()
				_tl_player_hp.add_string(hp_str, font_extrabold, SZ_HP)
				dirty = true

	# 2. Check Dummies state & screen positions
	for i in range(dummies.size()):
		var d = dummies[i]
		var c := _dummy_caches[i]
		if d and is_instance_valid(d) and d.get("active") == true:
			var dummy_head_pos: Vector3 = d.global_position + Vector3(0, 3.4, 0)
			var vis := not camera.is_position_behind(dummy_head_pos)
			if vis != c.vis:
				c.vis = vis
				dirty = true
			if vis:
				var pt := camera.unproject_position(dummy_head_pos).round()
				if pt != c.pos:
					c.pos = pt
					dirty = true
				var mode_str: String = d.get("mode") if d.get("mode") != null else "static"
				if mode_str != c.mode_str:
					c.mode_str = mode_str
					var name_str := "Dummy (Móvel)" if mode_str == "moving" else "Dummy (Estático)"
					c.tl_name.clear()
					c.tl_name.add_string(name_str, font_bold, SZ_NAME)
					dirty = true
				var cur_hp: float = d.get("hp") if d.get("hp") != null else 600.0
				var max_hp: float = d.get("max_hp") if d.get("max_hp") != null else 600.0
				var hp_int := roundi(cur_hp)
				if hp_int != c.hp_val:
					c.hp_val = hp_int
					var hp_pct := clampf(cur_hp / maxf(max_hp, 1.0), 0.0, 1.0)
					var hp_str := "%d / %d (%d%%)" % [hp_int, roundi(max_hp), roundi(hp_pct * 100.0)]
					c.hp_str = hp_str
					c.tl_hp.clear()
					c.tl_hp.add_string(hp_str, font_bold, SZ_HP)
					dirty = true
		else:
			if c.vis:
				c.vis = false
				dirty = true

	if dirty:
		queue_redraw()

func _draw_tl_shadowed(tl: TextLine, pos: Vector2, col: Color) -> void:
	var ci := get_canvas_item()
	var p := pos.round()
	# CSS drop-shadow(0 2px 4px rgba(0,0,0,0.8)) + 4-corner text-shadow
	tl.draw(ci, p + Vector2(0, 2), Color(0, 0, 0, 0.55))
	for off in SHADOW_OFFSETS:
		tl.draw(ci, p + off, Color(0, 0, 0, 0.92))
	tl.draw(ci, p, col)

func _draw() -> void:
	if not camera or not is_instance_valid(camera):
		return

	# 1. Caitlyn (Player) Plate
	if _cached_player_vis and hero and is_instance_valid(hero):
		_draw_player_plate(_cached_player_pos)

	# 2. Dummies (Enemy) Plates
	for i in range(dummies.size()):
		var d = dummies[i]
		var c := _dummy_caches[i]
		if c.vis and d and is_instance_valid(d) and d.get("active") == true:
			_draw_enemy_plate(d, c)

func _draw_player_plate(pos: Vector2) -> void:
	var total_w := 105.0
	var left := roundf(pos.x - total_w * 0.5)

	var cur_hp: float = hero.get("hp") if hero.get("hp") != null else 1072.0
	var max_hp: float = hero.get("max_hp") if hero.get("max_hp") != null else 1072.0
	var hp_pct := clampf(cur_hp / maxf(max_hp, 1.0), 0.0, 1.0)

	# 1. Name text: Caitlyn (top line, matching Three.js y = pos.y - 45)
	var name_w := _tl_player_name.get_size().x
	var name_pos := Vector2(roundf(pos.x - name_w * 0.5), pos.y - 45.0)
	_draw_tl_shadowed(_tl_player_name, name_pos, Color.WHITE)

	# 2. HP text: 1072 / 1072 (100%) (middle line, matching Three.js y = pos.y - 33)
	var hp_w := _tl_player_hp.get_size().x
	var hp_text_pos := Vector2(roundf(pos.x - hp_w * 0.5), pos.y - 33.0)
	_draw_tl_shadowed(_tl_player_hp, hp_text_pos, Color(0.0, 1.0, 0.8, 1.0)) # #00ffcc

	# 3. LoL Player Plate (.lol-player-plate: 105x17 black framed container)
	var plate_y := pos.y - 17.0
	var plate_rect := Rect2(left, plate_y, total_w, 17.0)
	# Drop shadow under plate (filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.8)))
	draw_rect(Rect2(left - 1.0, plate_y + 2.0, total_w + 2.0, 17.0), Color(0, 0, 0, 0.55))
	# Black plate body (background: rgba(0,0,0,0.95), border: 1.5px solid #000)
	draw_rect(plate_rect, Color(0.0, 0.0, 0.0, 0.96))

	# Level box (15x15 inside 1px padding -> left + 2, plate_y + 1)
	var lvl_rect := Rect2(left + 2.0, plate_y + 1.0, 15.0, 15.0)
	draw_rect(lvl_rect, Color(0.0706, 0.1412, 0.2118, 1.0)) # #122436
	draw_rect(lvl_rect, Color(0.7608, 0.6157, 0.3255, 1.0), false, 1.0) # Gold border #c29d53
	var lvl_sz := _tl_player_lvl.get_size()
	var lvl_pos := Vector2(
		roundf(lvl_rect.position.x + (15.0 - lvl_sz.x) * 0.5),
		roundf(lvl_rect.position.y + (15.0 - lvl_sz.y) * 0.5)
	)
	_tl_player_lvl.draw(get_canvas_item(), lvl_pos, Color(0.0, 1.0, 0.8, 1.0))

	# Bars container (left + 19, width = 84)
	var bar_x := left + 19.0
	var bar_w := 84.0
	var hp_y := plate_y + 3.0 # 7px HP + 1px gap + 3px Mana = 11px centered inside 17px plate

	# HP bar outer (height 7)
	draw_rect(Rect2(bar_x, hp_y, bar_w, 7.0), Color(0.039, 0.059, 0.078, 0.95))
	# HP bar inner: linear-gradient(180deg, #2ecc71, #27ae60)
	var fill_w := roundf(bar_w * hp_pct)
	if fill_w > 0.0:
		draw_rect(Rect2(bar_x, hp_y, fill_w, 4.0), Color(0.1804, 0.8000, 0.4431, 1.0)) # #2ecc71
		draw_rect(Rect2(bar_x, hp_y + 4.0, fill_w, 3.0), Color(0.1529, 0.6824, 0.3765, 1.0)) # #27ae60

	# Ticks every 100 HP (1px crisp black dividers)
	var num_ticks := int(max_hp / 100.0)
	for i in range(1, num_ticks + 1):
		var tx := roundf(bar_x + (float(i * 100) / max_hp) * bar_w)
		if tx < bar_x + bar_w:
			draw_rect(Rect2(tx, hp_y, 1.0, 7.0), Color(0.0, 0.0, 0.0, 0.85))

	# Mana bar (height 3, 1px gap below HP bar)
	var mana_y := hp_y + 8.0
	draw_rect(Rect2(bar_x, mana_y, bar_w, 3.0), Color(0.02, 0.031, 0.047, 0.95))
	draw_rect(Rect2(bar_x, mana_y, bar_w, 2.0), Color(0.0, 0.749, 1.0, 1.0)) # #00bfff
	draw_rect(Rect2(bar_x, mana_y + 2.0, bar_w, 1.0), Color(0.0, 0.467, 0.761, 1.0)) # #0077c2

func _draw_enemy_plate(dummy: Node3D, c: DummyBarCache) -> void:
	var pos := c.pos
	var total_w := 105.0
	var left := roundf(pos.x - total_w * 0.5)

	var cur_hp: float = dummy.get("hp") if dummy.get("hp") != null else 600.0
	var max_hp: float = dummy.get("max_hp") if dummy.get("max_hp") != null else 600.0
	var hp_pct := clampf(cur_hp / maxf(max_hp, 1.0), 0.0, 1.0)

	# 1. Gold framed HP bar at TOP: (height 9, y = pos.y - 36 matching Three.js y=[374, 382])
	var bar_y := pos.y - 36.0
	var bar_rect := Rect2(left, bar_y, total_w, 9.0)
	# Drop shadow under bar
	draw_rect(Rect2(left - 1.0, bar_y + 2.0, total_w + 2.0, 9.0), Color(0, 0, 0, 0.55))
	# Outer dark background
	draw_rect(bar_rect, Color(0.039, 0.059, 0.078, 0.95))
	# Inner fill: linear-gradient(180deg, #e74c3c, #c0392b) + inset top highlight
	var fill_w := roundf(total_w * hp_pct)
	if fill_w > 0.0:
		draw_rect(Rect2(left, bar_y, fill_w, 1.0), Color(0.925, 0.435, 0.380, 1.0))
		draw_rect(Rect2(left, bar_y + 1.0, fill_w, 4.0), Color(0.9059, 0.2980, 0.2353, 1.0)) # #e74c3c
		draw_rect(Rect2(left, bar_y + 5.0, fill_w, 4.0), Color(0.7529, 0.2235, 0.1686, 1.0)) # #c0392b

	# Ticks every 100 HP
	var num_ticks := int(max_hp / 100.0)
	for i in range(1, num_ticks):
		var tx := roundf(left + (float(i * 100) / max_hp) * total_w)
		draw_rect(Rect2(tx, bar_y + 1.0, 1.0, 7.0), Color(0.0, 0.0, 0.0, 0.85))

	# Gold border (#c29d53, 1.0px crisp frame)
	draw_rect(bar_rect, Color(0.7608, 0.6157, 0.3255, 1.0), false, 1.0)

	# 2. Name text centered (middle, matching Three.js y = pos.y - 25):
	var name_w := c.tl_name.get_size().x
	var name_pos := Vector2(roundf(pos.x - name_w * 0.5), pos.y - 25.0)
	_draw_tl_shadowed(c.tl_name, name_pos, Color.WHITE)

	# 3. HP text centered (bottom, matching Three.js y = pos.y - 13):
	var hp_w := c.tl_hp.get_size().x
	var hp_pos := Vector2(roundf(pos.x - hp_w * 0.5), pos.y - 13.0)
	_draw_tl_shadowed(c.tl_hp, hp_pos, Color(0.0, 1.0, 0.8, 1.0))
