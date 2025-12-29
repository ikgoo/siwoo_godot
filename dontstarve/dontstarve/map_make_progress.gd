extends CanvasLayer

## 맵 생성 진행 상황을 표시하는 Progress Bar UI

@onready var progress_bar = $CenterContainer/VBoxContainer/ProgressBar
@onready var label = $CenterContainer/VBoxContainer/Label

## 진행률 업데이트
## @param value: 진행률 (0~100)
## @param status_text: 상태 텍스트 (예: "지형 생성 중...")
func update_progress(value: float, status_text: String = ""):
	if progress_bar:
		progress_bar.value = value
	
	if label and not status_text.is_empty():
		label.text = status_text

## Progress Bar 표시
func show_progress():
	visible = true
	if progress_bar:
		progress_bar.value = 0.0
	if label:
		label.text = "맵 생성 중..."

## Progress Bar 숨기기
func hide_progress():
	visible = false

