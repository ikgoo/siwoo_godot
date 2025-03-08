extends Camera2D

var min_zoom = Vector2(1, 1)
var max_zoom = Vector2(6, 6)
var zoom_speed = 0.15
var zoom_target = Vector2(1, 1)
var zoom_smoothness = 15.0

# 카메라 이동 관련 변수
var move_speed = 500  # 카메라 이동 속도
const MIN_POSITION = Vector2(-3000, -2000)  # 최소 위치 조정
const MAX_POSITION = Vector2(3000, 2000)    # 최대 위치 조정
var target_position = Vector2.ZERO  # 목표 위치
var is_moving_to_target = false  # 목표 위치로 이동 중인지 여부

const CAMERA_BOUNDS_MIN = Vector2(-3000, -2000)
const CAMERA_BOUNDS_MAX = Vector2(3000, 2000)

var dragging = false
var drag_start_position = Vector2()

func _process(delta):
	if Main.go:
		# 줌 레벨 업데이트
		zoom = zoom.lerp(zoom_target, delta * zoom_smoothness)
		
		# 입력 처리
		var input_dir = Vector2.ZERO
		
		# WASD 키 입력 처리
		if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
			input_dir.x += 1
		if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
			input_dir.x -= 1
		if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
			input_dir.y += 1
		if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
			input_dir.y -= 1
		
		input_dir = input_dir.normalized()
		
		# 화면 크기 계산
		var effective_view_size = get_viewport_rect().size / zoom
		var half_view = effective_view_size / 2
		
		if is_moving_to_target:
			# 목표 위치로 부드럽게 이동
			position = position.lerp(target_position, delta * 2)
			if position.distance_to(target_position) < 1:
				is_moving_to_target = false
		else:
			# 일반 이동
			var new_position = position + input_dir * move_speed * delta
			new_position.x = clamp(new_position.x, MIN_POSITION.x + half_view.x, MAX_POSITION.x - half_view.x)
			new_position.y = clamp(new_position.y, MIN_POSITION.y + half_view.y, MAX_POSITION.y - half_view.y)
			position = new_position

func _unhandled_input(event):
	if Main.go:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_target = zoom_target + Vector2(zoom_speed, zoom_speed)
				zoom_target = zoom_target.clamp(min_zoom, max_zoom)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom_target = zoom_target - Vector2(zoom_speed, zoom_speed)
				zoom_target = zoom_target.clamp(min_zoom, max_zoom)

# 모든 별자리가 보이는 위치로 이동하는 함수
func move_to_constellation_view():
	target_position = Vector2(-500, 0)  # 모든 별자리가 보이는 위치로 조정
	is_moving_to_target = true
	zoom = Vector2(2, 2)  # 줌 레벨 조정

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# 드래그 시작
				dragging = true
				drag_start_position = event.position
			else:
				# 드래그 종료
				dragging = false
	
	elif event is InputEventMouseMotion and dragging:
		# 마우스 이동 거리만큼 카메라 이동 (반대 방향으로)
		var movement = (event.position - drag_start_position) * -1 / zoom
		
		# 새로운 카메라 위치 계산
		var new_position = position + movement
		
		# 카메라 경계 제한 적용
		new_position.x = clamp(new_position.x, CAMERA_BOUNDS_MIN.x, CAMERA_BOUNDS_MAX.x)
		new_position.y = clamp(new_position.y, CAMERA_BOUNDS_MIN.y, CAMERA_BOUNDS_MAX.y)
		
		# 카메라 위치 업데이트
		position = new_position
		drag_start_position = event.position
