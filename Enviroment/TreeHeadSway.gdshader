shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D leaf_texture;
uniform sampler2D wind_noise; // grayscale noise texture
uniform float sway_amplitude : hint_range(0.0, 0.05) = 0.02;
uniform float sway_speed : hint_range(0.0, 10.0) = 2.0;
uniform float sway_frequency : hint_range(0.0, 10.0) = 5.0;
uniform float alpha_scissor : hint_range(0.0, 1.0) = 0.05;
uniform float leaf_height : hint_range(0.0, 5.0) = 1.0;

void vertex() {
    vec3 pos = VERTEX;

    float height_factor = clamp(pos.y / leaf_height, 0.0, 1.0);

    // Sample noise texture using vertex position and time
    vec2 noise_uv = vec2(pos.x, pos.y) * 0.5 + vec2(TIME * 0.1, TIME * 0.1);
    float noise_val = texture(wind_noise, noise_uv).r;

    // Base sway using sine + noise turbulence
    float sway = (sin(TIME * sway_speed + pos.x * sway_frequency) * 0.5 + (noise_val - 0.5)) * sway_amplitude * height_factor;

    pos.x += sway;
    pos.y += sway * 0.2 * height_factor;

    VERTEX = pos;
}

void fragment() {
    vec4 tex = texture(leaf_texture, UV);

    if (tex.a < alpha_scissor) discard;

    ALBEDO = pow(tex.rgb, vec3(2.2));
    ALPHA = tex.a;
}