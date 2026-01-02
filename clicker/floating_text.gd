extends Label

## 떠오르는 텍스트 스크립트
## 돈 획득, 데미지 등을 표시하는 용도

# 폰트 로드
const GALMURI_9_FONT = preload("res://Galmuri9.ttf")

# 떠오르는 속도 및 거리
@export var float_distance: float = 80.0
@export var float_duration: float = 1.2
@export var fade_start: float = 0.6  # 언제부터 페이드 아웃 시작할지 (0~1)

func _ready():
	# 기본 설정
	z_index = 1000
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# 폰트 설정
	add_theme_font_override("font", GALMURI_9_FONT)
	add_theme_font_size_override("font_size", 16)
	
	# 텍스트 외곽선 (가독성)
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	add_theme_constant_override("outline_size", 2)
	
	# 애니메이션 시작
	animate()

## 떠오르는 애니메이션
func animate():
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 위로 떠오르기
	var start_pos = position
	var end_pos = start_pos + Vector2(0, -float_distance)
	tween.tween_property(self, "position", end_pos, float_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	# 페이드 아웃
	tween.tween_property(self, "modulate:a", 0.0, float_duration * (1.0 - fade_start)).set_delay(float_duration * fade_start)
	
	# 약간의 좌우 흔들림 (선택적)
	var wobble_tween = create_tween()
	wobble_tween.tween_property(self, "position:x", start_pos.x + 10, 0.3).set_ease(Tween.EASE_IN_OUT)
	wobble_tween.tween_property(self, "position:x", start_pos.x - 10, 0.3).set_ease(Tween.EASE_IN_OUT)
	wobble_tween.tween_property(self, "position:x", end_pos.x, 0.3).set_ease(Tween.EASE_IN_OUT)
	
	# 애니메이션 끝나면 자동 삭제
	tween.finished.connect(queue_free)

## 정적 생성 함수 - 다른 스크립트에서 쉽게 사용 가능
static func create(parent: Node, pos: Vector2, txt: String, color: Color = Color.WHITE) -> Label:
	var floating_text = Label.new()
	floating_text.text = txt
	floating_text.position = pos
	floating_text.modulate = color
	floating_text.z_index = 1000
	floating_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	floating_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	floating_text.label_settings = LabelSettings.new()
	const GALMURI_9 = preload("res://Galmuri9.ttf")
	floating_text.label_settings.font = GALMURI_9
	floating_text.label_settings.font_size = 10
	# 아웃라인 설정 (LabelSettings에서 직접 설정)
	floating_text.label_settings.outline_size = 2
	floating_text.label_settings.outline_color = Color(0.566, 0.56, 0.0, 1.0)
	
	parent.add_child(floating_text)
	
	# 애니메이션 (일자로 올라감)
	var tween = parent.create_tween()
	tween.set_parallel(true)
	var end_pos = pos + Vector2(0, -50)
	tween.tween_property(floating_text, "position", end_pos, 1.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(floating_text, "modulate:a", 0.0, 0.6).set_delay(0.6)
	
	tween.finished.connect(floating_text.queue_free)
	
	return floating_text
