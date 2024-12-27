shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float pixel_size = 3.0; // Controls the size of the "pixels"

void fragment() {
    // Calculate scaled UV coordinates
    vec2 uv = UV * SCREEN_PIXEL_SIZE.xy / pixel_size;
    uv = floor(uv) / (SCREEN_PIXEL_SIZE.xy / pixel_size);

    // Sample the screen texture
    COLOR = texture(SCREEN_TEXTURE, uv);
}
