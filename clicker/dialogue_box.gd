extends Control
class_name DialogueBox

## /** 튜토리얼 대화창 UI
##  * 하단에 표시되는 대화창으로 타이핑 효과와 함께 텍스트를 표시합니다.
##  */

# ========================================
# 노드 참조
# ========================================
@onready var panel: Panel = $Panel
@onready var fairy_portrait: Sprite2D = $Panel/FairyPortrait
@onready var text_label: RichTextLabel = $Panel/TextLabel
@onready var continue_hint: Label = $Panel/ContinueHint

# ========================================
# Export 설정
# ========================================
@export var fairy_texture: Texture2D  # 요정 초상화 텍스처

# ========================================
# 타이핑 효과 변수
# ========================================
var current_text: String = ""
var displayed_text: String = ""
var typing_index: int = 0
var typing_speed: float = 0.05
var is_typing: bool = false
var typing_timer: float = 0.0

# ========================================
# 대화 진행 변수
# ========================================
var dialogues: Array[String] = []
var current_dialogue_index: int = 0
var is_waiting_for_input: bool = false

# ========================================
# 시그널
# ========================================
signal dialogue_started()  # 대화 시작
signal dialogue_line_complete()  # 한 줄 완료
signal dialogue_all_complete()  # 모든 대화 완료

# ========================================
# 폰트
# ========================================
const GALMURI_9 = preload("res://Galmuri9.ttf")

func _ready():
	# 초기에는 숨김
	visible = false
	
	# 폰트 설정
	text_label.add_theme_font_override("normal_font", GALMURI_9)
	text_label.add_theme_font_size_override("normal_font_size", 18)
	continue_hint.add_theme_font_override("font", GALMURI_9)
	continue_hint.add_theme_font_size_override("font_size", 14)
	
	# 요정 초상화 설정
	if fairy_texture and fairy_portrait:
		fairy_portrait.texture = fairy_texture
	
	# 계속 힌트 숨김
	continue_hint.visible = false

func _process(delta):
	# 타이핑 중이면 타이머 업데이트
	if is_typing:
		typing_timer += delta
		if typing_timer >= typing_speed:
			typing_timer = 0.0
			type_next_character()
	
	# 입력 대기 중이면 Space/Enter 감지
	if is_waiting_for_input:
		if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE):
			next_dialogue()

## /** 대화 시작
##  * @param dialogue_list Array[String] 표시할 대화 목록
##  * @param speed float 타이핑 속도 (글자당 초)
##  * @returns void
##  */
func start_dialogue(dialogue_list: Array[String], speed: float = 0.05):
	print("💬 [대화창] 대화 시작 - 총 %d줄" % dialogue_list.size())
	dialogues = dialogue_list
	current_dialogue_index = 0
	typing_speed = speed
	visible = true
	dialogue_started.emit()
	show_next_line()

## /** 다음 대화 줄 표시
##  * @returns void
##  */
func show_next_line():
	if current_dialogue_index >= dialogues.size():
		# 모든 대화 완료
		print("💬 [대화창] 마지막 줄 완료 - end_dialogue 호출")
		end_dialogue()
		return
	
	print("💬 [대화창] %d번째 줄 표시: %s" % [current_dialogue_index + 1, dialogues[current_dialogue_index]])
	current_text = dialogues[current_dialogue_index]
	displayed_text = ""
	typing_index = 0
	is_typing = true
	is_waiting_for_input = false
	typing_timer = 0.0
	continue_hint.visible = false
	
	# 텍스트 초기화
	text_label.text = ""

## /** 다음 글자 타이핑
##  * @returns void
##  */
func type_next_character():
	if typing_index >= current_text.length():
		# 한 줄 타이핑 완료
		is_typing = false
		is_waiting_for_input = true
		continue_hint.visible = true
		dialogue_line_complete.emit()
		return
	
	displayed_text += current_text[typing_index]
	text_label.text = displayed_text
	typing_index += 1

## /** 타이핑 스킵 (즉시 전체 텍스트 표시)
##  * @returns void
##  */
func skip_typing():
	if is_typing:
		displayed_text = current_text
		text_label.text = displayed_text
		typing_index = current_text.length()
		is_typing = false
		is_waiting_for_input = true
		continue_hint.visible = true
		dialogue_line_complete.emit()

## /** 다음 대화로 진행
##  * @returns void
##  */
func next_dialogue():
	if is_typing:
		# 타이핑 중이면 스킵
		skip_typing()
	else:
		# 다음 줄로
		current_dialogue_index += 1
		show_next_line()

## /** 대화 종료
##  * @returns void
##  */
func end_dialogue():
	print("💬 [대화창] 모든 대화 완료 - signal emit")
	visible = false
	dialogues.clear()
	current_dialogue_index = 0
	is_typing = false
	is_waiting_for_input = false
	dialogue_all_complete.emit()

## /** 대화 즉시 종료 (강제)
##  * @returns void
##  */
func force_close():
	end_dialogue()

