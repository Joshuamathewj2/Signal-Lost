shader_type canvas_item;

uniform float reveal : hint_range(0.0, 1.0) = 0.0;
uniform vec2 wipe_center = vec2(0.5, 0.5);
uniform float glitch : hint_range(0.0, 1.0) = 0.0;

float hash(float n) {
	return fract(sin(n) * 43758.5453123);
}

void fragment() {
	vec2 uv = UV;
	if (glitch > 0.01) {
		float slice = floor(uv.y * 24.0) + floor(TIME * 20.0);
		float h = hash(slice);
		if (h > 0.85) {
			uv.x += glitch * 0.02 * (hash(slice + 1.0) - 0.5) * 2.0;
		}
	}

	vec4 col = texture(TEXTURE, uv);
	float d = distance(uv, wipe_center);
	float front = reveal * 1.2;
	float vis = 1.0 - smoothstep(front - 0.02, front, d);
	float ring = (abs(d - front) < 0.015 && front > 0.02 && front < 1.1) ? 1.0 : 0.0;

	col.a *= vis;
	col.rgb = mix(col.rgb, vec3(1.0), ring);
	COLOR = col;
}
