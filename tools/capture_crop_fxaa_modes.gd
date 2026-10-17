extends SceneTree

## Screenshot-only experiment; crop modes intentionally leave outer world unfiltered.
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
	var modes := ["full", "crop_fxaa_draw", "crop_fxaa_copy", "no_fxaa"]
	for mode in modes:
		bench.call("_apply_config", mode)
		for i in range(15):
			await process_frame
		var image := root.get_viewport().get_texture().get_image()
		var name := "res://docs/migration/visual/crop_fxaa_%s.png" % mode
		var err := image.save_png(name)
		if err != OK:
			push_error("Failed screenshot: %s error %s" % [name, err])
			bench.call("_apply_config", "full")
			quit(1)
			return
		print("[CaptureCropFXAA] Saved ", name)
	bench.call("_apply_config", "full")
	for i in range(5):
		await process_frame
	print("[CaptureCropFXAA] Restored production FXAA")
	quit(0)
