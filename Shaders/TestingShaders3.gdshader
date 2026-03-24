shader_type spatial;
render_mode unshaded, depth_draw_opaque, depth_prepass_alpha;

// Uniforms for controlling outline appearance
uniform vec3 shadow_color : source_color = vec3(0.0);
uniform float shadow_thickness = 2.0;

// New uniforms for tweaking sensitivity in the editor
uniform float normal_threshold = 0.05; // Lower values detect more edges
uniform float depth_sensitivity = 2.0; // Controls how strongly depth differences affect edges
uniform float outline_start = 0.1; // Adjusts when outlines begin to appear
uniform float outline_end = 0.2; // Adjusts the softness of the outline

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D NORMAL_TEXTURE : hint_normal_roughness_texture, filter_nearest;

vec2 getDepth(vec2 screen_uv, sampler2D depth_texture, mat4 inv_projection_matrix){
    float raw_depth = texture(depth_texture, screen_uv).r;
    vec3 normalized_device_coordinates = vec3(screen_uv * 2.0 - 1.0, raw_depth);
    vec4 view_space = inv_projection_matrix * vec4(normalized_device_coordinates, 1.0);
    view_space.xyz /= view_space.w;
    return vec2(-view_space.z, raw_depth);
}

void fragment() {
    vec2 e = vec2(1.0 / VIEWPORT_SIZE.x, 1.0 / VIEWPORT_SIZE.y);
    float depth_diff = 0.0;

    vec2 depth_data = getDepth(SCREEN_UV, DEPTH_TEXTURE, INV_PROJECTION_MATRIX);
    float depth = depth_data.x;
    vec3 color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
    vec3 c = vec3(0.0);

    vec3 normal = texture(NORMAL_TEXTURE, SCREEN_UV).rgb * 2.0 - 1.0;

    for (float x = -shadow_thickness; x <= shadow_thickness; x += 1.0){
        for (float y = -shadow_thickness; y <= shadow_thickness; y += 1.0){
            if ((x == 0.0 && y == 0.0) || (shadow_thickness * shadow_thickness < (x * x + y * y))) {
                continue;
            }

            vec2 du_data = getDepth(SCREEN_UV + vec2(x, y) * e, DEPTH_TEXTURE, INV_PROJECTION_MATRIX);
            float du = du_data.x;

            // Calculate the normal difference
            vec3 nu = texture(NORMAL_TEXTURE, SCREEN_UV + vec2(x, y) * e).rgb * 2.0 - 1.0;
            float normal_diff = 1.0 - abs(dot(nu, normal));

            // Use the exposed normal_threshold
            if (normal_diff > normal_threshold) {
                float val = clamp(abs(depth - du) / (x * x + y * y) * depth_sensitivity, 0.0, 1.0);
                val *= normal_diff;
                depth_diff += val;
            }
        }
    }

    // Use the exposed outline_start and outline_end
    depth_diff = smoothstep(outline_start, outline_end, depth_diff);

    // Set the final color based on the calculated outline
    vec3 final = mix(color, shadow_color, depth_diff);
    ALBEDO = final;
    ALPHA = depth_diff;
}
