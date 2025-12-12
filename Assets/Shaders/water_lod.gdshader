shader_type spatial;
render_mode blend_mix, cull_back, diffuse_burley, specular_disabled;

uniform sampler2D wave_height_1;
uniform sampler2D wave_height_2;
uniform sampler2D normal_map_1 : hint_normal;

uniform float world_scale = 10.0;

uniform float wave_speed_1 = 0.05;
uniform float wave_speed_2 = 0.025;
uniform float final_wave_speed = 0.5;
uniform float wave_scale_1 = 2.0;
uniform float wave_scale_2 = 1.0;
uniform float final_wave_scale = 1.0;

uniform float normal_mult = 0.1;
uniform float normal_height = 0.4;

uniform vec3 albedo : source_color = vec3(0.1, 0.2, 0.3);
uniform float roughness = 0.05;
uniform float transparency = 0.85;
uniform float specular = 1.0;
uniform float metallic = 0.5;

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// world-space UVs
	vec2 uv1 = (v_world_pos.xz / world_scale) + TIME * wave_speed_1 * final_wave_speed;
	vec2 uv2 = (v_world_pos.xz / world_scale) - TIME * wave_speed_2 * final_wave_speed;

	// multiple layer vertex displacement
	float h1 = texture(wave_height_1, uv1).r * wave_scale_1;
	float h2 = texture(wave_height_2, uv2).r * wave_scale_2;
	VERTEX.y += (h1 + h2) * final_wave_scale;
}

void fragment() {
	vec2 uv1 = (v_world_pos.xz / world_scale) + TIME * wave_speed_1 * final_wave_speed;

	// single normal map
	vec3 n1 = texture(normal_map_1, uv1).rgb * 2.0 - 1.0;
	n1.xy *= normal_height;

	// additive screen-space style normals
	NORMAL = normalize(NORMAL + n1 * normal_mult);

	// shading
	ALBEDO = albedo;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	METALLIC = metallic;
	ALPHA = transparency;
}
