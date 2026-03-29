shader_type spatial;
render_mode unshaded, depth_draw_opaque, cull_back;

uniform sampler2D noise_tex_1;
uniform sampler2D noise_tex_2;
uniform sampler2D screen_tex : hint_screen_texture;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest_mipmap;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

uniform vec2 noise_scale = vec2(2.0, 2.0);
uniform float refraction_strength = 0.03;
uniform float speed_1 = 0.05;
uniform float speed_2 = 0.07;

uniform vec3 water_color : source_color = vec3(0.2, 0.5, 0.8);

uniform vec2 foam_dir_1 = vec2(1.0, 0.0);
uniform vec2 foam_dir_2 = vec2(0.0, 1.0);

uniform float foam_intensity = 1.5;
uniform float depth_falloff = 2.0;

void fragment() {
    vec2 uv = UV * noise_scale;

    // Scroll noise
    vec2 uv1 = uv + TIME * speed_1 * foam_dir_1;
    vec2 uv2 = uv + TIME * speed_2 * foam_dir_2;

	float noise1 = texture(noise_tex_1, uv1).r;
	float noise2 = texture(noise_tex_2, uv2).r;

	vec2 distortion = vec2(noise1 - 0.5, noise2 - 0.5) * refraction_strength;

	vec2 screen_uv = SCREEN_UV + distortion;
	vec3 refracted = texture(SCREEN_TEXTURE, screen_uv).rgb;

    // Foam via subtracting noises
    float foam = noise1 - noise2;
    foam = clamp(foam * foam_intensity, 0.0, 1.0);

    // Depth-based edge highlight
    float depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
    float linear_depth = 1.0 / (depth * depth_falloff + 0.001);

    foam *= linear_depth;

    // Gradient-style highlight (2-tone)
    vec3 foam_color = mix(vec3(0.7, 0.9, 1.0), vec3(1.0), foam);

    // Final color
    vec3 col = refracted * water_color;
    col += foam_color * foam;

    ALBEDO = col;
    ALPHA = 0.9;
}