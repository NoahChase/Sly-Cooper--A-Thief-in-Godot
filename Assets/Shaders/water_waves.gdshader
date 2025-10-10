shader_type spatial;
render_mode blend_mix, cull_disabled, specular_disabled;

//////////////////////
// External textures / water params
//////////////////////

uniform float roughness : hint_range(0.0, 1.0) = 0.0;
uniform float transparency : hint_range(0.0, 1.0) = 1.0;
uniform vec3 water_color : source_color = vec3(0.0625, 0.1992, 0.3594);

//////////////////////
// Wave uniforms
//////////////////////
uniform int wave_count : hint_range(1, 6) = 4;
uniform float global_speed = 1.0;
uniform float global_amplitude = 1.0;
uniform float global_wavelength = 1.0;
uniform float global_steepness : hint_range(0.0, 1.0, 0.05) = 0.5;

// per-wave noise offsets (set in inspector / script)
uniform float amp_noise_offset[16];
uniform float wl_noise_offset[16];
uniform float sp_noise_offset[16];
uniform float dir_noise_offset[16];

//////////////////////
// Color uniforms
//////////////////////
uniform vec4 shallow_color : source_color = vec4(0.0, 0.6, 1.0, 1.0);
uniform vec4 deep_color    : source_color = vec4(0.0, 0.0, 0.4, 1.0);
uniform float blend_height = 0.5;   // center of height blend
uniform float blend_range  = 1.0;   // how wide the transition is

//////////////////////
// Noise helpers
//////////////////////
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f*f*(3.0-2.0*f);
	return mix(a, b, u.x) + (c - a)*u.y*(1.0-u.x) + (d - b)*u.x*u.y;
}

//////////////////////
// Gerstner
//////////////////////
vec3 gerstner(vec3 vertex, vec2 direction, float time, float speed, float steepness, float amplitude, float wavelength){
	float k = wavelength;
	float theta = k * dot(direction, vertex.xz) + speed * time;

	float displaced_x = vertex.x + (steepness/k) * direction.x * cos(theta);
	float displaced_z = vertex.z + (steepness/k) * direction.y * cos(theta);
	float displaced_y = vertex.y + amplitude * sin(theta);

	return vec3(displaced_x, displaced_y, displaced_z);
}

vec3 gerstner_normal(vec3 vertex, vec2 direction, float time, float speed, float steepness, float amplitude, float wavelength) {
	float k = wavelength;
	float theta = k * dot(direction, vertex.xz) + speed * time;
	float cosfactor = cos(theta);
	float sinfactor = sin(theta);

	float x_normal = -direction.x * k * amplitude * cosfactor;
	float z_normal = -direction.y * k * amplitude * cosfactor;
	float y_normal = 0.5 - (steepness/k) * k * amplitude * sinfactor;

	return vec3(x_normal, y_normal, z_normal);
}

//////////////////////
// Varyings
//////////////////////
varying float wave_height;

//////////////////////
// Vertex: displace with layered Gerstner waves
//////////////////////
void vertex() {
	vec3 displaced = VERTEX;
	vec3 normal_accum = vec3(0.0);

	for (int i = 0; i < wave_count; i++) {
		// per-wave direction seed (controlled by inspector)
		float angle = noise(vec2(dir_noise_offset[i], 0.0)) * 6.28318530718;
		vec2 dir = normalize(vec2(cos(angle), sin(angle)));

		// per-wave noise-controlled parameters
		float amp = global_amplitude * (0.5 + noise(vec2(amp_noise_offset[i], 13.2)));
		float wl  = global_wavelength * (0.5 + noise(vec2(wl_noise_offset[i], 24.7)));
		float sp  = global_speed * (0.5 + noise(vec2(sp_noise_offset[i], 55.1)));

		displaced = gerstner(displaced, dir, TIME, sp, global_steepness, amp, wl);
		normal_accum += gerstner_normal(displaced, dir, TIME, sp, global_steepness, amp, wl);
	}

	VERTEX = displaced;
	NORMAL = normalize(normal_accum);

	// pass height to fragment
	wave_height = VERTEX.y;
}

//////////////////////
// Fragment: normal mapping
//////////////////////
void fragment() {
	// Make water shiny
	ROUGHNESS = roughness;

	// Height-based water color
	float hblend = smoothstep(blend_height - blend_range, blend_height + blend_range, wave_height);
	vec3 base_color = mix(deep_color.rgb, shallow_color.rgb, hblend);

	ALBEDO = base_color;
	ALPHA = transparency;
}