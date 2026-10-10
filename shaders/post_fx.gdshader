shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

uniform float vignette_strength : hint_range(0.0, 1.0) = 0.45;
uniform float vignette_radius : hint_range(0.0, 2.0) = 0.75;
uniform float grain_amount : hint_range(0.0, 0.5) = 0.06;
uniform float ca_amount : hint_range(0.0, 0.1) = 0.0;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform float bloom_amount : hint_range(0.0, 1.0) = 0.25;
uniform bool ca_mono = true;

float luminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 dir = uv - 0.5;
	vec3 c = texture(screen_tex, uv).rgb;

	if (ca_amount > 0.0) {
		float l1 = luminance(texture(screen_tex, uv + dir * ca_amount).rgb);
		float l2 = luminance(texture(screen_tex, uv - dir * ca_amount).rgb);
		c = max(c, vec3((l1 + l2) * 0.25));
	}

	// 5-tap cross blur bright-pass
	vec2 px = vec2(2.0) * SCREEN_PIXEL_SIZE;
	vec3 b = max(texture(screen_tex, uv + vec2(px.x, 0.0)).rgb - 0.6, vec3(0.0)) +
			 max(texture(screen_tex, uv - vec2(px.x, 0.0)).rgb - 0.6, vec3(0.0)) +
			 max(texture(screen_tex, uv + vec2(0.0, px.y)).rgb - 0.6, vec3(0.0)) +
			 max(texture(screen_tex, uv - vec2(0.0, px.y)).rgb - 0.6, vec3(0.0)) +
			 max(c - 0.6, vec3(0.0));
	b *= 0.2;
	c += b * bloom_amount;

	// Vignette
	float v = smoothstep(vignette_radius, vignette_radius - 0.45, length(dir) * 1.2);
	c *= mix(1.0 - vignette_strength, 1.0, v);

	// Grain
	float n = hash(uv * vec2(1280.0, 720.0) + fract(TIME) * 91.0) - 0.5;
	c += n * grain_amount;

	// Flash
	c = mix(c, vec3(1.0), flash);

	COLOR = vec4(c, 1.0);
}
