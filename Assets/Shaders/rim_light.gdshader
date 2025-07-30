shader_type spatial;
render_mode blend_mix, cull_back;

uniform vec4 rim_color : source_color = vec4(0.4, 0.6, 1.0, 1.0); // Blue rim
uniform float rim_intensity = 2.0;
uniform float rim_power = 2.0;
uniform float rim_threshold = 0.07;

void fragment() {
    vec3 N = normalize(NORMAL);
    vec3 V = normalize(-VIEW);
    float rim = max(dot(V, N), 0.0);
	rim = smoothstep(rim_threshold - 0.1, rim_threshold + 0.1, rim);
    rim = pow(rim, rim_power);
    ALBEDO = rim_color.rgb;
    ALPHA = rim * rim_intensity;
}