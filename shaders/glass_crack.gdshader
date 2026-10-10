shader_type canvas_item;

uniform float crack : hint_range(0.0, 1.0) = 0.0;
uniform float seed_val = 0.0;
uniform vec4 tint : source_color = vec4(0.24, 0.24, 0.24, 1.0);

vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453123);
}

float cellular_edge(vec2 p) {
	vec2 n = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 o = hash2(n + g);
			vec2 r = g + o - f;
			float d = dot(r, r);
			if (d < d1) {
				d2 = d1;
				d1 = d;
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	return sqrt(d2) - sqrt(d1);
}

void fragment() {
	vec2 g = UV * 4.0 + vec2(seed_val, seed_val * 1.618);
	float e = cellular_edge(g);
	float line = (1.0 - smoothstep(0.0, 0.04 + 0.06 * crack, e)) * step(0.01, crack);
	vec3 col = mix(tint.rgb, vec3(1.0), line);
	float alpha = max(tint.a * 0.6, line);
	COLOR = vec4(col, alpha);
}

void light() {
	LIGHT = vec4(LIGHT_COLOR.rgb * COLOR.rgb * LIGHT_ENERGY, COLOR.a);
}
