extends Camera3D

## 줌 설정
@export_group("줌 설정")
@export var zoom_speed: float = 0.5  ## 줌 속도
@export var zoom_min: float = 5.0    ## 최소 거리 (가장 가까이)
@export var zoom_max: float = 30.0   ## 최대 거리 (가장 멀리)
@export var zoom_smooth: bool = true  ## 부드러운 줌 활성화
@export var zoom_smooth_speed: float = 10.0  ## 부드러운 줌 속도

## 개발자 모드 설정
@export_group("개발자 모드")
@export var dev_zoom_max: float = 200.0  ## 개발자 모드 최대 거리
@export var dev_zoom_speed: float = 5.0  ## 개발자 모드 줌 속도 (10배 빠름)

## 현재 줌 거리
var current_zoom: float = 15.0
## 목표 줌 거리 (부드러운 줌용)
var target_zoom: float = 15.0

## 개발자 모드 활성화 여부
var developer_mode: bool = false

func _ready():
	# 초기 줌 거리 설정 (현재 카메라 위치 기준)
	current_zoom = position.length()
	target_zoom = current_zoom

func _input(event):
	# K키로 개발자 모드 토글
	if event is InputEventKey and event.pressed and event.keycode == KEY_K:
		developer_mode = !developer_mode
		
		# 전역 신호 발송
		if developer_mode:
			print("🔧 [개발자 모드] 활성화 - 최대 줌: %.1f, Fog: OFF" % dev_zoom_max)
			get_tree().call_group("main", "set_developer_mode", true)
		else:
			print("🔧 [개발자 모드] 비활성화 - 최대 줌: %.1f, Fog: ON" % zoom_max)
			get_tree().call_group("main", "set_developer_mode", false)
			# 일반 모드로 돌아올 때 줌이 최대값을 초과하면 조정
			if target_zoom > zoom_max:
				target_zoom = zoom_max
	
	# 마우스 휠 입력 처리
	if event is InputEventMouseButton:
		# 개발자 모드에 따라 줌 속도와 최대값 결정
		var current_zoom_speed = dev_zoom_speed if developer_mode else zoom_speed
		var current_zoom_max = dev_zoom_max if developer_mode else zoom_max
		
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			# 휠 위로 = 줌 인 (카메라가 앞으로)
			target_zoom -= current_zoom_speed
			target_zoom = max(target_zoom, zoom_min)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			# 휠 아래로 = 줌 아웃 (카메라가 뒤로)
			target_zoom += current_zoom_speed
			target_zoom = min(target_zoom, current_zoom_max)

func _process(delta):
	# 부드러운 줌 처리
	if zoom_smooth:
		current_zoom = lerp(current_zoom, target_zoom, zoom_smooth_speed * delta)
	else:
		current_zoom = target_zoom
	
	# 카메라 위치 업데이트 (현재 방향 유지하면서 거리만 조정)
	var direction = position.normalized()
	position = direction * current_zoom
