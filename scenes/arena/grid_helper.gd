@tool
extends MeshInstance3D
class_name MobaGridHelper

## 1:1 Port of THREE.GridHelper(80, 40, '#c29d53', '#162838')
## Elevated at y = 0.01 above floor plane, unshaded 1px line primitives.

@export var size: float = 80.0:
	set(val):
		size = val
		_rebuild_grid()

@export var divisions: int = 40:
	set(val):
		divisions = val
		_rebuild_grid()

@export var color_center: Color = Color(0.7608, 0.6157, 0.3255, 1.0): # #c29d53
	set(val):
		color_center = val
		_rebuild_grid()

@export var color_grid: Color = Color(0.0863, 0.1569, 0.2196, 1.0): # #162838
	set(val):
		color_grid = val
		_rebuild_grid()

func _ready() -> void:
	_rebuild_grid()

func _rebuild_grid() -> void:
	if divisions <= 0 or size <= 0:
		return

	var step: float = size / float(divisions)
	var half_size: float = size * 0.5
	var center_idx: int = divisions / 2

	var vertices := PackedVector3Array()
	var colors := PackedColorArray()

	for i in range(divisions + 1):
		var k: float = -half_size + float(i) * step
		var col: Color = color_center if i == center_idx else color_grid

		# Line parallel to X axis (x varies from -half_size to half_size, z = k)
		vertices.append(Vector3(-half_size, 0.0, k))
		colors.append(col)
		vertices.append(Vector3(half_size, 0.0, k))
		colors.append(col)

		# Line parallel to Z axis (z varies from -half_size to half_size, x = k)
		vertices.append(Vector3(k, 0.0, -half_size))
		colors.append(col)
		vertices.append(Vector3(k, 0.0, half_size))
		colors.append(col)

	var arr_mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors

	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	mesh = arr_mesh

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = mat

	position = Vector3(0.0, 0.01, 0.0)
