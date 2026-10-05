shader_type canvas_item;

uniform vec4 danger_color : source_color = vec4(0.878, 0.0, 0.0, 1.0);
uniform float alert : hint_range(0.0, 1.0) = 0.0;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform bool hatch = false;
uniform float rim_softness : hint_range(0.01, 1.0) = 0.25;

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	float flick = alert * (0.85 + 0.15 * step(0.5, fract(TIME * 12.0)));
	vec3 c = mix(danger_color.rgb, vec3(1.0, 0.35, 0.35), max(flick * 0.35, flash));
	if (hatch) {
		float h = step(0.5, fract((FRAGCOORD.x + FRAGCOORD.y) / 6.0));
		c = mix(vec3(0.0), vec3(1.0), h);
	}
	COLOR = vec4(c, base.a);
}

void light() {
	float l = clamp(LIGHT_ENERGY * max(LIGHT_COLOR.r, max(LIGHT_COLOR.g, LIGHT_COLOR.b)), 0.0, 1.0);
	float l_cap = clamp(LIGHT_ENERGY, 0.0, 1.0);
	float k = smoothstep(0.0, rim_softness, l) * l_cap;
	LIGHT = vec4(COLOR.rgb * k, COLOR.a * k);
}
