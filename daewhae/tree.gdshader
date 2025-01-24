shader_type canvas_item;

uniform float bend_speed = 0.5;
uniform float bend_strength = 0.15;

void vertex() {
    // 나무 윗부분이 시작되는 지점 (UV 좌표 기준, 0.6은 위에서 60% 지점)
    float tree_top_start = 0.6;
    
    // UV.y가 tree_top_start보다 작은 경우(위쪽)에만 휘어짐 적용
    float bend_factor = step(UV.y, tree_top_start);
    float relative_height = (tree_top_start - UV.y) / tree_top_start;
    
    // sin 함수로 좌우 휘어짐 계산
    float bend = sin(TIME * bend_speed);
    
    // 휘어짐은 위쪽에만 적용되고, 위로 갈수록 더 많이 휘어짐
    float bend_amount = bend * bend_strength * bend_factor * relative_height;
    
    // x 좌표 변경하여 휘어짐 적용
    VERTEX.x += bend_amount * 40.0;
}