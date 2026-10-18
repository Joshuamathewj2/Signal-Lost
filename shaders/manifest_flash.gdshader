shader_type canvas_item;

// Hit / parry flash for ManifestSprite: lerps the sprite toward flash_color while
// keeping its alpha, so a crimson silhouette can go fully white for a few frames.
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	c.rgb = mix(c.rgb, flash_color.rgb, flash_amount);
	COLOR = c;
}
