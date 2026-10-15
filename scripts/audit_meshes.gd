extends SceneTree

func _init() -> void:
	var main_scene = load("res://scenes/main.tscn")
	var root_node = main_scene.instantiate()
	root.add_child(root_node)

	var meshes: Array[MeshInstance3D] = []
	_find_meshes(root_node, meshes)

	print("[game-x1-audit] MESH CLASSES & SAMPLES:")
	var classes = {}
	for m in meshes:
		if m.mesh:
			var cls = m.mesh.get_class()
			if not classes.has(cls):
				classes[cls] = {"count": 0, "sample_faces": m.mesh.get_faces().size() / 3, "sample_node": m.name}
			classes[cls]["count"] += 1

	for k in classes.keys():
		var info = classes[k]
		print("  Class: %-15s | Instances: %3d | Faces each: %5d | Total faces: %7d" % [
			k, info["count"], info["sample_faces"], info["count"] * info["sample_faces"]
		])

	quit(0)

func _find_meshes(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		out.append(node)
	for child in node.get_children():
		_find_meshes(child, out)
