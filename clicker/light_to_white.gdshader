shader_type canvas_item;

void fragment() {
	// 원본 텍스처 색상 가져오기
	vec4 color = texture(TEXTURE, UV);
	
	// 밝기 계산 (RGB 평균)
	float brightness = (color.r + color.g + color.b) / 3.0;
	
	// 흰색으로 변환 (밝기만 유지, 알파도 유지)
	COLOR = vec4(brightness, brightness, brightness, color.a);
}

