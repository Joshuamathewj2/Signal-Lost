shader_type canvas_item;

uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 0.25);
uniform float glow_falloff : hint_range(0.5, 5.0) = 2.2;
uniform float rim_softness : hint_range(0.01, 1.0) = 0.25;

void fragment() {
	float x = abs(UV.y - 0.5) * 2.0;
	COLOR = vec4(tint.rgb, tint.a * pow(1.0 - x, glow_falloff));
}

void light() {
	float l = clamp(LIGHT_ENERGY * max(LIGHT_COLOR.r, max(LIGHT_COLOR.g, LIGHT_COLOR.b)), 0.0, 1.0);
	float l_cap = clamp(LIGHT_ENERGY, 0.0, 1.0);
	float k = smoothstep(0.0, rim_softness, l) * l_cap;
	LIGHT = vec4(COLOR.rgb * k, COLOR.a * k);
}
