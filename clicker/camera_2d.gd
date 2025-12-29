extends Camera2D

@onready var character = $"../character"

# 카메라가 플레이어를 따라가는 속도 (0~1 사이, 클수록 빠름)
var follow_speed : float = 0.1



func _ready():
	# 시작 시 캐릭터 위치로 카메라 설정
	if character:
		global_position = character.global_position



func _process(delta):
	if character:
		# lerp를 사용해 현재 위치에서 캐릭터 위치로 부드럽게 이동
		global_position = global_position.lerp(character.global_position, follow_speed)
