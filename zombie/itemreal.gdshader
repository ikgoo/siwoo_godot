shader_type spatial;
render_mode unshaded, cull_front, depth_draw_always;

uniform vec4 outline_color : source_color = vec4(1.0, 0.95, 0.5, 1.0);  // 노란색 계열의 외곽선
uniform float outline_width : hint_range(0.0, 1.0) = 0.1;  // 외곽선 두께

void vertex() {
    // 버텍스를 법선 방향으로 확장
    vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
    vec3 clip_normal = normalize(mat3(PROJECTION_MATRIX) * (mat3(MODELVIEW_MATRIX) * NORMAL));

    // 외곽선 생성을 위한 버텍스 확장
    VERTEX += NORMAL * outline_width;
}

void fragment() {
    // 외곽선 색상 설정
    ALBEDO = outline_color.rgb;

    // 외곽선의 알파값 설정
    ALPHA = outline_color.a;
}