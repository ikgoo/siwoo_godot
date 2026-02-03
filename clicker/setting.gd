extends CanvasLayer

# ========================================
# 설정 화면 - 볼륨, 언어 설정 관리
# ========================================

# 설정 화면이 닫힐 때 발생하는 시그널
signal closed






# 씬 파일의 노드 참조
@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/Title
@onready var master_label: Label = $Panel/VBoxContainer/MasterVolumeContainer/MasterLabel
@onready var master_slider: HSlider = $Panel/VBoxContainer/MasterVolumeContainer/MasterSlider
@onready var master_value: Label = $Panel/VBoxContainer/MasterVolumeContainer/MasterValue
@onready var bgm_label: Label = $Panel/VBoxContainer/BGMVolumeContainer/BGMLabel
@onready var bgm_slider: HSlider = $Panel/VBoxContainer/BGMVolumeContainer/BGMSlider
@onready var bgm_value: Label = $Panel/VBoxContainer/BGMVolumeContainer/BGMValue
@onready var sfx_label: Label = $Panel/VBoxContainer/SFXVolumeContainer/SFXLabel
@onready var sfx_slider: HSlider = $Panel/VBoxContainer/SFXVolumeContainer/SFXSlider
@onready var sfx_value: Label = $Panel/VBoxContainer/SFXVolumeContainer/SFXValue
@onready var language_label: Label = $Panel/VBoxContainer/LanguageContainer/LanguageLabel
@onready var language_option: OptionButton = $Panel/VBoxContainer/LanguageContainer/LanguageOption
@onready var back_button: Button = $Panel/VBoxContainer/ButtonContainer/BackButton
@onready var vbox_container: VBoxContainer = $Panel/VBoxContainer

# 튜토리얼 UI 요소들
var tutorial_checkbox: CheckBox
var tutorial_restart_button: Button


func _ready():
	# 일시정지 중에도 작동하도록 설정 (모든 자식 노드에 적용)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_set_process_mode_recursive(self, Node.PROCESS_MODE_ALWAYS)
	
	# 스타일 설정 (esc_menu와 동일한 스타일)
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	style_box.border_color = Color(0.5, 0.5, 0.5, 1.0)
	style_box.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style_box)
	
	# 현재 설정값 불러와서 UI에 반영
	_load_current_settings()
	
	# 언어 옵션 초기화
	_setup_language_options()
	
	# OptionButton의 팝업 메뉴도 일시정지 중 작동하도록 설정
	var popup = language_option.get_popup()
	if popup:
		popup.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# UI 텍스트 번역 적용
	_update_ui_texts()
	
	# 튜토리얼 UI 추가
	_setup_tutorial_ui()
	
	# 시그널 연결
	master_slider.value_changed.connect(_on_master_volume_changed)
	bgm_slider.value_changed.connect(_on_bgm_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	language_option.item_selected.connect(_on_language_selected)
	back_button.pressed.connect(_on_back_pressed)


## 모든 자식 노드에 process_mode 재귀적으로 설정
func _set_process_mode_recursive(node: Node, mode: ProcessMode):
	node.process_mode = mode
	for child in node.get_children():
		_set_process_mode_recursive(child, mode)


## 현재 설정값을 UI에 반영
func _load_current_settings():
	# 볼륨 슬라이더 초기화
	master_slider.value = Globals.master_volume
	bgm_slider.value = Globals.bgm_volume
	sfx_slider.value = Globals.sfx_volume
	
	# 퍼센트 라벨 업데이트
	_update_volume_label(master_value, Globals.master_volume)
	_update_volume_label(bgm_value, Globals.bgm_volume)
	_update_volume_label(sfx_value, Globals.sfx_volume)


## 언어 옵션 버튼 초기화
func _setup_language_options():
	language_option.clear()
	
	var index = 0
	var current_index = 0
	
	# 사용 가능한 언어들 추가
	for lang_code in Globals.available_languages.keys():
		var lang_name = Globals.available_languages[lang_code]
		language_option.add_item(lang_name, index)
		language_option.set_item_metadata(index, lang_code)
		
		# 현재 언어 선택
		if lang_code == Globals.current_language:
			current_index = index
		
		index += 1
	
	language_option.select(current_index)


## 볼륨 라벨을 퍼센트로 업데이트
## @param label Label 업데이트할 라벨
## @param value float 볼륨 값 (0.0 ~ 1.0)
func _update_volume_label(label: Label, value: float):
	label.text = "%d%%" % int(value * 100)


## 마스터 볼륨 변경 시 호출
## @param value float 새 볼륨 값
func _on_master_volume_changed(value: float):
	Globals.master_volume = value
	_update_volume_label(master_value, value)
	Globals.save_settings()


## BGM 볼륨 변경 시 호출
## @param value float 새 볼륨 값
func _on_bgm_volume_changed(value: float):
	Globals.bgm_volume = value
	_update_volume_label(bgm_value, value)
	Globals.save_settings()


## SFX 볼륨 변경 시 호출
## @param value float 새 볼륨 값
func _on_sfx_volume_changed(value: float):
	Globals.sfx_volume = value
	_update_volume_label(sfx_value, value)
	Globals.save_settings()


## UI 텍스트에 번역 적용
func _update_ui_texts():
	title_label.text = Globals.get_text("SETTING TITLE")
	master_label.text = Globals.get_text("SETTING MASTER")
	bgm_label.text = Globals.get_text("SETTING BGM")
	sfx_label.text = Globals.get_text("SETTING SFX")
	language_label.text = Globals.get_text("SETTING LANGUAGE")
	back_button.text = Globals.get_text("SETTING BACK")


## 언어 선택 시 호출
## @param index int 선택된 항목 인덱스
func _on_language_selected(index: int):
	var lang_code = language_option.get_item_metadata(index)
	Globals.current_language = lang_code
	Globals.save_settings()
	
	# UI 텍스트 즉시 업데이트
	_update_ui_texts()


## 뒤로가기 버튼 클릭 시 호출
func _on_back_pressed():
	# 설정 저장 후 닫기
	Globals.save_settings()
	closed.emit()


## 튜토리얼 UI 설정
func _setup_tutorial_ui():
	# 튜토리얼 컨테이너 생성
	var tutorial_container = HBoxContainer.new()
	tutorial_container.name = "TutorialContainer"
	tutorial_container.process_mode = Node.PROCESS_MODE_ALWAYS  # 일시정지 중에도 작동
	
	# 체크박스 생성
	tutorial_checkbox = CheckBox.new()
	tutorial_checkbox.text = "튜토리얼 팝업 표시"
	tutorial_checkbox.button_pressed = Globals.show_tutorial_popup
	tutorial_checkbox.toggled.connect(_on_tutorial_popup_toggled)
	tutorial_checkbox.process_mode = Node.PROCESS_MODE_ALWAYS  # 일시정지 중에도 작동
	tutorial_container.add_child(tutorial_checkbox)
	
	# 다시 시작 버튼 생성
	tutorial_restart_button = Button.new()
	tutorial_restart_button.text = "튜토리얼 다시 보기"
	tutorial_restart_button.custom_minimum_size = Vector2(150, 0)
	tutorial_restart_button.pressed.connect(_on_tutorial_restart_pressed)
	tutorial_restart_button.process_mode = Node.PROCESS_MODE_ALWAYS  # 일시정지 중에도 작동
	tutorial_container.add_child(tutorial_restart_button)
	
	# ButtonContainer 앞에 추가
	var button_container_index = back_button.get_parent().get_index()
	vbox_container.add_child(tutorial_container)
	vbox_container.move_child(tutorial_container, button_container_index)

## 튜토리얼 팝업 토글
func _on_tutorial_popup_toggled(toggled_on: bool):
	Globals.show_tutorial_popup = toggled_on
	Globals.save_settings()

## 튜토리얼 다시 보기 버튼 클릭
func _on_tutorial_restart_pressed():
	# 설정 창 숨김
	visible = false
	
	# 게임 일시정지 해제
	get_tree().paused = false
	
	# 튜토리얼 완료 상태 초기화
	Globals.is_tutorial_completed = false
	Globals.show_tutorial_popup = true
	Globals.save_settings()
	
	# 게임 재시작
	get_tree().change_scene_to_file("res://main.tscn")

## ESC 키로도 닫을 수 있도록 처리
func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
