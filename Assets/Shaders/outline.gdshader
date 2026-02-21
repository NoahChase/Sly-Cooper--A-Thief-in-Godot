// credit goes to: "axilirate" https://godotshaders.com/shader/pixel-perfect-outline-shader/ https://godotshaders.com/author/axilirate/
shader_type spatial;
render_mode cull_front, unshaded;

uniform float fade_near = 8.0;   // fully visible
uniform float fade_far  = 20.0;  // fully transparent

uniform vec4 outline_color : source_color;
uniform float outline_width = 1.0;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture;

void vertex() {
	vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	vec3 clip_normal = mat3(PROJECTION_MATRIX) * (mat3(MODELVIEW_MATRIX) * NORMAL);

	vec2 offset = normalize(clip_normal.xy) / VIEWPORT_SIZE * clip_position.w * outline_width;

	clip_position.xy += offset;

	POSITION = clip_position;
}

void fragment() {
	ALBEDO = outline_color.rgb;

	// Screen UV
	vec2 uv = SCREEN_UV;

	// Scene depth at this pixel
	float scene_depth = texture(DEPTH_TEXTURE, uv).r;

	// Current fragment depth
	float my_depth = FRAGCOORD.z;

	//// If actual mesh is closer than outline, kill pixel
	//if (scene_depth > my_depth - 0.0005) {
		//discard;
	//}

	// Distance fade
	float dist = distance(VERTEX, VIEW);
	float fade = 1.0 - smoothstep(fade_near, fade_far, dist);

	ALPHA = outline_color.a * fade;
}
