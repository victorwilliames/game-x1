extends SceneTree

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	print("[test_camera] Loading Main scene for camera controller verification...")
	var err = change_scene_to_file("res://scenes/main.tscn")
	if err != OK:
		printerr("[test_camera] FAILED: Could not load main scene, error: %d" % err)
		quit(1)
		return

	await process_frame
	await process_frame

	var main = current_scene
	var hero: Hero = main.get_node_or_null("Hero")
	var cam: MobaCamera = main.get_node_or_null("CameraPivot")

	if not hero or not cam:
		printerr("[test_camera] FAILED: Hero or CameraPivot not found in scene")
		quit(1)
		return

	# 1. Initial State: Free mode by default, centered at hero
	print("[test_camera] Check 1: Initial state (Free mode, centered on hero)...")
	if cam.current_mode != MobaCamera.Mode.FREE:
		printerr("[test_camera] FAILED: Camera should start in FREE mode, but was %d" % cam.current_mode)
		quit(1)
		return

	var dist_to_hero = cam.global_position.distance_to(hero.global_position)
	if dist_to_hero > 0.5:
		printerr("[test_camera] FAILED: Camera should start near hero, but dist was %.2f" % dist_to_hero)
		quit(1)
		return

	# 2. Toggle Lock (Y)
	print("[test_camera] Check 2: Toggle Lock (Y)...")
	cam.toggle_lock()
	if cam.current_mode != MobaCamera.Mode.LOCKED:
		printerr("[test_camera] FAILED: Mode should be LOCKED after toggle")
		quit(1)
		return

	cam.toggle_lock()
	if cam.current_mode != MobaCamera.Mode.FREE:
		printerr("[test_camera] FAILED: Mode should return to FREE after second toggle")
		quit(1)
		return

	# 3. Space Bar centering
	print("[test_camera] Check 3: Space Bar centering...")
	cam.global_position = Vector3(8.0, 0.0, 5.0)
	cam.is_space_held = true
	if not cam.is_following_hero():
		printerr("[test_camera] FAILED: is_following_hero should be true when space is held")
		quit(1)
		return

	# Simulate follow steps
	for i in range(30):
		cam._process(1.0 / 60.0)

	var dist_after_space = cam.global_position.distance_to(hero.global_position)
	if dist_after_space >= 8.0:
		printerr("[test_camera] FAILED: Camera did not interpolate towards hero when space held")
		quit(1)
		return

	cam.is_space_held = false
	if cam.is_following_hero():
		printerr("[test_camera] FAILED: is_following_hero should be false after space released in FREE mode")
		quit(1)
		return

	# 4. Zoom bounds
	print("[test_camera] Check 4: Zoom clamping limits...")
	for i in range(25):
		cam.zoom_in()
	if cam.target_distance < cam.min_zoom:
		printerr("[test_camera] FAILED: target_distance exceeded min_zoom (%.2f < %.2f)" % [cam.target_distance, cam.min_zoom])
		quit(1)
		return

	for i in range(25):
		cam.zoom_out()
	if cam.target_distance > cam.max_zoom:
		printerr("[test_camera] FAILED: target_distance exceeded max_zoom (%.2f > %.2f)" % [cam.target_distance, cam.max_zoom])
		quit(1)
		return

	# 5. Arena boundary clamping
	print("[test_camera] Check 5: Arena boundary clamping...")
	cam.global_position = Vector3(100.0, 0.0, -100.0)
	cam._clamp_pivot_position()
	if cam.global_position.x > cam.max_bound_x or cam.global_position.z < cam.min_bound_z:
		printerr("[test_camera] FAILED: Camera position exceeded boundary limits: %s" % cam.global_position)
		quit(1)
		return

	# 6. Event handling (Space, Y, Wheel)
	print("[test_camera] Check 6: Event handling via handle_input()...")
	var key_y_event = InputEventKey.new()
	key_y_event.keycode = KEY_Y
	key_y_event.pressed = true
	var handled_y = cam.handle_input(key_y_event)
	if not handled_y or cam.current_mode != MobaCamera.Mode.LOCKED:
		printerr("[test_camera] FAILED: handle_input did not process KEY_Y")
		quit(1)
		return

	var key_space_event = InputEventKey.new()
	key_space_event.keycode = KEY_SPACE
	key_space_event.pressed = true
	var handled_space = cam.handle_input(key_space_event)
	if not handled_space or not cam.is_space_held:
		printerr("[test_camera] FAILED: handle_input did not process KEY_SPACE press")
		quit(1)
		return

	key_space_event.pressed = false
	cam.handle_input(key_space_event)
	if cam.is_space_held:
		printerr("[test_camera] FAILED: handle_input did not process KEY_SPACE release")
		quit(1)
		return

	# Reset mode to FREE
	cam.set_mode(MobaCamera.Mode.FREE)

	# 7. Middle Mouse Button (MMB) Drag Navigation
	print("[test_camera] Check 7: Middle Mouse Drag (MMB) panning...")
	cam.global_position = Vector3(0, 0, 0)
	var mmb_press = InputEventMouseButton.new()
	mmb_press.button_index = MOUSE_BUTTON_MIDDLE
	mmb_press.pressed = true
	var handled_mmb = cam.handle_input(mmb_press)
	if not handled_mmb or not cam.is_mmb_dragging:
		printerr("[test_camera] FAILED: MMB press did not start drag")
		quit(1)
		return

	if cam.get_mode_name() != "Panning (MMB)":
		printerr("[test_camera] FAILED: Expected mode name 'Panning (MMB)', got '%s'" % cam.get_mode_name())
		quit(1)
		return

	var mouse_motion = InputEventMouseMotion.new()
	mouse_motion.relative = Vector2(80.0, -40.0)
	var handled_motion = cam.handle_input(mouse_motion)
	if not handled_motion or cam.global_position == Vector3.ZERO:
		printerr("[test_camera] FAILED: Mouse motion during MMB drag did not move camera pivot")
		quit(1)
		return

	var mmb_release = InputEventMouseButton.new()
	mmb_release.button_index = MOUSE_BUTTON_MIDDLE
	mmb_release.pressed = false
	cam.handle_input(mmb_release)
	if cam.is_mmb_dragging:
		printerr("[test_camera] FAILED: MMB release did not stop drag")
		quit(1)
		return

	# 8. Responsive Edge Margins
	print("[test_camera] Check 8: Responsive edge margin bounds...")
	var test_vp_width = 1280.0
	var test_vp_height = 720.0
	var calc_margin_x = clamp(test_vp_width * cam.edge_margin_ratio_x, cam.edge_margin_min_px, cam.edge_margin_max_px)
	var calc_margin_y = clamp(test_vp_height * cam.edge_margin_ratio_y, cam.edge_margin_min_px, cam.edge_margin_max_px)
	if calc_margin_x < 36.0 or calc_margin_y < 36.0:
		printerr("[test_camera] FAILED: Responsive margins too narrow for windowed mode: (%f, %f)" % [calc_margin_x, calc_margin_y])
		quit(1)
		return

	print("[test_camera] SUCCESS: All 8 camera controller checks passed cleanly!")
	quit(0)
