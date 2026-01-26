shader_type canvas_item;

// 하이라이트할 타일의 월드 좌표 (중심점)
uniform vec2 highlight_position = vec2(-99999.0, -99999.0);
// 타일 크기 (픽셀) - breakable_tile은 16x16
uniform vec2 tile_size = vec2(16.0, 16.0);
// 하이라이트 색상 (밝기 조절용, 1.0 이상이면 밝아짐)
uniform vec4 highlight_color : source_color = vec4(1.4, 1.4, 1.0, 1.0);
// 하이라이트 활성화 여부
uniform bool highlight_enabled = false;

// vertex에서 fragment로 월드 좌표 전달
varying vec2 world_position;

void vertex() {
	// 월드 좌표 계산해서 varying으로 전달
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// 원본 텍스처 색상
	vec4 original_color = texture(TEXTURE, UV);
	
	if (highlight_enabled && original_color.a > 0.0) {
		// 하이라이트 타일 범위 계산
		vec2 half_tile = tile_size / 2.0;
		vec2 min_pos = highlight_position - half_tile;
		vec2 max_pos = highlight_position + half_tile;
		
		// 현재 픽셀이 하이라이트 타일 범위 내에 있는지 확인
		if (world_position.x >= min_pos.x && world_position.x <= max_pos.x &&
			world_position.y >= min_pos.y && world_position.y <= max_pos.y) {
			// 하이라이트 적용 (색상 곱하기로 밝기 조절)
			COLOR = original_color * highlight_color;
		} else {
			COLOR = original_color;
		}
	} else {
		COLOR = original_color;
	}
}
