shader_type spatial;
render_mode blend_mix, unshaded, depth_draw_never;

uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec3 custom_color : source_color = vec3(1.0, 1.0, 1.0);
uniform sampler2D custom_texture;

void fragment() {
    vec3 tex_color = texture(custom_texture, UV).rgb; // sample texture
    vec3 final_color = mix(vec3(0.0), custom_color * tex_color, flash);
    ALBEDO = final_color;
    ALPHA = flash;
}
