extends SceneTree

func _init() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	if scene == null:
		push_error("Could not load main.tscn")
		quit(1)
		return
	var main := scene.instantiate()
	root.add_child(main)
	current_scene = main
	_test.call_deferred(main)

func _test(main: Node) -> void:
	for i in range(10):
		await process_frame

	var fxaa_rect := main.get_node_or_null("PostProcessLayer/FXAAEffect") as ColorRect
	var light := main.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	var vp := root.get_viewport()
	var bench := root.get_node_or_null("PerfBench")

	assert(fxaa_rect != null, "FXAAEffect not found")
	assert(light != null, "DirectionalLight3D not found")

	print("[VerifyHotkeys] Initial FXAA visible: ", fxaa_rect.visible)
	print("[VerifyHotkeys] Initial FXAA layout anchors: ", fxaa_rect.anchor_right, ", ", fxaa_rect.anchor_bottom)
	assert(fxaa_rect.visible == true, "FXAA should be visible by default")
	assert(fxaa_rect.anchor_right == 1.0 and fxaa_rect.anchor_bottom == 1.0, "FXAA should be fullscreen anchor (1,1)")
	assert(fxaa_rect.offset_left == 0.0 and fxaa_rect.offset_top == 0.0, "FXAA offsets should be 0")

	# Test F4 toggle
	var ev_f4 := InputEventKey.new()
	ev_f4.keycode = KEY_F4
	ev_f4.pressed = true
	main._unhandled_input(ev_f4)
	await process_frame
	print("[VerifyHotkeys] After F4 press, FXAA visible: ", fxaa_rect.visible)
	assert(fxaa_rect.visible == false, "FXAA should be hidden after F4")

	main._unhandled_input(ev_f4)
	await process_frame
	print("[VerifyHotkeys] After second F4 press, FXAA visible: ", fxaa_rect.visible)
	assert(fxaa_rect.visible == true, "FXAA should be visible again after second F4")

	# Test F1 toggle (shadows)
	var initial_shadows: bool = light.shadow_enabled
	var ev_f1 := InputEventKey.new()
	ev_f1.keycode = KEY_F1
	ev_f1.pressed = true
	main._unhandled_input(ev_f1)
	await process_frame
	print("[VerifyHotkeys] After F1 press, shadows: ", light.shadow_enabled)
	assert(light.shadow_enabled != initial_shadows, "Shadows should toggle on F1")

	main._unhandled_input(ev_f1)
	await process_frame
	assert(light.shadow_enabled == initial_shadows, "Shadows should return to initial state")

	# Test F2 toggle (MSAA)
	var initial_msaa: int = vp.msaa_3d
	var ev_f2 := InputEventKey.new()
	ev_f2.keycode = KEY_F2
	ev_f2.pressed = true
	main._unhandled_input(ev_f2)
	await process_frame
	print("[VerifyHotkeys] After F2 press, MSAA: ", vp.msaa_3d)
	assert(vp.msaa_3d != initial_msaa, "MSAA should toggle on F2")

	main._unhandled_input(ev_f2)
	await process_frame
	assert(vp.msaa_3d == initial_msaa, "MSAA should return to initial state")

	# Test PerfBench crop switch and restoration to full
	if bench:
		bench.set("_main", main)
		bench.call("_apply_config", "crop_fxaa_copy")
		await process_frame
		print("[VerifyHotkeys] In crop_fxaa_copy, layout offsets: ", fxaa_rect.offset_left, ", ", fxaa_rect.offset_top, ", ", fxaa_rect.offset_right, ", ", fxaa_rect.offset_bottom)
		assert(fxaa_rect.anchor_right == 0.0, "Anchor right should be 0.0 during crop")
		assert(fxaa_rect.offset_right > 0.0, "Offset right should match ROI width")

		# Now restore full
		bench.call("_apply_config", "full")
		await process_frame
		print("[VerifyHotkeys] Restored full, anchors: ", fxaa_rect.anchor_right, ", ", fxaa_rect.anchor_bottom)
		assert(fxaa_rect.anchor_right == 1.0 and fxaa_rect.anchor_bottom == 1.0, "Anchor right/bottom should restore to 1.0")
		assert(fxaa_rect.offset_left == 0.0 and fxaa_rect.offset_top == 0.0, "Offsets should restore to 0")
		assert(fxaa_rect.offset_right == 0.0 and fxaa_rect.offset_bottom == 0.0, "Offsets should restore to 0")

	print("[VerifyHotkeys] ALL HOTKEY & FULL RESTORATION CHECKS PASSED!")
	quit(0)
