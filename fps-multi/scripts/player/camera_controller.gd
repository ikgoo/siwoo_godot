extends Node3D
class_name CameraController

## 1인칭 시점 카메라 컨트롤러
## 마우스 이동으로 좌우(Yaw) 및 상하(Pitch) 회전 처리

# 마우스 감도
@export var mouse_sensitivity: float = 0.002

# 카메라 상하 회전 제한
@export var min_pitch: float = -89.0
@export var max_pitch: float = 89.0

# Head bob (걷기/달리기 시 카메라 흔들림)
@export var bob_enabled: bool = true
@export var bob_frequency: float = 2.0
@export var bob_amplitude: float = 0.08
var bob_time: float = 0.0

# 카메라 흔들림 (피격, 발사 등)
var trauma: float = 0.0  # 0.0 ~ 1.0
var trauma_decay: float = 1.0  # 초당 감소량
@export var max_shake_offset: float = 0.5
@export var max_shake_rotation: float = 10.0

# 자식 노드 참조
@onready var camera: Camera3D = $Camera3D
@onready var player = get_parent() as PlayerController

# 원래 카메라 위치 저장
var original_camera_position: Vector3

func _ready():
	if camera:
		original_camera_position = camera.position

func _input(event):
	# 멀티플레이어: 로컬 플레이어만 입력 처리
	if player and multiplayer.get_peers().size() > 0 and not player.is_multiplayer_authority():
		return
	
	# 마우스 이동 처리
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# 좌우 회전 (Yaw) - 이 노드를 Y축 기준으로 회전
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		# 상하 회전 (Pitch) - 카메라를 X축 기준으로 회전
		if camera:
			var pitch_change = -event.relative.y * mouse_sensitivity
			var current_pitch = camera.rotation.x
			var new_pitch = clamp(
				current_pitch + pitch_change,
				deg_to_rad(min_pitch),
				deg_to_rad(max_pitch)
			)
			camera.rotation.x = new_pitch

func _process(delta):
	if not camera:
		return
	
	# Head Bob 효과
	if bob_enabled and player and player.is_on_floor() and player.is_moving():
		bob_time += delta * player.velocity.length() * bob_frequency / 5.0
		var bob_offset = Vector3(
			cos(bob_time) * bob_amplitude,
			sin(bob_time * 2.0) * bob_amplitude,
			0
		)
		camera.position = original_camera_position + bob_offset
	else:
		bob_time = 0.0
		camera.position = camera.position.lerp(original_camera_position, delta * 10.0)
	
	# 카메라 흔들림 효과
	if trauma > 0:
		trauma = max(trauma - trauma_decay * delta, 0.0)
		
		# 흔들림 강도 계산 (제곱하여 자연스러운 감소)
		var shake = trauma * trauma
		
		# 랜덤 오프셋 및 회전
		var offset = Vector3(
			randf_range(-max_shake_offset, max_shake_offset) * shake,
			randf_range(-max_shake_offset, max_shake_offset) * shake,
			0
		)
		var rotation_offset = Vector3(
			randf_range(-max_shake_rotation, max_shake_rotation) * shake,
			randf_range(-max_shake_rotation, max_shake_rotation) * shake,
			randf_range(-max_shake_rotation, max_shake_rotation) * shake
		)
		
		camera.position = original_camera_position + offset
		camera.rotation_degrees += rotation_offset * delta

# 카메라 흔들림 추가
# amount: 흔들림 강도 (0.0 ~ 1.0)
func add_trauma(amount: float):
	trauma = min(trauma + amount, 1.0)

# ADS(조준) 시 FOV 변경
# target_fov: 목표 FOV
# duration: 전환 시간
func change_fov(target_fov: float, duration: float = 0.2):
	if camera:
		var tween = create_tween()
		tween.tween_property(camera, "fov", target_fov, duration)

