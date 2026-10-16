@tool
extends MeshInstance3D
class_name MobaGridHelper

## 1:1 Port of THREE.GridHelper(80, 40, '#c29d53', '#162838')
## High-performance hybrid:
## - Secondary grid lines: ultra-fast PRIMITIVE_LINES (160 vertices, zero fillrate waste)
## - Center gold lines: narrow quad ribbons (width 0.04m) with smooth analytic alpha feathering (anti-aliased at 0 fragment cost)

@export var size: float = 80.0:
	set(val):
		size = val
		_rebuild_grid()

@export var divisions: int = 40:
	set(val):
		divisions = val
		_rebuild_grid()

@export var color_center: Color = Color(0.7608, 0.6157, 0.3255, 0.95): # #c29d53 [194, 157, 83]
	set(val):
		color_center = val
		_rebuild_grid()

@export var color_grid: Color = Color(0.0863, 0.1569, 0.2196, 0.70): # #162838 [22, 40, 56]
	set(val):
		color_grid = val
		_rebuild_grid()

var _gold_ribbon_instance: MeshInstance3D = null

func _ready() -> void:
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rebuild_grid()

func _rebuild_grid() -> void:
	if divisions <= 0 or size <= 0:
		return

	var step: float = size / float(divisions)
	var half_size: float = size * 0.5
	var center_idx: int = divisions / 2

	# 1. Build secondary lines using lightweight PRIMITIVE_LINES
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()

	for i in range(divisions + 1):
		var k: float = -half_size + float(i) * step
		var col: Color = color_center if i == center_idx else color_grid

		# Line parallel to X axis
		vertices.append(Vector3(-half_size, 0.0, k))
		colors.append(col)
		vertices.append(Vector3(half_size, 0.0, k))
		colors.append(col)

		# Line parallel to Z axis
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
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = mat

	# 2. Build anti-aliased gold ribbons for center lines (X=0 and Z=0)
	if _gold_ribbon_instance == null:
		_gold_ribbon_instance = get_node_or_null("GoldRibbons") as MeshInstance3D
		if _gold_ribbon_instance == null:
			_gold_ribbon_instance = MeshInstance3D.new()
			_gold_ribbon_instance.name = "GoldRibbons"
			add_child(_gold_ribbon_instance)

	_gold_ribbon_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var ribbon_half_w := 0.07 # 0.14m width (~2.0px at camera focus)
	var r_verts := PackedVector3Array()
	var r_uvs := PackedVector2Array()
	var r_indices := PackedInt32Array()

	# Ribbon along X axis (z from -w to +w, x from -half_size to +half_size)
	# UV.y: 0.0 at -w, 0.5 at center, 1.0 at +w
	var base := r_verts.size()
	r_verts.append(Vector3(-half_size, 0.002, -ribbon_half_w))
	r_uvs.append(Vector2(0.0, 0.0))
	r_verts.append(Vector3(half_size, 0.002, -ribbon_half_w))
	r_uvs.append(Vector2(1.0, 0.0))
	r_verts.append(Vector3(half_size, 0.002, ribbon_half_w))
	r_uvs.append(Vector2(1.0, 1.0))
	r_verts.append(Vector3(-half_size, 0.002, ribbon_half_w))
	r_uvs.append(Vector2(0.0, 1.0))
	r_indices.append_array([base, base + 1, base + 2, base, base + 2, base + 3])

	# Ribbon along Z axis (x from -w to +w, z from -half_size to +half_size)
	# UV.y: 0.0 at -w, 0.5 at center, 1.0 at +w (transversal to line direction)
	base = r_verts.size()
	r_verts.append(Vector3(-ribbon_half_w, 0.002, -half_size))
	r_uvs.append(Vector2(0.0, 0.0))
	r_verts.append(Vector3(ribbon_half_w, 0.002, -half_size))
	r_uvs.append(Vector2(0.0, 1.0))
	r_verts.append(Vector3(ribbon_half_w, 0.002, half_size))
	r_uvs.append(Vector2(1.0, 1.0))
	r_verts.append(Vector3(-ribbon_half_w, 0.002, half_size))
	r_uvs.append(Vector2(1.0, 0.0))
	r_indices.append_array([base, base + 1, base + 2, base, base + 2, base + 3])

	var ribbon_mesh := ArrayMesh.new()
	var r_arrays := []
	r_arrays.resize(Mesh.ARRAY_MAX)
	r_arrays[Mesh.ARRAY_VERTEX] = r_verts
	r_arrays[Mesh.ARRAY_TEX_UV] = r_uvs
	r_arrays[Mesh.ARRAY_INDEX] = r_indices
	ribbon_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, r_arrays)
	_gold_ribbon_instance.mesh = ribbon_mesh

	var r_sh := Shader.new()
	r_sh.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;

uniform vec4 gold_color : source_color = vec4(0.7608, 0.6157, 0.3255, 0.95);

varying vec2 v_uv;

void vertex() {
	v_uv = UV;
}

void fragment() {
	// UV.y is transversal across the ribbon: 0.0 at edge, 0.5 at center, 1.0 at opposite edge
	float dist_from_center = abs(v_uv.y - 0.5) * 2.0; // 0.0 at center, 1.0 at edge
	float aa = 1.0 - smoothstep(0.35, 1.0, dist_from_center);
	ALBEDO = gold_color.rgb;
	ALPHA = gold_color.a * aa;
}
"""
	var r_mat := ShaderMaterial.new()
	r_mat.shader = r_sh
	r_mat.render_priority = 1
	r_mat.set_shader_parameter("gold_color", color_center)
	_gold_ribbon_instance.material_override = r_mat

	position = Vector3(0.0, 0.01, 0.0)
