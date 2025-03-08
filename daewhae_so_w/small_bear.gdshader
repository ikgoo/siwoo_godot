shader_type canvas_item;

uniform float pixel_size : hint_range(1, 100) = 4.0;

void fragment() {
    vec2 uv = SCREEN_UV;
    uv -= mod(uv, vec2(pixel_size) / vec2(textureSize(TEXTURE, 0)));
    COLOR = texture(TEXTURE, uv);
}