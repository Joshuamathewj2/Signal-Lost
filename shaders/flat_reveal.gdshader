shader_type canvas_item;

uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float rim_softness : hint_range(0.01, 1.0) = 0.25;
uniform float max_brightness : hint_range(0.0, 2.0) = 1.0;
uniform bool hatch = false;

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR * tint;
	if (hatch) {
		float h = step(0.5, fract((FRAGCOORD.x + FRAGCOORD.y) / 6.0));
		base.rgb = mix(base.rgb * 0.4, base.rgb, h);
	}
	COLOR = base;
}

void light() {
	float l = clamp(LIGHT_ENERGY * max(LIGHT_COLOR.r, max(LIGHT_COLOR.g, LIGHT_COLOR.b)), 0.0, 1.0);
	float l_cap = clamp(LIGHT_ENERGY, 0.0, 1.0);
	float k = smoothstep(0.0, rim_softness, l) * l_cap;
	LIGHT = vec4(COLOR.rgb * k * max_brightness, COLOR.a * k);
}
