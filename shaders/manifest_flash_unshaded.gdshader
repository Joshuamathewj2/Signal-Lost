shader_type canvas_item;
render_mode unshaded;

// Self-lit twin of manifest_flash.gdshader: used while a sprite telegraphs danger
// (warning tint) so wind-ups stay readable in the sonar-dark world.
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	c.rgb = mix(c.rgb, flash_color.rgb, flash_amount);
	COLOR = c;
}
