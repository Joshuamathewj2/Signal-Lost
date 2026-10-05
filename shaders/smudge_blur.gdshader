shader_type canvas_item;

uniform vec4 smudge_color : source_color = vec4(0.353, 0.0, 0.0, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 0.5;
uniform float wobble = 0.06;

void fragment() {
	vec2 uv = UV + wobble * vec2(sin(TIME * 3.0 + UV.y * 9.0), cos(TIME * 2.3 + UV.x * 7.0));
	float d = length(uv - vec2(0.5)) * 2.0;
	float a = 1.0 - smoothstep(0.35, 1.0, d);
	COLOR = vec4(smudge_color.rgb, a * opacity * COLOR.a);
}
