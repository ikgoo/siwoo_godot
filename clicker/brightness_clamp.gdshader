shader_type canvas_item;

// 빛 압축 강도 (높을수록 밝은 부분이 더 눌림)
uniform float compression : hint_range(0.1, 10.0) = 4.0;

// 화면 텍스처 가져오기 (Godot 4 방식)
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	// 화면 색상 가져오기
	vec4 color = texture(screen_texture, SCREEN_UV);
	
	// Reinhard 톤매핑 적용 (밝은 부분만 압축)
	color.rgb = color.rgb / (1.0 + color.rgb * compression);
	
	// 밝기 보정 (기존 1.0 + compression에서 줄임)
	color.rgb *= (1.0 + compression * 0.3);
	
	COLOR = color;
}
