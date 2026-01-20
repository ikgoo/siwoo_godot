extends Node2D

## 텔레포트 목적지 위치
@export var teleport_destination: Vector2 = Vector2(0, 0)
## 액션바에 표시될 텍스트
@export var action_text: String = "[F] 텔레포트"

## Area 안에 있는 캐릭터 참조
var character_in_area: CharacterBody2D = null

func _ready():
	pass


func _process(delta):
	# 캐릭터가 Area 안에 있고 F키를 눌렀는지 확인
	if character_in_area != null and Input.is_key_pressed(KEY_F):
		teleport_character()


func teleport_character():
	if character_in_area != null:
		# 텔레포트 목적지를 전역 좌표로 변환하여 캐릭터 이동
		character_in_area.global_position = teleport_destination


func _on_area_2d_body_entered(body):
	# 들어온 객체가 CharacterBody2D인지 확인
	if body is CharacterBody2D:
		character_in_area = body
		# UI에 액션 텍스트 표시
		Globals.show_action_text(action_text)

func _on_area_2d_body_exited(body):
	# 나간 객체가 저장된 캐릭터와 같은지 확인
	if body == character_in_area:
		character_in_area = null
		# UI에서 액션 텍스트 숨김
		Globals.hide_action_text()
