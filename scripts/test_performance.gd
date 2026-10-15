extends SceneTree

func _init() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0

	var main_scene = load("res://scenes/main.tscn")
	var root_node = main_scene.instantiate()
	root.add_child(root_node)

	_run_benchmark(root_node)

func _run_benchmark(main_node: Node) -> void:
	var dir_light: DirectionalLight3D = main_node.get_node_or_null("DirectionalLight3D")
	
	print("[game-x1-bench] --- PHASE 1: Baseline with Shadows ON (VSync Disabled) ---")
	var stats_shadows_on = await _measure_phase(100)

	if dir_light:
		dir_light.shadow_enabled = false
	print("[game-x1-bench] --- PHASE 2: Performance with Shadows OFF (VSync Disabled) ---")
	var stats_shadows_off = await _measure_phase(100)

	print("[game-x1-bench] ==================================================")
	print("[game-x1-bench] PERFORMANCE DIAGNOSTIC REPORT (VSYNC DISABLED)")
	print("[game-x1-bench] ==================================================")
	print("[game-x1-bench] SHADOWS ON : Avg: %.2f ms (Min: %.2f, Max: %.2f) | Uncapped FPS: %.1f | Draw Calls: %d | Primitives: %d" % [
		stats_shadows_on.avg_time_ms,
		stats_shadows_on.min_time_ms,
		stats_shadows_on.max_time_ms,
		1000.0 / max(0.001, stats_shadows_on.avg_time_ms),
		stats_shadows_on.draw_calls,
		stats_shadows_on.primitives
	])
	print("[game-x1-bench] SHADOWS OFF: Avg: %.2f ms (Min: %.2f, Max: %.2f) | Uncapped FPS: %.1f | Draw Calls: %d | Primitives: %d" % [
		stats_shadows_off.avg_time_ms,
		stats_shadows_off.min_time_ms,
		stats_shadows_off.max_time_ms,
		1000.0 / max(0.001, stats_shadows_off.avg_time_ms),
		stats_shadows_off.draw_calls,
		stats_shadows_off.primitives
	])
	var diff_time = stats_shadows_on.avg_time_ms - stats_shadows_off.avg_time_ms
	var diff_calls = stats_shadows_on.draw_calls - stats_shadows_off.draw_calls
	print("[game-x1-bench] SHADOW IMPACT: %+.2f ms/frame (%+d draw calls)" % [diff_time, diff_calls])
	print("[game-x1-bench] 120 FPS Target Budget: 8.33 ms")
	print("[game-x1-bench] ==================================================")
	quit(0)

func _measure_phase(frame_count: int) -> Dictionary:
	var total_time_usec: int = 0
	var min_time_usec: int = 999999999
	var max_time_usec: int = 0
	var last_draw_calls: int = 0
	var last_primitives: int = 0

	for i in range(frame_count):
		var t0 = Time.get_ticks_usec()
		await process_frame
		var elapsed = Time.get_ticks_usec() - t0
		if i >= 10:
			total_time_usec += elapsed
			if elapsed < min_time_usec:
				min_time_usec = elapsed
			if elapsed > max_time_usec:
				max_time_usec = elapsed

		last_draw_calls = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		last_primitives = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)

	var valid_frames = frame_count - 10
	var avg_time_ms = (float(total_time_usec) / float(valid_frames)) / 1000.0
	return {
		"avg_time_ms": avg_time_ms,
		"min_time_ms": float(min_time_usec) / 1000.0,
		"max_time_ms": float(max_time_usec) / 1000.0,
		"draw_calls": last_draw_calls,
		"primitives": last_primitives
	}
