extends CharacterBody3D
class_name PlayerController

## 플레이어의 이동, 점프, 달리기를 관리하는 컨트롤러
## WASD로 이동, Space로 점프, Shift로 달리기

# 시그널 정의
signal player_damaged(damage: float)
signal player_died()

# 이동 관련 상수
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.5
const CROUCH_SPEED = 2.5

# 현재 속도
var current_speed = WALK_SPEED

# HP 시스템
@export var max_hp: float = 100.0
var current_hp: float = 100.0

# 낙하 데미지
var last_y_velocity: float = 0.0
const FALL_DAMAGE_THRESHOLD = -15.0  # 이 속도 이하로 떨어지면 데미지
const FALL_DAMAGE_MULTIPLIER = 2.0

# 중력
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# 자식 노드 참조
@onready var camera_controller = $CameraController
@onready var weapon_manager = $CameraController/Camera3D/WeaponManager

func _ready():
	current_hp = max_hp
	
	# 멀티플레이어: 로컬 플레이어만 마우스 캡처
	if multiplayer.get_peers().size() == 0 or is_multiplayer_authority():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# 멀티플레이어: 로컬 플레이어만 입력 처리
	if multiplayer.get_peers().size() > 0 and not is_multiplayer_authority():
		return
	
	# ESC 키로 마우스 해제
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	# 멀티플레이어: 로컬 플레이어만 입력 처리
	if multiplayer.get_peers().size() > 0 and not is_multiplayer_authority():
		# 원격 플레이어는 중력만 적용
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return
	
	# 낙하 전 속도 저장 (낙하 데미지 계산용)
	var was_on_floor = is_on_floor()
	last_y_velocity = velocity.y
	
	# 중력 적용
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		# 착지 시 낙하 데미지 체크 (땅에 막 착지했을 때만)
		if not was_on_floor and last_y_velocity < FALL_DAMAGE_THRESHOLD:
			var fall_damage = abs(last_y_velocity - FALL_DAMAGE_THRESHOLD) * FALL_DAMAGE_MULTIPLIER
			take_damage(fall_damage)
			print("낙하 데미지: %.1f" % fall_damage)
	
	# 점프 처리
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# 달리기 처리
	if Input.is_action_pressed("sprint") and is_on_floor():
		current_speed = SPRINT_SPEED
	else:
		current_speed = WALK_SPEED
	
	# 이동 입력 받기
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	# 카메라 방향 기준으로 이동 방향 계산
	var direction = Vector3.ZERO
	if camera_controller:
		direction = (camera_controller.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# 이동 적용
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	move_and_slide()

# 데미지를 받는 함수 (레이캐스트에서 직접 호출됨)
# damage: 받을 데미지량
# _hit_position: 피격 위치 (선택, 미사용)
func take_damage(damage: float, _hit_position: Vector3 = Vector3.ZERO):
	print("플레이어 %s가 %.1f 데미지 받음" % [name, damage])
	
	# 멀티플레이어: 서버에서만 HP 관리
	if multiplayer.get_peers().size() > 0:
		if multiplayer.is_server():
			_apply_damage.rpc(damage)
		else:
			# 클라이언트는 서버에 데미지 요청
			_request_damage.rpc_id(1, damage)
	else:
		# 싱글플레이어
		_apply_damage(damage)

# 실제 데미지 적용
@rpc("authority", "call_local", "reliable")
func _apply_damage(damage: float):
	current_hp -= damage
	current_hp = clamp(current_hp, 0, max_hp)
	player_damaged.emit(damage)
	
	if current_hp <= 0:
		die()

# 클라이언트가 서버에 데미지 요청
@rpc("any_peer", "reliable")
func _request_damage(damage: float):
	if multiplayer.is_server():
		_apply_damage.rpc(damage)

# 플레이어 사망 처리
func die():
	if current_hp > 0:
		return  # 이미 죽지 않았으면 무시
	
	print("플레이어 사망!")
	player_died.emit()
	
	# 멀티플레이어에서는 리스폰
	if multiplayer.get_peers().size() > 0:
		await get_tree().create_timer(3.0).timeout
		current_hp = max_hp
		position.y = 2.0  # 위로 리스폰
		print("플레이어 리스폰!")
	print("플레이어 사망!")

# HP 회복 함수
# amount: 회복할 HP량
func heal(amount: float):
	current_hp += amount
	current_hp = clamp(current_hp, 0, max_hp)

# 현재 이동 중인지 확인
# 반환: 이동 중이면 true
func is_moving() -> bool:
	return velocity.length() > 0.1

