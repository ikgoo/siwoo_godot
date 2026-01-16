extends StaticBody3D
class_name Dummy

## 허수아비 타겟
## 데미지를 받고 데미지 숫자를 표시함

# 시그널
signal target_hit(damage: float, position: Vector3)

# 데미지 숫자 씬
var damage_number_scene = preload("res://scenes/ui/damage_number.tscn")

# 헤드 영역 (헤드샷 감지용)
@onready var head_area: Area3D = $HeadArea

func _ready():
	# 충돌 레이어 설정 (레이어 2)
	collision_layer = 2
	collision_mask = 0

# 데미지를 받는 함수
# damage: 받을 데미지
# hit_position: 피격 위치
func take_damage(damage: float, hit_position: Vector3):
	# 멀티플레이어: 서버에서만 데미지 처리
	if multiplayer.get_peers().size() > 0:
		if multiplayer.is_server():
			_apply_damage.rpc(damage, hit_position)
		else:
			# 클라이언트는 서버에 요청
			_request_damage.rpc_id(1, damage, hit_position)
	else:
		# 싱글플레이어
		_apply_damage(damage, hit_position)

# 실제 데미지 적용 (서버 권한)
@rpc("authority", "call_local", "reliable")
func _apply_damage(damage: float, hit_position: Vector3):
	# 데미지 숫자 생성
	spawn_damage_number(damage, hit_position, false)
	
	# 시그널 발생
	target_hit.emit(damage, hit_position)
	
	print("허수아비가 %.1f 데미지를 받았습니다!" % damage)

# 클라이언트가 서버에 데미지 요청
@rpc("any_peer", "reliable")
func _request_damage(damage: float, hit_position: Vector3):
	if multiplayer.is_server():
		_apply_damage.rpc(damage, hit_position)

# 데미지 숫자 생성
# damage: 데미지 값
# position: 표시 위치
# is_headshot: 헤드샷 여부
func spawn_damage_number(damage: float, position: Vector3, is_headshot: bool):
	if not damage_number_scene:
		return
	
	var damage_number = damage_number_scene.instantiate()
	get_tree().root.add_child(damage_number)
	damage_number.global_position = position
	damage_number.setup(damage, is_headshot)

