shader_type spatial;
render_mode shadows_disabled;

// ===== PIXEL SETTINGS =====
uniform float pixel_size : hint_range(0.001, 0.05) = 0.01;
uniform float color_steps : hint_range(2.0, 16.0) = 5.0;

// ===== COLOR =====
uniform vec3 absorption_color : source_color = vec3(1.0, 0.35, 0.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.15;
uniform float specular : hint_range(0.0, 1.0) = 0.25;

uniform float depth_distance = 25.0;
uniform float beers_law = 4.5;

// ===== DISPLACEMENT =====
uniform float displacement_strength = 0.3;
uniform float displacement_scroll_speed = 0.1;
uniform vec2 displacement_scale = vec2(0.04);
uniform sampler2D displacement_texture;

// ===== NORMAL MAP =====
uniform sampler2D normal_map : hint_normal;
uniform float normal_map_strength = 1.0;
uniform float scroll_speed = 0.3;
uniform vec2 normal_map_scale = vec2(0.1);

// ===== CAUSTICS =====
uniform float caustic_size = 2.0;
uniform float caustic_range = 40.0;
uniform float caustic_strength = 0.08;

// ===== SCREEN =====
uniform sampler2D screen_texture : hint_screen_texture;
uniform sampler2D depth_texture : hint_depth_texture;

// ===== GLOBALS =====
global uniform float wind_intensity;
global uniform vec3 wind_direction;

// ===== VARYING =====
varying vec3 global_position;

// ===== NOISE (unchanged from yours) =====
vec4 permute(vec4 t){return t*(t*34.0+133.0);}
vec3 grad(float hash){
	vec3 cube=mod(floor(hash/vec3(1.0,2.0,4.0)),2.0)*2.0-1.0;
	vec3 cuboct=cube;
	cuboct[int(hash/16.0)]=0.0;
	float type=mod(floor(hash/8.0),2.0);
	vec3 rhomb=(1.0-type)*cube+type*(cuboct+cross(cube,cuboct));
	vec3 g=fma(cuboct,vec3(1.22474487139),rhomb);
	g*=fma(-0.0429424367,type,1.0)*3.5946317686;
	return g;
}

vec4 os2NoiseWithDerivatives_Fallback(vec3 X){
	X = dot(X, vec3(2.0/3.0)) - X;
	vec4 r = vec4(0.0);
	for(int i=0;i<2;i++){
		vec3 v = X + float(i)*144.5;
		vec3 b=floor(v);
		vec3 d=v-b;
		float h=fract(sin(dot(b,vec3(12.9898))) * 43758.5453);
		r.w += dot(d, grad(h));
	}
	return r;
}

// ===== PIXEL HELPERS =====
vec2 pixelate_uv(vec2 uv){
	return floor(uv / pixel_size) * pixel_size;
}

vec3 quantize(vec3 c){
	return floor(c * color_steps) / color_steps;
}

// ===== VERTEX =====
void vertex(){
	global_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;

	float time = TIME * displacement_scroll_speed;
	float d = texture(displacement_texture, global_position.xz * displacement_scale + time).r;
	d = (d * 2.0 - 1.0) * displacement_strength;

	VERTEX.y += d;
	global_position.y += d;
}

// ===== FRAGMENT =====
void fragment(){

	vec2 uv = pixelate_uv(SCREEN_UV);

	vec3 screen = texture(screen_texture, uv).rgb;

	// ===== DEPTH =====
	float depth_tex = texture(depth_texture, uv).r;

	vec3 ndc = vec3(uv * 2.0 - 1.0, depth_tex);
	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	world.xyz /= world.w;

	float depth_diff = global_position.y - world.y;

	float depth_blend = clamp(depth_diff / depth_distance, 0.0, 1.0);
	depth_blend = 1.0 - exp(-depth_blend * beers_law);

	// ===== NORMAL =====
	vec3 n = texture(normal_map, global_position.xz * normal_map_scale + TIME * scroll_speed).xyz;
	NORMAL_MAP = n;
	NORMAL_MAP_DEPTH = normal_map_strength;

	// ===== CAUSTICS (SHARP VERSION) =====
	float caustic_value = 0.0;

	float range_mod = clamp((VERTEX.z + caustic_range) * 0.05, 0.0, 1.0);

	if (range_mod > 0.0) {

		vec3 X = vec3(world.xz * caustic_size, TIME * 0.5);

		vec4 noiseResult = os2NoiseWithDerivatives_Fallback(X);
		noiseResult = os2NoiseWithDerivatives_Fallback(X - noiseResult.xyz / 16.0);

		float raw = noiseResult.w * 0.5 + 0.5;

		// 🔥 SHARPEN
		raw = pow(raw, 6.0);

		// 🔥 HARD THRESHOLD
		float cutoff = 0.6;
		float hard = step(cutoff, raw);

		// slight smoothing to avoid ugly aliasing
		float soft = smoothstep(cutoff - 0.05, cutoff + 0.05, raw);

		raw = mix(hard, soft, 0.3);

		// optional shimmer
		raw *= 0.9 + 0.1 * sin(TIME * 10.0);

		caustic_value = raw * range_mod * range_mod;
	}

	// ===== COLOR =====
	vec3 color = screen - absorption_color * depth_blend;
	color = mix(color, vec3(1.0) - absorption_color, depth_blend * depth_blend);

	color += caustic_value * caustic_strength;

	// ===== PIXEL LOOK =====
	color = quantize(color);

	ALBEDO = color;
	ROUGHNESS = roughness;
	SPECULAR = specular;
}