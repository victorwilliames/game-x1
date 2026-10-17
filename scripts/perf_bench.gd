extends Node
## PerfBench — in-game benchmark harness (autoload). Completely inactive unless requested.
##
## Runs inside the REAL game build (windowed native or Web), drives scripted gameplay
## scenarios and records, per frame, separately:
##   - frame interval (wall clock between consecutive frames, includes present/wait)
##   - CPU time spent in scripts (Performance.TIME_PROCESS / TIME_PHYSICS_PROCESS)
##   - CPU time spent by the renderer submitting the viewport (viewport_get_measured_render_time_cpu)
##   - GPU time of the viewport (viewport_get_measured_render_time_gpu; 0 => NOT AVAILABLE, never "free")
##   - draw calls / primitives
##
## Native:  godot --path . --windowed --resolution 1280x720 -- --bench
##            [--bench-out=ABS_PATH.json] [--bench-runs=3] [--bench-sec=12] [--bench-warmup=6]
##            [--bench-configs=full,no_fxaa,no_shadows,no_ui,msaa2x] [--bench-label=name]
## Web:     index.html?bench=1&runs=3&sec=12&warmup=6&configs=full&label=name
##          -> result JSON string is published in window._gamex1_bench_result
##
## FXAA decomposition (available natively and on Web):
##   --bench-configs=full,pass_only,crop_draw,crop_copy,no_fxaa
## Full-screen AA alternative comparison: full,msaa2x,msaa4x,no_fxaa
##   full:       screen copy/compositing AND full FXAA filter (production)
##   pass_only:  fullscreen auto-copy + fullscreen passthrough shader
##   crop_draw:  fullscreen auto-copy + cropped central 50%x50% passthrough
##   crop_copy:  explicit BackBufferCopy COPY_MODE_RECT + cropped passthrough
##   crop_fxaa_draw:  full screen copy + genuine FXAA on center 25% of viewport
##   crop_fxaa_copy:  regional BackBufferCopy + genuine FXAA on center 25%
##   no_fxaa:    no post-processing layer (no copy, no quad)
##   crop_* are diagnostic ONLY: center 25% viewport area. crop_fxaa_* use
##   real FXAA INSIDE the crop but leave outer scene aliased, with possible
##   boundary seams. They do NOT establish full-scene visual parity.
##   Differences approximate
##   costs under matched conditions; not precise isolated GPU timings.
##
## Configs are INTERLEAVED per round (A,B,C,A,B,C,...) so thermal / turbo drift on laptops
## affects every config equally instead of biasing whichever ran last.

const SCENARIOS: Array[String] = ["idle", "movement", "kiting", "combat", "camera"]
const MOVE_POINTS: Array[Vector3] = [
	Vector3(-10, 0, -6), Vector3(10, 0, -4), Vector3(-6, 0, 8), Vector3(8, 0, 6)
]
const KITE_OFFSETS: Array[Vector3] = [
	Vector3(-3, 0, -2), Vector3(3, 0, -2), Vector3(-2, 0, 2), Vector3(2, 0, 2)
]

var _opts: Dictionary = {}
var _main: Node = null
var _vp_rid: RID
var _results: Array = []
var _info: Dictionary = {}

# Benchmark-only material swap. Production FXAA shader/material remains untouched.
# pass_only keeps the full-screen screen-texture read and blit, but skips the
# antialiasing filter. Combined with full and no_fxaa it isolates pass overhead.
var _baseline_fxaa_material: Material = null
var _passthrough_material: ShaderMaterial = null
var _benchmark_region_copy: BackBufferCopy = null

# Fixed central region simplifies the experiment: half viewport width and
# half viewport height (25% pixels). This is deliberately NOT a character
# tracker, NOT production AA, and NOT intended to preserve every 3D edge.
const BENCH_CROP_MARGIN_PIXELS := 16.0

func _benchmark_crop_rect() -> Rect2:
	var vp_size := get_viewport().get_visible_rect().size
	return Rect2((vp_size * 0.25).round(), (vp_size * 0.5).round())

func _configure_benchmark_copy(fxaa_rect: ColorRect, cfg: String, roi: Rect2) -> void:
	var regional_copy := cfg == "crop_copy" or cfg == "crop_fxaa_copy"
	if regional_copy and _benchmark_region_copy == null:
		_benchmark_region_copy = BackBufferCopy.new()
		_benchmark_region_copy.name = "BenchRegionBackBufferCopy"
		_benchmark_region_copy.copy_mode = BackBufferCopy.COPY_MODE_DISABLED
		var parent_node := fxaa_rect.get_parent()
		parent_node.add_child(_benchmark_region_copy)
		parent_node.move_child(_benchmark_region_copy, fxaa_rect.get_index())

	if _benchmark_region_copy:
		if regional_copy:
			# Important: explicitly copy only the diagnostic region, preventing the
			# automatic fullscreen back-buffer copy from hint_screen_texture.
			var viewport_rect := get_viewport().get_visible_rect()
			_benchmark_region_copy.rect = roi.grow(BENCH_CROP_MARGIN_PIXELS).intersection(viewport_rect)
			_benchmark_region_copy.copy_mode = BackBufferCopy.COPY_MODE_RECT
		else:
			# A disabled BackBufferCopy does NOT suppress the usual auto full
			# screen capture for pass_only/crop_draw/full.
			_benchmark_region_copy.copy_mode = BackBufferCopy.COPY_MODE_DISABLED

	# Reset to exact scene-authored fullscreen layout when not testing a crop.
	# These changes occur only in benchmark mode (_run), never in normal play.
	var crop := cfg == "crop_draw" or cfg == "crop_copy" or cfg == "crop_fxaa_draw" or cfg == "crop_fxaa_copy"
	fxaa_rect.anchor_left = 0.0
	fxaa_rect.anchor_top = 0.0
	fxaa_rect.anchor_right = 0.0 if crop else 1.0
	fxaa_rect.anchor_bottom = 0.0 if crop else 1.0
	fxaa_rect.offset_left = roi.position.x if crop else 0.0
	fxaa_rect.offset_top = roi.position.y if crop else 0.0
	fxaa_rect.offset_right = roi.end.x if crop else 0.0
	fxaa_rect.offset_bottom = roi.end.y if crop else 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	_opts = _parse_options()
	if _opts.is_empty():
		return # inactive: zero per-frame cost
	_run.call_deferred()

# ---------------------------------------------------------------- options
func _parse_options() -> Dictionary:
	var o := {}
	if OS.has_feature("web"):
		var q = JavaScriptBridge.eval("location.search", true)
		if typeof(q) != TYPE_STRING or not String(q).contains("bench=1"):
			return {}
		for pair in String(q).trim_prefix("?").split("&"):
			var kv: PackedStringArray = String(pair).split("=")
			if kv.size() == 2:
				o[kv[0]] = kv[1].uri_decode()
	else:
		var args := OS.get_cmdline_user_args()
		if not args.has("--bench"):
			return {}
		for a in args:
			if String(a).begins_with("--bench-") and String(a).contains("="):
				var kv: PackedStringArray = String(a).trim_prefix("--bench-").split("=", true, 1)
				o[kv[0]] = kv[1]
		o["bench"] = "1"
	return o

func _opt_i(k: String, d: int) -> int:
	return int(_opts[k]) if _opts.has(k) else d

func _opt_f(k: String, d: float) -> float:
	return float(_opts[k]) if _opts.has(k) else d

# ---------------------------------------------------------------- main flow
func _run() -> void:
	# Let the main scene finish _ready and the first frames settle.
	for i in range(10):
		await get_tree().process_frame
	_main = get_tree().current_scene
	if _main == null or _main.get("hero") == null:
		push_error("[PerfBench] main scene not found")
		get_tree().quit(2)
		return

	_vp_rid = get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(_vp_rid, true)
	if not OS.has_feature("web"):
		Input.warp_mouse(get_viewport().get_visible_rect().size * 0.5)

	var runs := _opt_i("runs", 3)
	var sec := _opt_f("sec", 12.0)
	var warmup := _opt_f("warmup", 6.0)
	var configs: PackedStringArray = String(_opts.get("configs", "full")).split(",")
	_info = _collect_info(runs, sec, warmup, configs)
	print("[PerfBench] start ", JSON.stringify(_info))

	_apply_config("full")
	await _phase("warmup", warmup, false, "full", -1)

	for r in range(runs):
		for cfg in configs:
			_apply_config(cfg)
			await _phase("settle", 1.0, false, cfg, r)
			for sc in SCENARIOS:
				_reset_scene()
				await _phase(sc, sec, true, cfg, r)

	_finish()

func _collect_info(runs: int, sec: float, warmup: float, configs: PackedStringArray) -> Dictionary:
	var vi := Engine.get_version_info()
	var d := {
		"label": String(_opts.get("label", "")),
		"engine": "%s.%s.%s-%s" % [vi.major, vi.minor, vi.patch, vi.status],
		"platform": OS.get_name(),
		"web": OS.has_feature("web"),
		"cpu": OS.get_processor_name(),
		"cpu_threads": OS.get_processor_count(),
		"gpu": RenderingServer.get_video_adapter_name(),
		"gpu_vendor": RenderingServer.get_video_adapter_vendor(),
		"graphics_api": RenderingServer.get_video_adapter_api_version(),
		"rendering_method": str(ProjectSettings.get_setting("rendering/renderer/rendering_method")),
		"window_size": str(DisplayServer.window_get_size()),
		"viewport_size": str(get_viewport().get_visible_rect().size),
		"vsync_mode": DisplayServer.window_get_vsync_mode(),
		"engine_max_fps": Engine.max_fps,
		"screen_refresh_hz": DisplayServer.screen_get_refresh_rate(),
		"runs": runs, "scenario_sec": sec, "warmup_sec": warmup,
		"configs": Array(configs),
		"timestamp": Time.get_datetime_string_from_system(true),
	}
	if OS.has_feature("web"):
		d["user_agent"] = str(JavaScriptBridge.eval("navigator.userAgent", true))
	return d

# ---------------------------------------------------------------- configs
func _apply_config(cfg: String) -> void:
	var pp := _main.get_node_or_null("PostProcessLayer") as CanvasLayer
	var fxaa_rect := _main.get_node_or_null("PostProcessLayer/FXAAEffect") as ColorRect
	var ui := _main.get_node_or_null("UI") as CanvasLayer
	var light := _main.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	var fxaa := true
	var shadows := true
	var ui_on := true
	var msaa := Viewport.MSAA_DISABLED
	match cfg:
		"no_fxaa": fxaa = false
		"no_shadows": shadows = false
		"no_ui": ui_on = false
		"msaa2x":
			fxaa = false
			msaa = Viewport.MSAA_2X
		"msaa4x":
			fxaa = false
			msaa = Viewport.MSAA_4X
		"bare":
			fxaa = false
			shadows = false
			ui_on = false
	# Diagnostic configurations retain the original scene and UI while
	# independently testing fullscreen copy, reduced raster, and regional copy.
	# crop_fxaa_* retain the production shader within the same centered ROI.
	# Normal game mode never invokes this method.
	if fxaa_rect:
		if _baseline_fxaa_material == null:
			_baseline_fxaa_material = fxaa_rect.material
		var passthrough := cfg == "pass_only" or cfg == "crop_draw" or cfg == "crop_copy"
		if passthrough:
			if _passthrough_material == null:
				_passthrough_material = ShaderMaterial.new()
				_passthrough_material.shader = load("res://shaders/screen_passthrough.gdshader") as Shader
			fxaa_rect.material = _passthrough_material
		else:
			fxaa_rect.material = _baseline_fxaa_material
		_configure_benchmark_copy(fxaa_rect, cfg, _benchmark_crop_rect())

	if pp:
		pp.visible = fxaa
	if ui:
		ui.visible = ui_on
	if light:
		light.shadow_enabled = shadows
	get_viewport().msaa_3d = msaa

# ---------------------------------------------------------------- scenarios
func _reset_scene() -> void:
	var hero: Node3D = _main.get("hero")
	_main.set("selected_target", null)
	_main.set("is_attack_move_mode", false)
	if hero:
		hero.global_position = Vector3.ZERO
		if hero.has_method("stop"):
			hero.stop()
	var cam = _main.get("camera_controller")
	if cam:
		cam.set("edge_scroll_enabled", true)
		if cam.has_method("set_mode"):
			cam.set_mode(1) # LOCKED
		if cam.has_method("center_on_target"):
			cam.center_on_target(false)

func _static_dummy() -> Node3D:
	var ds: Array = _main.get("dummies")
	for d in ds:
		if is_instance_valid(d) and d.get("mode") == "static":
			return d
	return ds[0] if ds.size() > 0 else null

func _phase(name: String, seconds: float, record: bool, cfg: String, run_idx: int) -> void:
	var frames := PackedFloat32Array()
	var proc := PackedFloat32Array()
	var phys := PackedFloat32Array()
	var rcpu := PackedFloat32Array()
	var rgpu := PackedFloat32Array()
	var draws := PackedInt32Array()
	var prims := PackedInt32Array()

	var t := 0.0
	var action_t := 0.0
	var action_i := 0
	var last := Time.get_ticks_usec()
	var hero: Node3D = _main.get("hero")
	var cam = _main.get("camera_controller")
	var dummy := _static_dummy()

	if name == "camera" and cam:
		cam.set("edge_scroll_enabled", false)
		cam.set_mode(0) # FREE

	while t < seconds:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		var dt_us := now - last
		last = now
		var dt := dt_us / 1000000.0
		t += dt
		action_t -= dt

		# --- drive gameplay through the same entry points the player input uses
		match name:
			"movement":
				if action_t <= 0.0:
					action_t = 0.45
					_main.call("_handle_right_click", MOVE_POINTS[action_i % MOVE_POINTS.size()])
					action_i += 1
			"kiting":
				if action_t <= 0.0 and dummy and hero:
					action_t = 0.25
					if action_i % 2 == 0 and dummy.get("active"):
						_main.call("_handle_right_click", dummy.global_position)
					else:
						_main.call("_handle_right_click", hero.global_position + KITE_OFFSETS[(action_i / 2) % KITE_OFFSETS.size()])
					action_i += 1
			"combat":
				if action_t <= 0.0 and dummy:
					action_t = 0.5
					if _main.get("selected_target") == null and dummy.get("active"):
						_main.call("_handle_right_click", dummy.global_position)
			"camera":
				if cam:
					cam.set("camera_target", Vector3(cos(t * 0.8) * 22.0, 0.0, sin(t * 0.8) * 16.0))

		if record:
			frames.append(dt_us / 1000.0)
			proc.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
			phys.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
			rcpu.append(RenderingServer.viewport_get_measured_render_time_cpu(_vp_rid) + RenderingServer.get_frame_setup_time_cpu())
			rgpu.append(RenderingServer.viewport_get_measured_render_time_gpu(_vp_rid))
			draws.append(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
			prims.append(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))

	if record:
		var r := _summarize(frames, proc, phys, rcpu, rgpu, draws, prims)
		r["config"] = cfg
		r["scenario"] = name
		r["run"] = run_idx
		_results.append(r)
		print("[PerfBench] run=%d cfg=%-10s %-8s fps=%6.1f mean=%5.2fms p50=%5.2f p95=%5.2f p99=%5.2f | cpu_proc=%4.2f cpu_phys=%4.2f render_cpu=%4.2f gpu=%s | dc=%d" % [
			run_idx, cfg, name, r.fps_mean, r.frame_ms_mean, r.frame_ms_p50, r.frame_ms_p95, r.frame_ms_p99,
			r.cpu_process_ms_mean, r.cpu_physics_ms_mean, r.render_cpu_ms_mean,
			("%4.2f" % r.gpu_ms_mean) if r.gpu_available else "n/a", r.draw_calls_p50])

func _pct(sorted: Array, p: float) -> float:
	if sorted.is_empty():
		return 0.0
	var idx := clampi(int(ceil(p * sorted.size())) - 1, 0, sorted.size() - 1)
	return sorted[idx]

func _mean(a: Variant) -> float:
	if a.size() == 0:
		return 0.0
	var s: float = 0.0
	for v in a:
		s += float(v)
	return s / float(a.size())

func _summarize(frames: PackedFloat32Array, proc: PackedFloat32Array, phys: PackedFloat32Array, rcpu: PackedFloat32Array, rgpu: PackedFloat32Array, draws: PackedInt32Array, prims: PackedInt32Array) -> Dictionary:
	var fs := Array(frames)
	fs.sort()
	var gpu_nonzero: int = 0
	for g in rgpu:
		if g > 0.0:
			gpu_nonzero += 1
	var gpu_ok: bool = gpu_nonzero > (rgpu.size() / 2)
	var ds := Array(draws)
	ds.sort()
	var ps := Array(prims)
	ps.sort()
	var fm := _mean(frames)
	var proc_ms := _mean(proc)
	var phys_ms := _mean(phys)
	var rcpu_ms := _mean(rcpu)
	var rgpu_ms := _mean(rgpu)
	return {
		"frames": frames.size(),
		"fps_mean": 1000.0 / maxf(fm, 0.0001),
		"frame_ms_mean": fm,
		"frame_ms_p50": _pct(fs, 0.50),
		"frame_ms_p95": _pct(fs, 0.95),
		"frame_ms_p99": _pct(fs, 0.99),
		"frame_ms_max": fs.back() if not fs.is_empty() else 0.0,
		"cpu_process_ms_mean": proc_ms,
		"cpu_physics_ms_mean": phys_ms,
		"render_cpu_ms_mean": rcpu_ms,
		"gpu_available": gpu_ok,
		"gpu_ms_mean": rgpu_ms if gpu_ok else -1.0,
		"draw_calls_p50": ds[ds.size() / 2] if not ds.is_empty() else 0,
		"primitives_p50": ps[ps.size() / 2] if not ps.is_empty() else 0,
	}

func _finish() -> void:
	# Always restore production graphics after diagnostic runs, including Web.
	_apply_config("full")
	var out := {"info": _info, "results": _results}
	var s := JSON.stringify(out, "  ")
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window._gamex1_bench_result = %s;" % JSON.stringify(s), true)
		print("[PerfBench] done (web)")
		return
	var path := String(_opts.get("out", "user://perf_bench.json"))
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(s)
		f.close()
	print("[PerfBench] done -> ", ProjectSettings.globalize_path(path))
	get_tree().quit(0)
