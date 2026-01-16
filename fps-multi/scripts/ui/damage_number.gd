extends Label3D
class_name DamageNumber

## 데미지 숫자 표시
## 3D 공간에서 위로 떠오르며 페이드아웃됨

# 애니메이션 설정
var lifetime: float = 1.0
var rise_speed: float = 1.5
var fade_speed: float = 2.0
var spread_amount: float = 0.3

# 타이머
var time_elapsed: float = 0.0

func _ready():
	# 빌보드 모드 설정 (항상 카메라를 향함)
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
	# 랜덤한 방향으로 약간 퍼짐
	var random_offset = Vector3(
		randf_range(-spread_amount, spread_amount),
		0,
		randf_range(-spread_amount, spread_amount)
	)
	global_position += random_offset

func _process(delta):
	time_elapsed += delta
	
	# 위로 떠오름
	global_position.y += rise_speed * delta
	
	# 페이드아웃
	modulate.a = 1.0 - (time_elapsed / lifetime)
	
	# 수명 종료 시 제거
	if time_elapsed >= lifetime:
		queue_free()

# 데미지 숫자 설정
# damage: 표시할 데미지
# is_headshot: 헤드샷 여부
func setup(damage: float, is_headshot: bool):
	text = str(int(damage))
	
	if is_headshot:
		# 헤드샷은 빨간색, 크게
		modulate = Color(1.0, 0.2, 0.2)
		font_size = 32
	else:
		# 일반 공격은 흰색
		modulate = Color(1.0, 1.0, 1.0)
		font_size = 24

