extends Node2D

## 로비 씬 스크립트
## 버튼 호버 효과를 관리합니다

# 버튼 참조
@onready var start_button = $start
@onready var setting_button = $setting
@onready var exit_button = $exit

# 각 버튼의 원래 위치와 크기 저장
var button_original_data: Dictionary = {}

# 호버 효과 설정
@export var hover_offset_x: float = 20.0  # 호버 시 x좌표 이동 거리 (오른쪽으로)
@export var animation_duration: float = 0.2  # 애니메이션 지속 시간

func _ready():
	# 모든 버튼의 원래 데이터 저장
	save_button_original_data(start_button)
	save_button_original_data(setting_button)
	save_button_original_data(exit_button)
	
	# 각 버튼에 시그널 연결
	connect_button_signals(start_button)
	connect_button_signals(setting_button)
	connect_button_signals(exit_button)

## 버튼의 원래 위치와 크기 저장
func save_button_original_data(button: Button):
	if button:
		# Control 노드는 offset_left, offset_top 사용
		button_original_data[button] = {
			"offset_left": button.offset_left,
			"offset_top": button.offset_top,
			"z_index": button.z_index
		}

## 버튼 시그널 연결
func connect_button_signals(button: Button):
	if button:
		button.mouse_entered.connect(func(): on_button_hover(button))
		button.mouse_exited.connect(func(): on_button_unhover(button))

## 마우스가 버튼에 올라갔을 때
func on_button_hover(button: Button):
	if not button or not button_original_data.has(button):
		return
	
	var original = button_original_data[button]
	
	# 기존 Tween 정리
	if button.has_meta("hover_tween"):
		var old_tween = button.get_meta("hover_tween")
		if old_tween:
			old_tween.kill()
	
	# 새로운 Tween 생성
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# x좌표 이동 (오른쪽으로)
	var new_offset_left = original.offset_left + hover_offset_x
	tween.tween_property(button, "offset_left", new_offset_left, animation_duration)
	
	# z_index 증가 (앞으로 나오는 효과)
	button.z_index = original.z_index + 1
	
	# Tween 참조 저장
	button.set_meta("hover_tween", tween)

## 마우스가 버튼에서 벗어났을 때
func on_button_unhover(button: Button):
	if not button or not button_original_data.has(button):
		return
	
	var original = button_original_data[button]
	
	# 기존 Tween 정리
	if button.has_meta("hover_tween"):
		var old_tween = button.get_meta("hover_tween")
		if old_tween:
			old_tween.kill()
	
	# 새로운 Tween 생성
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# x좌표 원래대로
	tween.tween_property(button, "offset_left", original.offset_left, animation_duration)
	
	# z_index 원래대로
	button.z_index = original.z_index
	
	# Tween 참조 저장
	button.set_meta("hover_tween", tween)
