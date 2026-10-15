shader_type spatial;
render_mode cull_back;

uniform vec4 bg_color : source_color = vec4(0.13, 0.16, 0.20, 1.0);
uniform vec4 grid_color : source_color = vec4(0.24, 0.32, 0.42, 1.0);
uniform float grid_size = 2.0;
uniform float line_thickness = 0.04;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 coord = world_pos.xz / grid_size;
	vec2 grid = abs(fract(coord - 0.5) - 0.5) / max(fwidth(coord), vec2(0.001));
	float line = min(grid.x, grid.y);
	float c = clamp(1.0 - line * line_thickness, 0.0, 1.0);
	ALBEDO = mix(bg_color.rgb, grid_color.rgb, c);
	ROUGHNESS = 0.85;
}
