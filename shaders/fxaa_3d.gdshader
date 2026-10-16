shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

// FXAA 3.11 Quality Presets
const float FXAA_SPAN_MAX = 8.0;
const float FXAA_REDUCE_MUL = 0.125;
const float FXAA_REDUCE_MIN = 0.0078125;

void fragment() {
	vec2 texCoord = SCREEN_UV;
	vec2 inverseVP = SCREEN_PIXEL_SIZE;

	vec3 rgbM = texture(screen_texture, texCoord).rgb;
	vec3 dCol = abs(dFdx(rgbM)) + abs(dFdy(rgbM));

	// Instant GPU hardware derivative early exit on flat areas (saves 3.4M texture taps/frame)
	if (max(max(dCol.r, dCol.g), dCol.b) < 0.035) {
		COLOR = vec4(rgbM, 1.0);
	} else {
		vec3 rgbNW = texture(screen_texture, texCoord + vec2(-1.0, -1.0) * inverseVP).rgb;
		vec3 rgbNE = texture(screen_texture, texCoord + vec2(1.0, -1.0) * inverseVP).rgb;
		vec3 rgbSW = texture(screen_texture, texCoord + vec2(-1.0, 1.0) * inverseVP).rgb;
		vec3 rgbSE = texture(screen_texture, texCoord + vec2(1.0, 1.0) * inverseVP).rgb;

		vec3 luma = vec3(0.299, 0.587, 0.114);
		float lumaNW = dot(rgbNW, luma);
		float lumaNE = dot(rgbNE, luma);
		float lumaSW = dot(rgbSW, luma);
		float lumaSE = dot(rgbSE, luma);
		float lumaM  = dot(rgbM,  luma);

		float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
		float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));
		vec2 dir;
		dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
		dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));

		float dirReduce = max((lumaNW + lumaNE + lumaSW + lumaSE) * (0.25 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN);
		float rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);
		dir = min(vec2(FXAA_SPAN_MAX), max(vec2(-FXAA_SPAN_MAX), dir * rcpDirMin)) * inverseVP;

		vec3 rgbA = 0.5 * (
			texture(screen_texture, texCoord + dir * (1.0 / 3.0 - 0.5)).rgb +
			texture(screen_texture, texCoord + dir * (2.0 / 3.0 - 0.5)).rgb);
		vec3 rgbB = rgbA * 0.5 + 0.25 * (
			texture(screen_texture, texCoord + dir * (0.0 / 3.0 - 0.5)).rgb +
			texture(screen_texture, texCoord + dir * (3.0 / 3.0 - 0.5)).rgb);

		float lumaB = dot(rgbB, luma);
		if ((lumaB < lumaMin) || (lumaB > lumaMax)) {
			COLOR = vec4(rgbA, 1.0);
		} else {
			COLOR = vec4(rgbB, 1.0);
		}
	}
}
