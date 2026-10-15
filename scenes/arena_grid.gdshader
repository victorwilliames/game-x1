shader_type spatial;
render_mode cull_back;

// game-x0-moba 1:1 floor & grid shader
// Floor: #0a1016
// Grid primary (axes): #c29d53 (Gold)
// Grid secondary (cells): #162838 (Slate Navy)
// Grid size: 80x80, 40 divisions (2.0m per cell)

uniform vec4 bg_color : source_color = vec4(0.0392, 0.0627, 0.0863, 1.0); // #0a1016
uniform vec4 grid_secondary : source_color = vec4(0.0863, 0.1569, 0.2196, 1.0); // #162838
uniform vec4 grid_primary : source_color = vec4(0.7608, 0.6157, 0.3255, 1.0); // #c29d53

uniform float grid_size = 2.0;
uniform float line_thickness = 0.03;
uniform float axis_thickness = 0.045;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// 1. Base floor color
	vec3 col = bg_color.rgb;

	// 2. Cell coordinates (grid step 2.0m)
	vec2 coord = world_pos.xz / grid_size;
	vec2 f_coord = abs(fract(coord - 0.5) - 0.5);
	vec2 fw = max(fwidth(coord), vec2(0.0005));
	vec2 line_factor = clamp((f_coord / fw) * (line_thickness * 10.0), 0.0, 1.0);
	float grid_mask = 1.0 - min(line_factor.x, line_factor.y);

	// Blend secondary grid lines (#162838)
	col = mix(col, grid_secondary.rgb, grid_mask);

	// 3. Central primary axes (X = 0 and Z = 0 in #c29d53 Gold)
	float axis_x = 1.0 - clamp(abs(world_pos.x) / axis_thickness, 0.0, 1.0);
	float axis_z = 1.0 - clamp(abs(world_pos.z) / axis_thickness, 0.0, 1.0);
	float axis_mask = max(axis_x, axis_z);

	col = mix(col, grid_primary.rgb, axis_mask);

	ALBEDO = col;
	ROUGHNESS = 0.8;
	SPECULAR = 0.1;
}
