shader_type canvas_item;

uniform float bend_strength : hint_range(-1.0, 1.0) = 0.3; // 휘어짐 강도
uniform float bend_height : hint_range(0.0, 1.0) = 0.5;    // 휘어짐이 시작되는 높이

void fragment() {
    vec2 uv = UV;
    float height_factor = smoothstep(bend_height, 1.0, uv.y);
    uv.x += bend_strength * height_factor;
    COLOR = texture(TEXTURE, uv);
}