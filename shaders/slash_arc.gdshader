shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 arc_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	float alpha = clamp((1.0 - progress) * (1.0 - abs(UV.y - 0.5) * 2.0), 0.0, 1.0);
	COLOR = vec4(arc_color.rgb, arc_color.a * alpha);
}
