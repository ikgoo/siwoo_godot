extends Camera2D

var min_zoom = Vector2(1, 1)
var max_zoom = Vector2(6, 6)
var zoom_speed = 0.15
var zoom_target = Vector2(1, 1)
var zoom_smoothness = 15.0

# 카메라 이동 관련 변수
var move_speed = 300  # 카메라 이동 속도
const MIN_POSITION = Vector2(-820, -820)  # 최소 위치
const MAX_POSITION = Vector2(800, 800)    # 최대 위치

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_target = zoom_target + Vector2(zoom_speed, zoom_speed)
			zoom_target = zoom_target.clamp(min_zoom, max_zoom)
			Gamemanger.camera_zoom = zoom_target
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_target = zoom_target - Vector2(zoom_speed, zoom_speed)
			zoom_target = zoom_target.clamp(min_zoom, max_zoom)
			Gamemanger.camera_zoom = zoom_target

func _process(delta):
	# 부드러운 줌 효과
	zoom = zoom.lerp(zoom_target, delta * zoom_smoothness)
	
	# WASD 이동 처리
	var input_dir = Vector2.ZERO
	
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_dir.y -= 1000
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_dir.y += 1000
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_dir.x -= 1000
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_dir.x += 1000
	
	# 카메라 위치 업데이트
	var new_position = position + input_dir * delta
	
	# 위치 제한 적용
	new_position.x = clamp(new_position.x, MIN_POSITION.x, MAX_POSITION.x)
	new_position.y = clamp(new_position.y, MIN_POSITION.y, MAX_POSITION.y)
	
	position = new_position
