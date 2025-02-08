shader_type spatial;
render_mode blend_mix, depth_draw_opaque,
cull_back, diffuse_toon, specular_disabled,
shadows_disabled, unshaded,
depth_test_disabled;

uniform sampler2D bar_texture_base : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D bar_texture_alpha : source_color, filter_linear_mipmap, repeat_disable;
uniform vec3 bar_color : source_color;
uniform vec3 bar_empty_color : source_color;

uniform float maxProg = 50.0;  // Define the maximum progress
uniform float progress : hint_range(0.0, 100.0, 1.0);  // Set the range hint for the inspector

void vertex() {
    // Billboard Effect
    MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
        INV_VIEW_MATRIX[0],
        INV_VIEW_MATRIX[1],
        INV_VIEW_MATRIX[2],
        MODEL_MATRIX[3]);
}

void fragment() {
    // Normalize progress to 0 - 1 range based on maxProg
    float normalized_progress = progress / maxProg;

    // Calculate the progress texture effect
    float progress_texture = smoothstep(-normalized_progress, -normalized_progress + 0.001, -UV.x);

    // Calculate the color of the bar based on progress
    vec3 bar_final_color = texture(bar_texture_base, UV).rgb
                           * mix(bar_color, bar_empty_color, clamp(1.5 + -normalized_progress * 2.5, 0, 1))
                           * progress_texture;

    // Set final color and alpha
    ALBEDO = bar_final_color;
    ALPHA = texture(bar_texture_alpha, UV).a;
}
