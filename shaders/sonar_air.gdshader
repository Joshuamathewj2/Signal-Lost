shader_type canvas_item;

uniform int pulse_count = 0;
uniform vec4 pulse_data[6];
uniform vec4 pulse_style[6];
uniform vec4 arc_color : source_color = vec4(1.0, 1.0, 1.0, 0.85);
uniform vec2 rect_origin = vec2(0.0, 0.0);

varying vec2 world_pos;

float band(float d, float r, float w) {
	if (d > r) {
		return 1.0 - smoothstep(0.0, max(w * 0.4, 0.4), d - r);
	} else {
		return 1.0 - smoothstep(0.0, max(w * 1.6, 1.2), r - d);
	}
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float a = 0.0;
	for (int i = 0; i < 6; i++) {
		if (i >= pulse_count) {
			break;
		}
		vec4 p = pulse_data[i];
		vec4 s = pulse_style[i];
		float d = distance(world_pos, p.xy);
		// Main wavefront arc
		a = max(a, band(d, p.z, s.x) * p.w);
		// Trailing ripple rings
		int max_trails = int(min(s.z, 3.0));
		for (int k = 1; k <= 3; k++) {
			if (k > max_trails) {
				break;
			}
			float ring_r = p.z - s.y * float(k);
			float ring_w = s.x * 0.6;
			float ring_falloff = pow(0.45, float(k));
			a = max(a, band(d, ring_r, ring_w) * p.w * ring_falloff);
		}
	}
	COLOR = vec4(arc_color.rgb, arc_color.a * clamp(a, 0.0, 1.0));
}

void light() {
	float gate = step(0.02, LIGHT_ENERGY * max(LIGHT_COLOR.r, max(LIGHT_COLOR.g, LIGHT_COLOR.b)));
	LIGHT = vec4(COLOR.rgb, COLOR.a) * gate;
}
