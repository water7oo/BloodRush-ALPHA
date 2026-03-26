// MIT License.
// Made by Dylearn
// Fixed: cloud_direction type conflict + rotation + duplicate variable

global uniform sampler2D cloud_noise;      // Noise for cloud simulation
global uniform float cloud_scale;          // Scale of cloud noise
global uniform float cloud_world_y;        // Height where clouds cast shadows
global uniform float cloud_speed;          // Speed of cloud movement
global uniform float cloud_contrast;       // Steepness of noise
global uniform float cloud_threshold;      // Brightness cutoff
global uniform float cloud_direction;      // ✅ MUST remain float (angle in radians)
global uniform vec3 light_direction;       // Directional light direction
global uniform float cloud_shadow_min;     // Minimum shadow darkness
global uniform float cloud_diverge_angle;  // Angle between noise directions


// -----------------------------
// Rotate a 2D vector (angle in degrees)
// -----------------------------
vec2 rotate_vec2(vec2 v, float angle) {
	float rad = radians(angle);
	float c = cos(rad);
	float s = sin(rad);
	return vec2(
		v.x * c - v.y * s,
		v.x * s + v.y * c
	);
}


// -----------------------------
// Cloud shadow sampling
// -----------------------------
float get_cloud_noise(vec3 world_pos) {

	// Project world position onto cloud plane
	float t = (cloud_world_y - world_pos.y) / light_direction.y;
	vec3 hit_pos = world_pos + t * light_direction;

	float inv_scale = 1.0 / cloud_scale;

	// -----------------------------
	// Convert float direction → vec2
	// -----------------------------
	vec2 base_dir = vec2(cos(cloud_direction), sin(cloud_direction));

	// -----------------------------
	// Dual noise (non-repeating clouds)
	// -----------------------------
	vec2 dir1 = rotate_vec2(base_dir, cloud_diverge_angle);
	vec2 dir2 = rotate_vec2(base_dir, -cloud_diverge_angle);

	vec2 move1 = TIME * cloud_speed * normalize(dir1);
	vec2 move2 = TIME * cloud_speed * normalize(dir2);

	float sample1 = texture(cloud_noise, hit_pos.xz * inv_scale + move1).r;
	float sample2 = texture(
		cloud_noise,
		hit_pos.xz * (inv_scale * 0.8) + (move2 * 0.89 * PI / 3.0)
	).r;

	float cloud_sample = sample1 * sample2;

	// Base light value
	float light_value = clamp(cloud_sample + cloud_threshold, 0.0, 1.0);

	// -----------------------------
	// Simple cloud layer (blended, not overriding)
	// -----------------------------
	vec2 cloud_offset = base_dir * cloud_speed * TIME;
	vec2 light_uv = hit_pos.xz * inv_scale + cloud_offset;

	float simple_cloud = texture(cloud_noise, light_uv).r;

	// Blend both methods (better visuals)
	light_value = mix(light_value, simple_cloud, 0.3);

	// Contrast + threshold shaping
	light_value = (light_value - 0.5) * cloud_contrast + 0.5;
	light_value = clamp(light_value + cloud_threshold, cloud_shadow_min, 1.0);

	return light_value;
}