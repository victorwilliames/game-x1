extends SceneTree

func _init() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0

	var main_scene = load("res://scenes/main.tscn")
	var root_node = main_scene.instantiate()
	root.add_child(root_node)

	_run_profiling(root_node)

func _run_profiling(main_node: Node) -> void:
	print("\n=======================================================")
	print("[PROFILE-300FPS] SYSTEMIC SUBSYSTEM DECOMPOSITION")
	print("=======================================================")

	# 1. Baseline Full Scene
	var base = await _measure(100)
	print("1. BASELINE (Full Scene):               Avg: %5.2f ms (%5.1f FPS) | DrawCalls: %2d | Prims: %d" % [base.avg_ms, base.fps, base.draw_calls, base.prims])

	# 2a. Hide StatusHUD alone
	var hud_node: Control = main_node.get_node_or_null("UI/StatusHUD")
	if hud_node:
		hud_node.visible = false
	var no_hud = await _measure(100)
	print("2a. NO STATUS HUD:                      Avg: %5.2f ms (%5.1f FPS) | DrawCalls: %2d | Prims: %d" % [no_hud.avg_ms, no_hud.fps, no_hud.draw_calls, no_hud.prims])
	print("    --> StatusHUD Overhead:             Cost: %+5.2f ms (%+2d Draw Calls)" % [base.avg_ms - no_hud.avg_ms, base.draw_calls - no_hud.draw_calls])
	if hud_node:
		hud_node.visible = true

	# 2b. Hide FloatingBars alone
	var bars_node: Control = main_node.get_node_or_null("UI/FloatingBars")
	if bars_node:
		bars_node.visible = false
	var no_bars = await _measure(100)
	print("2b. NO FLOATING BARS:                   Avg: %5.2f ms (%5.1f FPS) | DrawCalls: %2d | Prims: %d" % [no_bars.avg_ms, no_bars.fps, no_bars.draw_calls, no_bars.prims])
	print("    --> FloatingBars Overhead:          Cost: %+5.2f ms (%+2d Draw Calls)" % [base.avg_ms - no_bars.avg_ms, base.draw_calls - no_bars.draw_calls])
	if bars_node:
		bars_node.visible = true

	# 2c. Hide 2D UI entirely
	var ui_node: CanvasLayer = main_node.get_node_or_null("UI")
	if ui_node:
		ui_node.visible = false
	var no_ui = await _measure(100)
	print("2c. NO 2D UI (3D Only):                 Avg: %5.2f ms (%5.1f FPS) | DrawCalls: %2d | Prims: %d" % [no_ui.avg_ms, no_ui.fps, no_ui.draw_calls, no_ui.prims])
	print("    --> Entire 2D UI Overhead:          Cost: %+5.2f ms (%+2d Draw Calls)" % [base.avg_ms - no_ui.avg_ms, base.draw_calls - no_ui.draw_calls])
	if ui_node:
		ui_node.visible = true

	# 3. Disable PostProcessLayer (FXAA-3D)
	var pp_layer: CanvasLayer = main_node.get_node_or_null("PostProcessLayer")
	if pp_layer:
		pp_layer.visible = false
	var no_fxaa = await _measure(100)
	print("3. NO FXAA POST-PROCESS:                Avg: %5.2f ms (%5.1f FPS) | DrawCalls: %2d | Prims: %d" % [no_fxaa.avg_ms, no_fxaa.fps, no_fxaa.draw_calls, no_fxaa.prims])
	print("   --> FXAA-3D Overhead:                Cost: %+5.2f ms (%+2d Draw Calls)" % [base.avg_ms - no_fxaa.avg_ms, base.draw_calls - no_fxaa.draw_calls])
	if pp_layer:
		pp_layer.visible = true

	# 4. Disable Shadows
	var dir_light: DirectionalLight3D = main_node.get_node_or_null("DirectionalLight3D")
	if dir_light:
		dir_light.shadow_enabled = false
	var no_shadow = await _measure(100)
	print("4. NO DIRECTIONAL SHADOW:               Avg: %5.2f ms (%5.1f FPS) | DrawCalls: %2d | Prims: %d" % [no_shadow.avg_ms, no_shadow.fps, no_shadow.draw_calls, no_shadow.prims])
	print("   --> Shadow Pass Overhead:            Cost: %+5.2f ms (%+2d Draw Calls)" % [base.avg_ms - no_shadow.avg_ms, base.draw_calls - no_shadow.draw_calls])
	if dir_light:
		dir_light.shadow_enabled = true

	# 5. Hide RangeIndicator & Markers
	var fx: Node3D = main_node.get_node_or_null("Effects")
	if fx:
		fx.visible = false
	var no_fx = await _measure(100)
	print("5. NO RANGE/CLICK EFFECTS:              Avg: %5.2f ms (%5.1f FPS) | DrawCalls: %2d | Prims: %d" % [no_fx.avg_ms, no_fx.fps, no_fx.draw_calls, no_fx.prims])
	print("   --> Effects Overhead:                Cost: %+5.2f ms (%+2d Draw Calls)" % [base.avg_ms - no_fx.avg_ms, base.draw_calls - no_fx.draw_calls])
	if fx:
		fx.visible = true

	# 6. Hide Hero (Caitlyn 18.5k tris + skeleton)
	var hero_node = main_node.get_node_or_null("Hero")
	if hero_node:
		hero_node.visible = false
	var no_hero = await _measure(100)
	print("6. NO CAITLYN MESH & SKELETON:          Avg: %5.2f ms (%5.1f FPS) | DrawCalls: %2d | Prims: %d" % [no_hero.avg_ms, no_hero.fps, no_hero.draw_calls, no_hero.prims])
	print("   --> Caitlyn Mesh/Skel Overhead:      Cost: %+5.2f ms (%+2d Draw Calls)" % [base.avg_ms - no_hero.avg_ms, base.draw_calls - no_hero.draw_calls])
	if hero_node:
		hero_node.visible = true

	# 7. Hide Arena Floor & Grid
	var arena_node = main_node.get_node_or_null("Arena")
	if arena_node:
		arena_node.visible = false
	var no_arena = await _measure(100)
	print("7. NO ARENA FLOOR & GRID:               Avg: %5.2f ms (%5.1f FPS) | DrawCalls: %2d | Prims: %d" % [no_arena.avg_ms, no_arena.fps, no_arena.draw_calls, no_arena.prims])
	print("   --> Arena Floor/Grid Overhead:       Cost: %+5.2f ms (%+2d Draw Calls)" % [base.avg_ms - no_arena.avg_ms, base.draw_calls - no_arena.draw_calls])
	if arena_node:
		arena_node.visible = true

	print("=======================================================\n")
	quit(0)

func _measure(frame_count: int) -> Dictionary:
	var total_time_usec: int = 0
	var last_draw_calls: int = 0
	var last_primitives: int = 0

	for i in range(frame_count):
		var t0 = Time.get_ticks_usec()
		await process_frame
		var elapsed = Time.get_ticks_usec() - t0
		if i >= 10:
			total_time_usec += elapsed
		last_draw_calls = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		last_primitives = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)

	var valid = frame_count - 10
	var avg_ms = (float(total_time_usec) / float(valid)) / 1000.0
	var fps = 1000.0 / max(0.001, avg_ms)
	return {
		"avg_ms": avg_ms,
		"fps": fps,
		"draw_calls": last_draw_calls,
		"prims": last_primitives
	}
