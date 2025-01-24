extends Camera3D

# 기본 설정
@export var base_offset : Vector3 = Vector3(0, 0, 0)  # 기본 카메라 오프셋
@export var constant_shake_amount : float = 0.01        # 일반 비행중 흔들림 강도
@export var impact_shake_amount : float = 0.0          # 충격시 추가 흔들림 강도
@export var shake_decay : float = 1.0                  # 충격 흔들림 감소 속도
@export var noise_speed : float = 50.0                 # 흔들림 속도

# 내부 변수
var noise : FastNoiseLite
var noise_i : float = 0.0
var base_rotation : Vector3

func _ready():
	# 노이즈 생성기 설정
	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.8

	# 초기 설정
	base_rotation = rotation_degrees
	h_offset = base_offset.x
	v_offset = base_offset.y
	
	# 기본 오프셋 설정
	set_base_offset(base_offset)

func _process(delta):
	noise_i += delta * noise_speed
	
	# 전체 흔들림 강도 계산 (상수 흔들림 + 충격 흔들림)
	var total_shake = constant_shake_amount + impact_shake_amount
	
	# 충격 흔들림 감소
	if impact_shake_amount > 0:
		impact_shake_amount = move_toward(impact_shake_amount, 0, shake_decay * delta)
	
	# 오프셋 흔들림 적용
	h_offset = base_offset.x + noise.get_noise_2d(noise_i, 0.0) * total_shake
	v_offset = base_offset.y + noise.get_noise_2d(noise_i, 1.0) * total_shake
	
	# 회전 흔들림
	rotation_degrees = base_rotation + Vector3(
		noise.get_noise_2d(noise_i, 3.0) * total_shake * 2.0,
		noise.get_noise_2d(noise_i, 4.0) * total_shake * 2.0,
		noise.get_noise_2d(noise_i, 5.0) * total_shake * 2.0
	)

# 충격 효과 추가 함수
func add_impact_shake(amount: float = 1.0):
	impact_shake_amount = amount

# 비행중 흔들림 강도 조절 함수
func set_constant_shake(amount: float):
	constant_shake_amount = amount

# 기본 오프셋 설정 함수
func set_base_offset(new_offset: Vector3):
	base_offset = new_offset
	h_offset = new_offset.x
	v_offset = new_offset.y
