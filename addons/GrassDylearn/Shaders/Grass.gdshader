shader_type spatial;
render_mode depth_prepass_alpha, depth_draw_opaque;

// 🌥️ CLOUD UNIFORMS (LOCAL NOW)
group_uniforms clouds;
uniform sampler2D cloud_noise;
uniform float cloud_scale = 0.03;
uniform float cloud_world_y = 5.0;
uniform float cloud_speed = 0.02;
uniform float cloud_contrast = 2.0;
uniform float cloud_threshold = -0.2;
uniform vec2 cloud_direction = vec2(0.5, 0.5);
uniform vec3 light_direction = vec3(0.0, -1.0, 0.0);
uniform float cloud_shadow_min = 0.4;
uniform float cloud_diverge_angle = 15.0;

// --- CLOUD FUNCTIONS ---
vec2 rotate_vec2(vec2 v, float angle) {
	float a = radians(angle);
	return vec2(
		v.x * cos(a) - v.y * sin(a),
		v.x * sin(a) + v.y * cos(a)
	);
}

float get_cloud_noise(vec3 world_pos) {
	float t = (cloud_world_y - world_pos.y) / light_direction.y;
	vec3 hit_pos = world_pos + t * light_direction;

	float inv_scale = 1.0 / cloud_scale;

	vec2 dir1 = rotate_vec2(cloud_direction, cloud_diverge_angle);
	vec2 dir2 = rotate_vec2(cloud_direction, -cloud_diverge_angle);

	vec2 time_dir1 = TIME * cloud_speed * normalize(dir1);
	vec2 time_dir2 = TIME * cloud_speed * normalize(dir2);

	float sample1 = texture(cloud_noise, hit_pos.xz * inv_scale + time_dir1).r;
	float sample2 = texture(cloud_noise, hit_pos.xz * (inv_scale * 0.8) + (time_dir2 * 0.89)).r;

	float cloud_sample = sample1 * sample2;

	float light_value = clamp(cloud_sample + cloud_threshold, 0.0, 1.0);
	light_value = (light_value - 0.5) * cloud_contrast + 0.5;
	light_value = clamp(light_value + cloud_threshold, cloud_shadow_min, 1.0);

	return light_value;
}