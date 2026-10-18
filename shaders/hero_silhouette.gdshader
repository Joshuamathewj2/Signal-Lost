shader_type canvas_item;

uniform vec4 rim_color : source_color = vec4(0.15, 0.20, 0.30, 0.85);
uniform float rim_thickness : hint_range(0.0, 4.0) = 1.2;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	
	if (base.a > 0.05) {
		// Main sprite body
		vec3 c = mix(base.rgb, flash_color.rgb, flash);
		COLOR = vec4(c, base.a * COLOR.a);
	} else {
		// Check neighbors for 1px subtle rim outline for noir level contrast
		vec2 ps = TEXTURE_PIXEL_SIZE * rim_thickness;
		float a_up = texture(TEXTURE, UV + vec2(0.0, -ps.y)).a;
		float a_dn = texture(TEXTURE, UV + vec2(0.0, ps.y)).a;
		float a_lf = texture(TEXTURE, UV + vec2(-ps.x, 0.0)).a;
		float a_rt = texture(TEXTURE, UV + vec2(ps.x, 0.0)).a;
		
		float outline = max(max(a_up, a_dn), max(a_lf, a_rt));
		if (outline > 0.1) {
			COLOR = vec4(rim_color.rgb, rim_color.a * outline * COLOR.a);
		} else {
			COLOR = vec4(0.0);
		}
	}
}
