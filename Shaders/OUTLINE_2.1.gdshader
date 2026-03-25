shader_type spatial;
render_mode unshaded, depth_draw_opaque, depth_prepass_alpha;

// Outline appearance
uniform vec3 shadow_color : source_color = vec3(0.0);
uniform float shadow_thickness = 2.0;

// Tuned for foliage
uniform float depth_sensitivity = 0.5;   // LOWER = less internal noise
uniform float outline_start = 0.2;       // raise to ignore small differences
uniform float outline_end = 0.4;

// Screen textures
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Depth helper
vec2 getDepth(vec2 screen_uv, sampler2D depth_texture, mat4 inv_projection_matrix){
    float raw_depth = texture(depth_texture, screen_uv).r;
    vec3 ndc = vec3(screen_uv * 2.0 - 1.0, raw_depth);
    vec4 view_space = inv_projection_matrix * vec4(ndc, 1.0);
    view_space.xyz /= view_space.w;
    return vec2(-view_space.z, raw_depth);
}

void fragment() {
    vec2 e = vec2(1.0 / VIEWPORT_SIZE.x, 1.0 / VIEWPORT_SIZE.y);

    vec2 depth_data = getDepth(SCREEN_UV, DEPTH_TEXTURE, INV_PROJECTION_MATRIX);
    float depth = depth_data.x;

    vec3 color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;

    float depth_diff = 0.0;

    // Sample surrounding pixels
    for (float x = -shadow_thickness; x <= shadow_thickness; x += 1.0){
        for (float y = -shadow_thickness; y <= shadow_thickness; y += 1.0){

            if ((x == 0.0 && y == 0.0) || (shadow_thickness * shadow_thickness < (x * x + y * y))) {
                continue;
            }

            vec2 du_data = getDepth(SCREEN_UV + vec2(x, y) * e, DEPTH_TEXTURE, INV_PROJECTION_MATRIX);
            float du = du_data.x;

            float diff = abs(depth - du);

            float val = clamp(diff / (x * x + y * y) * depth_sensitivity, 0.0, 1.0);
            depth_diff += val;
        }
    }

    // Smooth threshold to remove internal noise
    depth_diff = smoothstep(outline_start, outline_end, depth_diff);

    // Final color
    vec3 final = mix(color, shadow_color, depth_diff);

    ALBEDO = final;
    ALPHA = depth_diff;
}