shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform bool quantize_enabled = true;
uniform bool vignette_enabled = true;
uniform float color_steps : hint_range(8.0, 64.0) = 28.0;
uniform float dither_strength : hint_range(0.0, 0.05) = 0.012;
uniform float vignette_strength : hint_range(0.0, 0.5) = 0.13;
uniform int colorblind_mode = 0;

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int index = x + y * 4;
	float values[16] = float[16](
		0.0, 8.0, 2.0, 10.0,
		12.0, 4.0, 14.0, 6.0,
		3.0, 11.0, 1.0, 9.0,
		15.0, 7.0, 13.0, 5.0
	);
	return values[index] / 16.0 - 0.5;
}

vec3 apply_colorblind(vec3 c, int mode) {
	if (mode == 1) {
		return vec3(
			0.625 * c.r + 0.375 * c.g,
			0.700 * c.r + 0.300 * c.g,
			0.300 * c.g + 0.700 * c.b
		);
	}
	if (mode == 2) {
		return vec3(
			0.567 * c.r + 0.433 * c.g,
			0.558 * c.r + 0.442 * c.g,
			0.242 * c.g + 0.758 * c.b
		);
	}
	if (mode == 3) {
		return vec3(
			0.950 * c.r + 0.050 * c.g,
			0.433 * c.g + 0.567 * c.b,
			0.475 * c.g + 0.525 * c.b
		);
	}
	return c;
}

void fragment() {
	vec4 source = texture(screen_texture, SCREEN_UV);
	vec3 color = source.rgb;
	if (quantize_enabled) {
		float noise = bayer4(FRAGCOORD.xy) * dither_strength;
		color = floor(clamp(color + vec3(noise), 0.0, 1.0) * color_steps) / color_steps;
	}
	color = apply_colorblind(color, colorblind_mode);
	if (vignette_enabled) {
		vec2 centered = SCREEN_UV - vec2(0.5);
		float edge = smoothstep(0.16, 0.52, dot(centered, centered));
		color *= 1.0 - edge * vignette_strength;
	}
	COLOR = vec4(color, source.a);
}
