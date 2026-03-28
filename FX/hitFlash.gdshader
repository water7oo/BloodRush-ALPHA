shader_type spatial;

render_mode unshaded;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 flash_color : source_color = vec3(1.0, 1.0, 1.0);

void fragment() {
	vec3 base = ALBEDO;

	// Blend original color with flash color
	ALBEDO = mix(base, flash_color, flash_amount);
}