extends Node3D

## 1:1 Port of Game.ts from game-x0-moba (Godot 4)
## Coordinates Caitlyn, Dummies, Combat AI, Projectiles, Targeting, LoL Cursors, and Floating UI.

const PLAYABLE_MIN_X: float = -38.0
const PLAYABLE_MAX_X: float = 38.0
const PLAYABLE_MIN_Z: float = -38.0
const PLAYABLE_MAX_Z: float = 38.0

@onready var hero: Hero = $Hero
@onready var camera_controller: MobaCamera = $CameraPivot
@onready var directional_light: DirectionalLight3D = $DirectionalLight3D

@onready var dummies_container: Node3D = $Dummies
@onready var projectiles_container: Node3D = $Projectiles
@onready var effects_container: Node3D = $Effects

@onready var range_indicator: MeshInstance3D = $Effects/RangeIndicator
@onready var target_marker: Node3D = $Effects/TargetMarker
@onready var click_indicator: Node3D = $Effects/ClickIndicator

@onready var floating_bars: FloatingBars = $UI/FloatingBars
@onready var floating_damage: FloatingDamage = $UI/FloatingDamage
@onready var status_hud: StatusHUD = $UI/StatusHUD
@onready var debug_panel: PanelContainer = $UI/DebugPanel
@onready var telemetry_label: Label = $UI/DebugPanel/TelemetryLabel
@onready var fxaa_effect: ColorRect = get_node_or_null("PostProcessLayer/FXAAEffect")

const PROJECTILE_SCENE = preload("res://scenes/combat/projectile.tscn")

var cursor_normal: Texture2D
var cursor_alt: Texture2D
var cursor_link: Texture2D
var current_cursor_type: String = "normal"

var dummies: Array = []
var selected_target: Node3D = null
var is_attack_move_mode: bool = false
var click_indicator_timer: float = 0.0

var is_headless: bool = false
var ground_plane := Plane(Vector3.UP, 0.0)

var current_frame_time_ms: float = 16.6
var frame_time_acc: float = 0.0
var frame_time_count: int = 0
var last_fps_update_time: float = 0.0
var cached_raf_hz: int = 0

# Browser benchmark commands are rare. Poll a single atomic bitmask 20 times/second,
# rather than calling JavaScriptBridge.eval() three times on every render frame.
# Bit pairs: 0/1 = FXAA present/value, 2/3 = MSAA, 4/5 = shadows.
const WEB_COMMAND_POLL_SECONDS: float = 0.05
const WEB_COMMANDS_JS: String = """
(function () {
    var mask = 0;
    if (window._cmd_set_fxaa !== undefined) {
        mask |= 1;
        if (window._cmd_set_fxaa == 1) mask |= 2;
        delete window._cmd_set_fxaa;
    }
    if (window._cmd_set_msaa !== undefined) {
        mask |= 4;
        if (window._cmd_set_msaa == 1) mask |= 8;
        delete window._cmd_set_msaa;
    }
    if (window._cmd_set_shadows !== undefined) {
        mask |= 16;
        if (window._cmd_set_shadows == 1) mask |= 32;
        delete window._cmd_set_shadows;
    }
    return mask;
})()
"""
var _web_command_poll_elapsed: float = 0.0

var range_mat: Material

func _ready() -> void:
	is_headless = DisplayServer.get_name() == "headless"

	# Load LoL Cursors
	cursor_normal = load("res://assets/ui/pointers/normal.png")
	cursor_alt = load("res://assets/ui/pointers/alt.png")
	cursor_link = load("res://assets/ui/pointers/link.png")
	_set_cursor("normal")

	# Gather Dummies
	if dummies_container:
		for child in dummies_container.get_children():
			if child is MobaDummy:
				dummies.append(child)

	# Configure Hero
	if hero and not is_headless:
		hero.shoot.connect(_on_hero_shoot)
		hero.global_position = Vector3.ZERO

	# Configure Camera
	if camera_controller and hero:
		camera_controller.target = hero
		if not is_headless:
			camera_controller.center_on_target(false)
			camera_controller.camera_mode_changed.connect(_on_camera_mode_changed)

	# Setup Floating UI
	var cam: Camera3D = camera_controller.camera if camera_controller else null
	if floating_bars and cam:
		floating_bars.setup(hero, dummies, cam)
	if floating_damage and cam:
		floating_damage.setup(cam)

	# Setup Range Indicator (Flat 2D ring matching THREE.RingGeometry)
	if range_indicator and hero:
		var r_mesh = RingMeshBuilder.create_ring_mesh(hero.attack_range - 0.25, hero.attack_range + 0.25, 128)
		range_indicator.mesh = r_mesh
		range_mat = RingMeshBuilder.create_smooth_ring_material(hero.attack_range - 0.08, hero.attack_range + 0.08, Color(0, 1, 0.533, 0.12))
		range_indicator.material_override = range_mat

	# Setup PointTarget material
	if click_indicator:
		var green_mat = StandardMaterial3D.new()
		green_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		green_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		green_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		green_mat.albedo_color = Color(0.0, 1.0, 0.533, 0.85) # #00ff88
		for mesh_inst in click_indicator.find_children("*", "MeshInstance3D"):
			mesh_inst.material_override = green_mat
			mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		click_indicator.visible = false

	# Setup Target Marker (Flat 2D red ring matching THREE.RingGeometry(0.75, 0.95, 32))
	if target_marker:
		var marker_mesh_node = target_marker.get_node_or_null("MarkerMesh") as MeshInstance3D
		if marker_mesh_node:
			marker_mesh_node.mesh = RingMeshBuilder.create_ring_mesh(0.65, 1.05, 64)
			var marker_mat = RingMeshBuilder.create_smooth_ring_material(0.75, 0.95, Color(1.0, 0.231, 0.188, 0.7))
			marker_mesh_node.material_override = marker_mat
		target_marker.visible = false

	if not is_headless:
		if status_hud:
			status_hud.set_status("Pronto!")
			status_hud.set_fps(Engine.get_frames_per_second())
		if OS.has_feature("web"):
			_install_web_scroll_preventer()
			JavaScriptBridge.eval("window._gamex1_ready = true;")

	print("[game-x1] Main 1:1 scene ready. Platform: %s, Headless: %s" % [OS.get_name(), str(is_headless)])

func _install_web_scroll_preventer() -> void:
	if not OS.has_feature("web"):
		return
	var js_code = """
	(function() {
		if (window._godot_web_scroll_guard) return;
		window._godot_web_scroll_guard = true;
		function isCanvasTarget(e) {
			var canvas = document.getElementById('canvas');
			return canvas && (e.target === canvas || canvas.contains(e.target));
		}
		window.addEventListener('keydown', function(e) {
			if (e.code === 'Space' || e.keyCode === 32 || e.code === 'Quote' || e.key === "'") {
				var canvas = document.getElementById('canvas');
				if (document.activeElement === canvas || document.activeElement === document.body || isCanvasTarget(e)) {
					e.preventDefault();
				}
			}
		}, { passive: false });
		window.addEventListener('wheel', function(e) {
			if (isCanvasTarget(e)) {
				e.preventDefault();
			}
		}, { passive: false });
	})();
	"""
	JavaScriptBridge.eval(js_code)

func _unhandled_input(event: InputEvent) -> void:
	if is_headless or not hero:
		return

	# F1 toggles real-time shadows, F2 toggles MSAA, F3 toggles telemetry debug panel, F4 toggles FXAA
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			_toggle_shadows()
			return
		elif event.keycode == KEY_F2:
			var vp := get_viewport()
			vp.msaa_3d = Viewport.MSAA_DISABLED if vp.msaa_3d != Viewport.MSAA_DISABLED else Viewport.MSAA_2X
			_update_hud()
			return
		elif event.keycode == KEY_F3:
			if debug_panel:
				debug_panel.visible = not debug_panel.visible
				_update_hud()
			return
		elif event.keycode == KEY_F4:
			if fxaa_effect:
				fxaa_effect.visible = not fxaa_effect.visible
				_update_hud()
			return
		elif event.keycode == KEY_A:
			is_attack_move_mode = true
			return
		elif event.keycode == KEY_X:
			_handle_attack_basic_trigger()
			return

	# Camera input (Space, Y, Quote, MMB, Wheel)
	if camera_controller and camera_controller.handle_input(event):
		return

	# Mouse clicks
	if event is InputEventMouseButton and event.pressed:
		var cursor_pos = _get_floor_world_pos(event.position)
		if cursor_pos != null:
			if event.button_index == MOUSE_BUTTON_RIGHT:
				_handle_right_click(cursor_pos)
			elif event.button_index == MOUSE_BUTTON_LEFT:
				_handle_left_click(cursor_pos)

func _handle_right_click(cursor_pos: Vector3) -> void:
	var target_dummy: MobaDummy = null

	# Search active dummy within purple tolerance ring (radius 3.0)
	var min_dist_sq := 3.0 * 3.0
	for d in dummies:
		if d and is_instance_valid(d) and d.active:
			var dx: float = d.global_position.x - cursor_pos.x
			var dz: float = d.global_position.z - cursor_pos.z
			var dist_sq: float = dx * dx + dz * dz
			if dist_sq < min_dist_sq:
				min_dist_sq = dist_sq
				target_dummy = d

	# If targeted a dummy
	if target_dummy != null and target_dummy.active:
		selected_target = target_dummy
		is_attack_move_mode = false

		if hero.state == Hero.State.ATTACKING and hero.is_attack_windup_triggered:
			hero.cancel_attack()
		return

	# Otherwise, normal ground movement
	selected_target = null
	is_attack_move_mode = false

	if hero.state == Hero.State.ATTACKING:
		hero.cancel_attack()

	var clamped_pos = _clamp_to_bounds(cursor_pos)
	hero.set_move_target(clamped_pos)
	_spawn_click_indicator(clamped_pos)

func _handle_left_click(cursor_pos: Vector3) -> void:
	if is_attack_move_mode:
		is_attack_move_mode = false
		var closest_dummy: MobaDummy = null
		var min_dist_sq := INF

		for d in dummies:
			if d and is_instance_valid(d) and d.active:
				var dx: float = d.global_position.x - cursor_pos.x
				var dz: float = d.global_position.z - cursor_pos.z
				var dist_sq: float = dx * dx + dz * dz
				if dist_sq < min_dist_sq:
					min_dist_sq = dist_sq
					closest_dummy = d

		if closest_dummy != null:
			var dist_to_player_sq: float = hero.global_position.distance_squared_to(closest_dummy.global_position)
			var range_sq := (hero.attack_range + 3.0) * (hero.attack_range + 3.0)
			if dist_to_player_sq <= range_sq:
				selected_target = closest_dummy
			else:
				var clamped_pos = _clamp_to_bounds(cursor_pos)
				hero.set_move_target(clamped_pos)
				selected_target = null
		else:
			var clamped_pos = _clamp_to_bounds(cursor_pos)
			hero.set_move_target(clamped_pos)
			selected_target = null

		_spawn_click_indicator(_clamp_to_bounds(cursor_pos))
	else:
		# Smart attack closest target
		var best_target = TargetingSystem.find_best_target(hero.global_position, cursor_pos, dummies, hero.attack_range)
		if best_target != null:
			selected_target = best_target
			if hero.attack_cooldown <= 0.0 and hero.state != Hero.State.ATTACKING:
				hero.start_attack(best_target, null)

func _handle_attack_basic_trigger() -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	var cursor_pos = _get_floor_world_pos(mouse_pos)

	var best_target = TargetingSystem.find_best_target(hero.global_position, cursor_pos, dummies, hero.attack_range)
	if best_target != null:
		selected_target = best_target
		if hero.attack_cooldown <= 0.0 and hero.state != Hero.State.ATTACKING:
			hero.start_attack(best_target, null)
	else:
		if hero.attack_cooldown <= 0.0 and hero.state != Hero.State.ATTACKING and cursor_pos is Vector3:
			var dir: Vector3 = (cursor_pos as Vector3) - hero.global_position
			dir.y = 0.0
			hero.start_attack(null, dir)

func _get_floor_world_pos(screen_pos: Vector2) -> Variant:
	if not camera_controller or not camera_controller.camera:
		return null
	var active_cam := camera_controller.camera
	var ray_origin := active_cam.project_ray_origin(screen_pos)
	var ray_dir := active_cam.project_ray_normal(screen_pos)
	return ground_plane.intersects_ray(ray_origin, ray_dir)

func _clamp_to_bounds(pos: Vector3) -> Vector3:
	return Vector3(
		clampf(pos.x, PLAYABLE_MIN_X, PLAYABLE_MAX_X),
		0.0,
		clampf(pos.z, PLAYABLE_MIN_Z, PLAYABLE_MAX_Z)
	)

func _spawn_click_indicator(pos: Vector3) -> void:
	if click_indicator:
		click_indicator.global_position = Vector3(pos.x, 0.05, pos.z)
		click_indicator.visible = true
		click_indicator.scale = Vector3(1.5, 1.5, 1.5)
		click_indicator_timer = 0.35

func _on_hero_shoot(target: Node3D, direction: Variant, is_melee: bool) -> void:
	var damage := 55.0

	if is_melee:
		# Coronhada: dano instantâneo + faísca amarela
		if target and is_instance_valid(target) and target.has_method("take_damage"):
			target.take_damage(damage)
			if floating_damage:
				floating_damage.spawn_damage(damage, target.global_position)
			_spawn_melee_slash_effect(target.global_position)
	else:
		# Disparo Ranged: Projétil rosa Hextech a 25 m/s
		var spawn_pos := hero.global_position + Vector3(0, 1.85, 0)
		var proj: MobaProjectile = PROJECTILE_SCENE.instantiate()
		projectiles_container.add_child(proj)
		proj.init_projectile(spawn_pos, 25.0, damage, target, direction)
		proj.hit_target_signal.connect(_on_projectile_hit)

func _on_projectile_hit(damage: float, hit_pos: Vector3) -> void:
	if floating_damage:
		floating_damage.spawn_damage(damage, hit_pos)

func _spawn_melee_slash_effect(pos: Vector3) -> void:
	var slash := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.1
	mesh.outer_radius = 0.8
	mesh.rings = 16
	mesh.ring_segments = 3
	slash.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(1.0, 0.8, 0.0, 0.9) # Amarelo de impacto
	slash.material_override = mat

	slash.global_position = pos + Vector3(0, 1.35, 0)
	slash.rotation = Vector3(randf() * PI, randf() * PI, randf() * PI)
	effects_container.add_child(slash)

	var tween = create_tween()
	tween.tween_property(slash, "scale", Vector3(3.0, 3.0, 3.0), 0.15)
	tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.15)
	tween.tween_callback(slash.queue_free)

func _handle_combat_ai() -> void:
	if selected_target != null:
		if not is_instance_valid(selected_target) or not selected_target.get("active"):
			selected_target = null
			return

		var dist: float = hero.global_position.distance_to(selected_target.global_position)
		if dist <= hero.attack_range:
			if hero.state == Hero.State.WALKING:
				hero.stop()
			if hero.attack_cooldown <= 0.0 and hero.state != Hero.State.ATTACKING:
				hero.start_attack(selected_target, null)
		else:
			if hero.state != Hero.State.ATTACKING:
				hero.set_move_target(selected_target.global_position)

func _process(delta: float) -> void:
	if is_headless:
		return

	if OS.has_feature("web"):
		_web_command_poll_elapsed += delta
		if _web_command_poll_elapsed >= WEB_COMMAND_POLL_SECONDS:
			_web_command_poll_elapsed = 0.0
			_poll_web_commands()

	# 1. Update Dummies
	for d in dummies:
		if d and is_instance_valid(d):
			d.update_dummy(delta)

	# 2. Update Active Projectiles
	for child in projectiles_container.get_children():
		if child is MobaProjectile:
			child.update_projectile(dummies, delta)

	# 3. Process Combat AI
	_handle_combat_ai()

	# 4. Update Range Indicator (Follows Caitlyn, color changes on Attack Move)
	if range_indicator and hero:
		range_indicator.global_position = hero.global_position + Vector3(0, 0.02, 0)
		if range_mat:
			var target_col := Color(1.0, 0.0, 0.33, 0.35) if is_attack_move_mode else Color(0.0, 1.0, 0.533, 0.12)
			if range_mat is ShaderMaterial:
				range_mat.set_shader_parameter("ring_color", target_col)
			elif range_mat is StandardMaterial3D and range_mat.albedo_color != target_col:
				range_mat.albedo_color = target_col

	# 5. Update Target Marker on selected dummy
	if target_marker:
		if selected_target != null and is_instance_valid(selected_target) and selected_target.get("active"):
			target_marker.global_position = selected_target.global_position + Vector3(0, 0.03, 0)
			target_marker.visible = true
			var s := 1.0 + sin(Time.get_ticks_msec() * 0.01) * 0.1
			target_marker.scale = Vector3(s, s, s)
		else:
			if target_marker.visible:
				target_marker.visible = false

	# 6. Update Click Indicator (Spins and scales down)
	if click_indicator and click_indicator.visible:
		click_indicator_timer -= delta
		var progress := click_indicator_timer / 0.35
		if progress <= 0.0:
			click_indicator.visible = false
		else:
			click_indicator.rotation.y += delta * 6.0
			var s := 1.5 * progress
			click_indicator.scale = Vector3(s, s, s)

	# 7. Update Outlines & Hover Cursors
	_update_hover_and_cursor()

	# 8. FPS and Telemetry
	_update_telemetry(delta)

# This method only runs on the Web build at 20 Hz. One JS evaluation consumes
# every pending benchmark toggle atomically; repeated commands do not stay queued.
func _poll_web_commands() -> void:
	var command_mask := int(JavaScriptBridge.eval(WEB_COMMANDS_JS, true))
	if command_mask == 0:
		return

	var changed := false
	if (command_mask & 1) != 0 and fxaa_effect:
		var fxaa_enabled := (command_mask & 2) != 0
		if fxaa_effect.visible != fxaa_enabled:
			fxaa_effect.visible = fxaa_enabled
			changed = true

	if (command_mask & 4) != 0:
		var vp := get_viewport()
		var new_msaa := Viewport.MSAA_2X if (command_mask & 8) != 0 else Viewport.MSAA_DISABLED
		if vp.msaa_3d != new_msaa:
			vp.msaa_3d = new_msaa
			changed = true

	if (command_mask & 16) != 0 and directional_light:
		var shadows_enabled := (command_mask & 32) != 0
		if directional_light.shadow_enabled != shadows_enabled:
			directional_light.shadow_enabled = shadows_enabled
			changed = true

	if changed:
		_update_hud()

func _update_hover_and_cursor() -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	var cursor_world = _get_floor_world_pos(mouse_pos)

	var hover_enemy = false

	for d in dummies:
		if d and is_instance_valid(d):
			var show_outline := false
			if d.active and cursor_world is Vector3:
				if selected_target == d:
					show_outline = true
				var dx: float = d.global_position.x - cursor_world.x
				var dz: float = d.global_position.z - cursor_world.z
				if dx * dx + dz * dz <= 3.0 * 3.0: # Purple ring radius tolerance
					hover_enemy = true
					show_outline = true
			d.set_outline_visible(show_outline)

	if hover_enemy:
		_set_cursor("alt")
	elif is_attack_move_mode:
		_set_cursor("link")
	else:
		_set_cursor("normal")

func _set_cursor(type: String) -> void:
	if current_cursor_type == type:
		return
	current_cursor_type = type

	var tex: Texture2D = cursor_normal
	if type == "alt" and cursor_alt:
		tex = cursor_alt
	elif type == "link" and cursor_link:
		tex = cursor_link

	if tex:
		Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, Vector2.ZERO)

func _update_telemetry(delta: float) -> void:
	frame_time_acc += delta
	frame_time_count += 1
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_fps_update_time >= 0.5:
		if frame_time_count > 0:
			current_frame_time_ms = (frame_time_acc / float(frame_time_count)) * 1000.0
		frame_time_acc = 0.0
		frame_time_count = 0
		last_fps_update_time = now

		if OS.has_feature("web"):
			var shadow_flag: int = 1 if (directional_light and directional_light.shadow_enabled) else 0
			var aa_flag := "OFF"
			var vp := get_viewport()
			if vp.msaa_3d != Viewport.MSAA_DISABLED:
				aa_flag = "MSAA-2X"
			elif fxaa_effect and fxaa_effect.visible:
				aa_flag = "FXAA-3D"
			var dc = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
			var prim = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
			var raf_val = JavaScriptBridge.eval("window._gamex1_engine_fps = %d; window._gamex1_frame_time_ms = %.2f; window._gamex1_aa_mode = '%s'; window._gamex1_shadows = %d; window._gamex1_draw_calls = %d; window._gamex1_prims = %d; window._gamex1_raf ? window._gamex1_raf.fps : 0;" % [Engine.get_frames_per_second(), current_frame_time_ms, aa_flag, shadow_flag, dc, prim])
			if raf_val != null:
				cached_raf_hz = int(raf_val)

		_update_hud()

func _update_hud() -> void:
	if status_hud:
		status_hud.set_fps(Engine.get_frames_per_second())

	if debug_panel and debug_panel.visible and telemetry_label and hero:
		var h_vel = Vector2(hero.velocity.x, hero.velocity.z).length()
		var cam_mode = camera_controller.get_mode_name() if camera_controller else "Unknown"
		var draw_calls = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		var prims = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		var shadow_str = "ON" if (directional_light and directional_light.shadow_enabled) else "OFF"
		var raf_str = " | Browser RAF: %d Hz" % cached_raf_hz if OS.has_feature("web") else ""
		var aa_mode := "OFF"
		var vp := get_viewport()
		if vp.msaa_3d != Viewport.MSAA_DISABLED:
			aa_mode = "MSAA-2X"
		elif fxaa_effect and fxaa_effect.visible:
			aa_mode = "FXAA-3D"

		telemetry_label.text = "FPS: %d (%.1f ms)%s | DrawCalls: %d | Prims: %d | Shadows: [%s] (F1) | AA: [%s] (F2/F4)\nCaitlyn: (%.1f, %.1f) | HP: %d/%d | AS: %.2f (+%d%%) | Speed: %.1f m/s | Cam: [%s]" % [
			Engine.get_frames_per_second(),
			current_frame_time_ms,
			raf_str,
			draw_calls,
			prims,
			shadow_str,
			aa_mode,
			hero.global_position.x,
			hero.global_position.z,
			roundi(hero.hp),
			roundi(hero.max_hp),
			hero.attack_speed * (1.0 + hero.attack_speed_bonus),
			roundi(hero.attack_speed_bonus * 100.0),
			h_vel,
			cam_mode
		]

func _toggle_shadows() -> void:
	if directional_light:
		directional_light.shadow_enabled = not directional_light.shadow_enabled
		_update_hud()

func _on_camera_mode_changed(_mode: MobaCamera.Mode, _mode_name: String) -> void:
	_update_hud()
