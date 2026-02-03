extends Panel

## /** 튜토리얼 팝업 UI
##  * 예/아니오 버튼 처리
##  */

@onready var yes_button: Button = $VBoxContainer/ButtonContainer/YesButton
@onready var no_button: Button = $VBoxContainer/ButtonContainer/NoButton

# 시그널 정의 (TutorialManager가 구독)
signal tutorial_accepted()
signal tutorial_declined()

func _ready():
	print("🎯 [TutorialPopup] _ready 호출됨")
	yes_button.pressed.connect(_on_yes_pressed)
	no_button.pressed.connect(_on_no_pressed)
	print("🎯 [TutorialPopup] 버튼 시그널 연결 완료")

func _on_yes_pressed():
	print("✅ [TutorialPopup] 예 버튼 클릭됨!")
	visible = false
	tutorial_accepted.emit()

func _on_no_pressed():
	print("❌ [TutorialPopup] 아니오 버튼 클릭됨!")
	visible = false
	tutorial_declined.emit()
