class_name RingMeshBuilder
extends RefCounted

## Utility to generate flat 2D ring meshes matching THREE.RingGeometry on XZ plane.

static func create_ring_mesh(inner_radius: float, outer_radius: float, segments: int = 64) -> ArrayMesh:
	var arr_mesh := ArrayMesh.new()
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()

	for i in range(segments):
		var a1: float = float(i) * TAU / float(segments)
		var a2: float = float(i + 1) * TAU / float(segments)

		var v0 := Vector3(cos(a1) * inner_radius, 0.0, sin(a1) * inner_radius)
		var v1 := Vector3(cos(a1) * outer_radius, 0.0, sin(a1) * outer_radius)
		var v2 := Vector3(cos(a2) * inner_radius, 0.0, sin(a2) * inner_radius)
		var v3 := Vector3(cos(a2) * outer_radius, 0.0, sin(a2) * outer_radius)

		var base := vertices.size()
		vertices.append_array([v0, v1, v2, v3])

		# Two triangles forming the quad between inner and outer radii
		indices.append_array([base, base + 2, base + 1])
		indices.append_array([base + 1, base + 2, base + 3])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices

	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return arr_mesh

static func create_smooth_ring_material(inner_r: float, outer_r: float, col: Color) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;
uniform vec4 ring_color : source_color = vec4(0.0, 1.0, 0.533, 0.12);
uniform float inner_radius = 17.92;
uniform float outer_radius = 18.08;
varying vec2 v_xz;
void vertex() {
    v_xz = VERTEX.xz;
}
void fragment() {
    float r = length(v_xz);
    float aa = max(fwidth(r), 0.018);
    float mask = smoothstep(inner_radius - aa, inner_radius + aa, r) * (1.0 - smoothstep(outer_radius - aa, outer_radius + aa, r));
    ALBEDO = ring_color.rgb;
    ALPHA = ring_color.a * mask;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("ring_color", col)
	mat.set_shader_parameter("inner_radius", inner_r)
	mat.set_shader_parameter("outer_radius", outer_r)
	return mat

