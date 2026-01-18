// Two-tone outline shader with light-based visibility
shader_type spatial;
render_mode cull_front, unshaded;

uniform float fade_near = 8.0;   // fully visible
uniform float fade_far  = 20.0;  // fully transparent

uniform vec4 outline_color_lit   : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Lit outline color
uniform vec4 outline_color_unlit : source_color = vec4(0.0, 0.0, 0.0, 1.0); // Unlit outline color
uniform float outline_width : hint_range(0.0, 10.0) = 1.0;
uniform float outline_step: hint_range(0.001, 0.999) = 0.5;

// Directional light direction (set in script or via shader param)
// Should be in WORLD space, normalized, pointing *towards* the object
uniform vec3 light_direction = vec3(0.0, -1.0, -1.0);

void vertex() {
	vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	vec3 clip_normal = mat3(PROJECTION_MATRIX) * (mat3(MODELVIEW_MATRIX) * NORMAL);

	vec2 offset = normalize(clip_normal.xy) / VIEWPORT_SIZE * clip_position.w * outline_width;

	clip_position.xy += offset;
	POSITION = clip_position;
}

void fragment() {
	// World-space normal
	vec3 world_normal = normalize(NORMAL);

	// Light direction
	vec3 L = normalize(light_direction);

	// Lambert term: how much light hits this fragment
	float NdotL = max(dot(world_normal, L), 0.0);

	// Use NdotL as a mask to select between lit/unlit outline colors
	vec4 final_color = mix(outline_color_unlit, outline_color_lit, step(outline_step, NdotL));

	// Distance fade
	float dist = distance(VERTEX, VIEW);
	float fade = 1.0 - smoothstep(fade_near, fade_far, dist);

	ALBEDO = final_color.rgb;
	ALPHA  = final_color.a * fade;

}
