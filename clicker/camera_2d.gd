extends Camera2D

@onready var character = $"../character"

# 카메라가 플레이어를 따라가는 속도 (0~1 사이, 클수록 빠름)
var follow_speed : float = 0.2

# 카메라 고정 관련 변수
var is_locked : bool = false  # 카메라가 특정 위치에 고정되었는지
var locked_target_position : Vector2 = Vector2.ZERO  # 고정된 목표 위치



func _ready():
	# 카메라를 그룹에 추가 (rock.gd에서 찾을 수 있도록)
	add_to_group("camera")
	
	# 시작 시 캐릭터 위치로 카메라 설정
	if character:
		global_position = character.global_position



func _process(_delta):
	if is_locked:
		# 카메라가 고정된 경우: 고정된 위치로 부드럽게 이동
		global_position = global_position.lerp(locked_target_position, follow_speed)
	elif character:
		# 일반 모드: 캐릭터를 따라가기
		global_position = global_position.lerp(character.global_position, follow_speed)

# 카메라를 특정 위치에 고정
func lock_to_target(target_position: Vector2):
	is_locked = true
	locked_target_position = target_position

# 카메라 고정 해제
func unlock_from_target():
	is_locked = false
