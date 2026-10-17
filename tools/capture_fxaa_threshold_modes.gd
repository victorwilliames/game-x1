extends SceneTree

## Full-frame FXAA threshold variants. Screenshots need visual review.
func _init() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	if scene == null:
		quit(1)
		return
	var main := scene.instantiate()
	root.add_child(main)
	current_scene = main
	_capture.call_deferred(main)

func _capture(main: Node) -> void:
	for i in range(25):
		await process_frame
	var bench := root.get_node_or_null("PerfBench")
	if bench == null:
		push_error("PerfBench autoload missing")
		quit(1)
		return
	bench.set("_main", main)
	var modes := ["full", "fxaa_thr035", "fxaa_thr050", "fxaa_thr070", "no_fxaa"]
	for mode in modes:
		bench.call("_apply_config", mode)
		for i in range(15):
			await process_frame
		var image := root.get_viewport().get_texture().get_image()
		var name := "res://docs/migration/visual/fxaa_threshold_%s.png" % mode
		var err := image.save_png(name)
		if err != OK:
			push_error("Failed screenshot: %s error %s" % [name, err])
			bench.call("_apply_config", "full")
			quit(1)
			return
		print("[CaptureFXAAThreshold] Saved ", name)
	bench.call("_apply_config", "full")
	for i in range(5):
		await process_frame
	print("[CaptureFXAAThreshold] Restored production FXAA")
	quit(0)
