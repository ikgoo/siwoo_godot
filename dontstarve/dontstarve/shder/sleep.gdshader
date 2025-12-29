shader_type canvas_item;

// 졸림 효과 셰이더 (Godot 4.5+)
// 
// 사용법:
// 1. 씬에 CanvasLayer 생성
// 2. 자식으로 BackBufferCopy 노드 추가 (Copy Mode: Viewport, Rect: Full Rect)
// 3. 자식으로 ColorRect 추가 (Anchor: Full Rect, Color: 투명)
// 4. ColorRect Material → New ShaderMaterial → Shader에 이 파일 연결
// 5. character_body_3d.gd에서 update_sleep_overlay_external() 호출

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

// 블러 효과
uniform int blur_samples : hint_range(1, 25) = 9;
uniform float blur_radius : hint_range(0.0, 5.0) = 0.0;

// 비네팅 효과
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.0;
uniform float vignette_size : hint_range(0.0, 2.0) = 0.6;

// 채도 감소
uniform float desaturation : hint_range(0.0, 1.0) = 0.0;

// 눈꺼풀 효과
uniform float eyelid_amount : hint_range(0.0, 0.5) = 0.0;

void fragment(){
	vec4 col = vec4(0.0);
	
	// 블러 효과 (박스 블러)
	if (blur_radius > 0.001 && blur_samples > 0) {
		vec2 pixel_size = 1.0 / SCREEN_PIXEL_SIZE;
		float step_size = blur_radius / float(blur_samples);
		int half_samples = blur_samples / 2;
		
		for (int x = -half_samples; x <= half_samples; x++) {
			for (int y = -half_samples; y <= half_samples; y++) {
				vec2 offset = vec2(float(x), float(y)) * step_size / pixel_size;
				col += texture(screen_texture, SCREEN_UV + offset);
			}
		}
		col /= float((blur_samples + 1) * (blur_samples + 1));
	} else {
		col = texture(screen_texture, SCREEN_UV);
	}

	// 채도 감소 (흑백 효과)
	float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	col.rgb = mix(col.rgb, vec3(gray), desaturation);

	// 비네팅 (화면 가장자리 어둡게)
	vec2 uv = SCREEN_UV * 2.0 - 1.0;
	float dist = length(uv);
	float vignette = smoothstep(vignette_size, vignette_size + 0.4, dist);
	col.rgb *= 1.0 - vignette * vignette_strength;

	// 눈꺼풀 효과 (상/하에서 검게 닫힘)
	if (eyelid_amount > 0.001) {
		float upper = smoothstep(0.5 - eyelid_amount, 0.5, SCREEN_UV.y);
		float lower = 1.0 - smoothstep(0.5, 0.5 + eyelid_amount, SCREEN_UV.y);
		float lid = min(upper, lower);
		col.rgb = mix(vec3(0.0), col.rgb, lid);
	}

	COLOR = col;
}
