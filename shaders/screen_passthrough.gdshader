shader_type canvas_item;
render_mode unshaded;

// Diagnostic only. Preserves the same screen texture dependency and
// fullscreen composite as the production FXAA material, but does a
// single central texture read and deliberately performs no edge filtering.
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

void fragment() {
	COLOR = vec4(texture(screen_texture, SCREEN_UV).rgb, 1.0);
}
