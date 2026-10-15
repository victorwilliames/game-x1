shader_type spatial;
render_mode cull_back;

uniform vec4 bg_color : source_color = vec4(0.09, 0.12, 0.16, 1.0);
uniform vec4 grid_color : source_color = vec4(0.18, 0.24, 0.32, 1.0);
uniform vec4 team_allied_tint : source_color = vec4(0.06, 0.14, 0.20, 1.0);
uniform vec4 team_enemy_tint : source_color = vec4(0.16, 0.09, 0.11, 1.0);

uniform float grid_size = 2.0;
uniform float line_thickness = 0.025;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// 1. Base team gradient along lane Z axis
	float z_norm = clamp(world_pos.z / 25.0, -1.0, 1.0);
	vec3 base_tint;
	if (z_norm > 0.0) {
		base_tint = mix(bg_color.rgb, team_allied_tint.rgb, z_norm * 0.45);
	} else {
		base_tint = mix(bg_color.rgb, team_enemy_tint.rgb, -z_norm * 0.45);
	}

	// 2. Subtle, flat grid
	vec2 coord = world_pos.xz / grid_size;
	vec2 f_coord = abs(fract(coord - 0.5) - 0.5);
	vec2 fw = max(fwidth(coord), vec2(0.001));
	vec2 line_factor = clamp((f_coord / fw) * (line_thickness * 15.0), 0.0, 1.0);
	float grid_mask = 1.0 - min(line_factor.x, line_factor.y);

	vec3 col = mix(base_tint, grid_color.rgb, grid_mask * 0.45);

	// 3. Grid intersection crosses (+)
	vec2 dist_from_int = abs(fract(coord + 0.5) - 0.5) * grid_size;
	bool in_cross_x = dist_from_int.x < 0.15 && dist_from_int.y < 0.025;
	bool in_cross_y = dist_from_int.y < 0.15 && dist_from_int.x < 0.025;
	if (in_cross_x || in_cross_y) {
		col = mix(col, vec3(0.35, 0.45, 0.58), 0.6);
	}

	// 4. Dashed centerline along lane (X = 0)
	if (abs(world_pos.x) < 0.035 && abs(world_pos.z) < 22.0) {
		float dash = fract(world_pos.z * 0.6);
		if (dash > 0.4) {
			col = mix(col, vec3(0.45, 0.55, 0.65), 0.7);
		}
	}

	// 5. Subtle side lane boundary lines (at X = -4.5 and X = 4.5)
	if (abs(abs(world_pos.x) - 4.5) < 0.025 && abs(world_pos.z) < 22.0) {
		col = mix(col, grid_color.rgb, 0.4);
	}

	ALBEDO = col;
	ROUGHNESS = 0.85;
	SPECULAR = 0.12;
}
