@tool
extends MeshInstance3D
class_name MobaGridHelper

## 1:1 Port of THREE.GridHelper(80, 40, '#c29d53', '#162838')
## Uses analytical anti-aliased shader with fwidth() so lines are smooth at any angle/resolution.

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

func _ready() -> void:
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rebuild_grid()

func _rebuild_grid() -> void:
	if divisions <= 0 or size <= 0:
		return

	var p_mesh := PlaneMesh.new()
	p_mesh.size = Vector2(size, size)
	mesh = p_mesh

	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;

uniform vec4 color_center : source_color = vec4(0.7608, 0.6157, 0.3255, 0.95);
uniform vec4 color_grid : source_color = vec4(0.0863, 0.1569, 0.2196, 0.70);
uniform float grid_size = 80.0;
uniform float grid_divisions = 40.0;

varying vec2 v_xz;

void vertex() {
	v_xz = VERTEX.xz;
}

void fragment() {
	float step_size = grid_size / grid_divisions;
	vec2 coord = v_xz;

	// Anti-aliasing derivative
	vec2 fw = max(fwidth(coord), vec2(0.008));

	// Distance to nearest grid line
	vec2 grid_dist = abs(fract(coord / step_size + 0.5) - 0.5) * step_size;
	vec2 line_aa = smoothstep(fw * 1.25, vec2(0.0), grid_dist);
	float grid_line = max(line_aa.x, line_aa.y);

	// Distance to center lines (X=0 and Z=0)
	vec2 center_dist = abs(coord);
	vec2 center_aa = smoothstep(fw * 1.5, vec2(0.0), center_dist);
	float center_line = max(center_aa.x, center_aa.y);

	// Blend colors
	vec3 col = mix(color_grid.rgb, color_center.rgb, center_line);
	float a = max(grid_line * color_grid.a, center_line * color_center.a);

	if (a < 0.005) {
		discard;
	}

	ALBEDO = col;
	ALPHA = a;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("color_center", color_center)
	mat.set_shader_parameter("color_grid", color_grid)
	mat.set_shader_parameter("grid_size", size)
	mat.set_shader_parameter("grid_divisions", float(divisions))
	material_override = mat

	position = Vector3(0.0, 0.012, 0.0)
