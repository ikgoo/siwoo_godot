extends Node3D

@onready var sprite_3d = $Sprite3D
const MAKING_NOTE = preload("uid://di76m0xa8r77h")

# 클릭 입력을 무시하기 위한 플래그
var ignore_next_click = false
var resipis : resipi
@export var thing : obsticle:
	set(value):
		thing = value
		# thing이 설정되면 한 프레임 동안 클릭 입력 무시
		ignore_next_click = true
		# thing이 설정되면 Sprite3D 업데이트
		if thing and is_node_ready():
			update_sprite()

func _ready():
	# 초기 thing이 있으면 스프라이트 업데이트
	if thing:
		update_sprite()
	
## thing의 이미지를 Sprite3D에 표시하는 함수
func update_sprite():
	get_parent().is_click_move = false
	if sprite_3d and thing and thing.img:
		sprite_3d.texture = thing.img
		# offset도 적용
		sprite_3d.offset.y = thing.offset
		print("making_veiw 스프라이트 업데이트: ", thing.name if thing else "없음")
	elif sprite_3d:
		sprite_3d.texture = null

## 매 프레임 호출되는 함수 - 마우스 위치를 추적합니다
## delta: 프레임 간 경과 시간
func _process(_delta):
	# 마우스 화면 좌표를 월드 좌표로 변환
	var mouse_pos = get_viewport().get_mouse_position()

	
	if Globals.mouse_pos != Vector3.ZERO:
		# Y좌표는 현재 위치 유지, X와 Z만 마우스 위치로 업데이트
		position.x = Globals.mouse_pos.x
		position.y = Globals.mouse_pos.y
		position.z = Globals.mouse_pos.z
	
	# 클릭 입력 처리
	if Input.is_action_just_pressed("clicks"):
		if thing:
			# 제작 버튼 클릭 직후라면 이번 클릭 무시
			if ignore_next_click:
				ignore_next_click = false
				print("제작 버튼 클릭 무시됨")
				return
			
			# 정상적인 설치 처리
			print("obsticle 설치됨")
			var a = MAKING_NOTE.instantiate()
			a.thing = thing
			a.global_position = global_position
			a.resipis = resipis
			get_parent().add_child(a)
			thing = null
			update_sprite()
			get_parent().is_click_move = true
