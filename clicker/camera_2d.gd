extends Camera2D

@onready var character = $"../character"

# 카메라가 플레이어를 따라가는 속도 (0~1 사이, 클수록 빠름)
var follow_speed : float = 0.2

# 카메라 고정 관련 변수
var is_locked : bool = false  # 카메라가 특정 위치에 고정되었는지
var locked_target_position : Vector2 = Vector2.ZERO  # 고정된 목표 위치

# 줌 관련 변수
var default_zoom : Vector2 = Vector2(2, 2)  # 기본 줌 레벨
var target_zoom : Vector2 = Vector2(2, 2)  # 목표 줌 레벨
var zoom_speed : float = 2.0  # 줌 변경 속도

# y 제한 관련 확대 변수
var y_limit : float = 88.0  # 카메라 y 제한선
var max_zoom_distance : float = 100.0  # 이 거리만큼 내려가면 최대 확대
var max_extra_zoom : float = 0.8  # 최대 추가 확대량 (기본줌 + 이 값)



func _ready():
	# 카메라를 그룹에 추가 (rock.gd에서 찾을 수 있도록)
	add_to_group("camera")
	
	# 시작 시 캐릭터 위치로 카메라 설정
	if character:
		global_position = character.global_position
	
	# 기본 줌 레벨 저장
	default_zoom = zoom
	target_zoom = zoom



func _process(delta):
	if is_locked:
		# 카메라가 고정된 경우: 고정된 위치로 부드럽게 이동
		global_position = global_position.lerp(locked_target_position, follow_speed)
	elif character:
		# 일반 모드: 캐릭터를 따라가기
		global_position = global_position.lerp(character.global_position, follow_speed)
	
	# 캐릭터가 y_limit 아래에 있으면 거리에 비례해서 확대
	_update_zoom_by_y_distance()
	
	# 줌 부드럽게 변경
	zoom = zoom.lerp(target_zoom, zoom_speed * delta)

# 카메라를 특정 위치에 고정
func lock_to_target(target_position: Vector2):
	is_locked = true
	locked_target_position = target_position

# 카메라 고정 해제
func unlock_from_target():
	is_locked = false

# 카메라가 목표 위치에 거의 도착했는지 확인
func is_near_target(threshold: float = 5.0) -> bool:
	if not is_locked:
		return false
	return global_position.distance_to(locked_target_position) < threshold

# 카메라가 목표 위치에 도착할 때까지 대기
func wait_until_arrived(threshold: float = 5.0, max_wait_time: float = 5.0):
	if not is_locked:
		return
	
	var elapsed_time = 0.0
	while not is_near_target(threshold) and elapsed_time < max_wait_time:
		await get_tree().process_frame
		elapsed_time += get_process_delta_time()

# === y 거리에 따른 자동 줌 ===

## 캐릭터가 y_limit 아래에 있을 때 거리에 비례해서 확대
func _update_zoom_by_y_distance():
	if not character or is_locked:
		return
	
	var char_y = character.global_position.y
	
	if char_y > y_limit:
		# y_limit 아래로 내려간 거리 계산
		var distance_below = char_y - y_limit
		
		# 거리 비율 계산 (0.0 ~ 1.0 사이로 클램프)
		var zoom_ratio = clamp(distance_below / max_zoom_distance, 0.0, 1.0)
		
		# 추가 확대량 계산 (거리에 비례)
		var extra_zoom = max_extra_zoom * zoom_ratio
		
		# 목표 줌 설정 (기본 줌 + 추가 확대)
		target_zoom = default_zoom + Vector2(extra_zoom, extra_zoom)
	else:
		# y_limit 위에 있으면 기본 줌으로 복귀
		target_zoom = default_zoom

# === 줌 제어 함수들 ===

func zoom_in(zoom_level: Vector2 = Vector2(3, 3), duration: float = 1.0):
	target_zoom = zoom_level
	zoom_speed = 1.0 / duration if duration > 0 else 2.0
	print("카메라 클로즈업: ", zoom_level)


func zoom_out(duration: float = 1.0):
	target_zoom = default_zoom
	zoom_speed = 1.0 / duration if duration > 0 else 2.0
	print("카메라 줌 복원: ", default_zoom)

func is_zoom_reached(threshold: float = 0.1) -> bool:
	return zoom.distance_to(target_zoom) < threshold

func wait_until_zoom_reached(threshold: float = 0.1, max_wait_time: float = 5.0):
	var elapsed_time = 0.0
	while not is_zoom_reached(threshold) and elapsed_time < max_wait_time:
		await get_tree().process_frame
		elapsed_time += get_process_delta_time()
