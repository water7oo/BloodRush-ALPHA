shader_type spatial;

group_uniforms colour;
uniform vec4 albedo1 : source_color = vec4(1.0);

group_uniforms colour.albedo2;
uniform vec4 albedo2 : source_color = vec4(1.0);
uniform sampler2D albedo2_noise;
uniform float albedo2_scale : hint_range(0.0, 1.0, 0.001) = 0.005;
uniform float albedo2_threshold : hint_range(0.0, 1.0, 0.001) = 0.604;

group_uniforms colour.albedo3;
uniform vec4 albedo3 : source_color = vec4(1.0);
uniform sampler2D albedo3_noise;
uniform float albedo3_scale : hint_range(0.0, 0.1, 0.001) = 0.003;
uniform float albedo3_threshold : hint_range(0.0, 1.0, 0.001) = 0.661;

group_uniforms lighting;
uniform int cuts : hint_range(1, 8) = 3;
uniform float wrap : hint_range(-2.0, 2.0) = 0.0;
uniform float steepness : hint_range(1.0, 8.0) = 1.0;

// 🌥️ CLOUD SETTINGS (now LOCAL, not global)
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

varying vec3 vertex_pos;
varying vec3 normal;
varying vec3 vertex_world;

// --- CLOUD FUNCTIONS (inlined) ---

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

// --- MAIN SHADER ---

void vertex() {
	vertex_pos = VERTEX;
	normal = NORMAL;
	vertex_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float albedo2_noise_tex = texture(albedo2_noise, vertex_world.xz * albedo2_scale).r;
	float albedo3_noise_tex = texture(albedo3_noise, vertex_world.xz * albedo3_scale).r;

	ALBEDO = albedo1.rgb;

	if (albedo2_noise_tex > albedo2_threshold) {
		ALBEDO = albedo2.rgb;
	}
	if (albedo3_noise_tex > albedo3_threshold) {
		ALBEDO = albedo3.rgb;
	}
}

void light() {
	float NdotL = dot(NORMAL, LIGHT);
	float diffuse_amount = NdotL + (ATTENUATION - 1.0) + wrap;
	diffuse_amount *= steepness;

	// CLOUDS
	if (LIGHT_IS_DIRECTIONAL) {
		vec3 vertex_world_pos = (MODEL_MATRIX * vec4(vertex_pos, 1.0)).xyz;
		float light_value = get_cloud_noise(vertex_world_pos);
		diffuse_amount = min(diffuse_amount, light_value);
	}

	// Toon shading
	float cuts_inv = 1.0 / float(cuts);
	float original_index = ceil(diffuse_amount * float(cuts));
	float diffuse_stepped = clamp(original_index * cuts_inv, 0.0, 1.0);

	vec3 diffuse = ALBEDO.rgb * LIGHT_COLOR / PI;
	diffuse *= diffuse_stepped;

	DIFFUSE_LIGHT = max(DIFFUSE_LIGHT, diffuse);
}