extends AnimatedSprite2D

## 횃불 타입 (벽에 붙은 횃불 / 반대방향 벽 횃불 / 서있는 횃불)
enum TorchType { WALL, WALL_REVERSE, STAND, AUTO }

@export var torch_type: TorchType = TorchType.AUTO

@onready var light: PointLight2D = $Light2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var raycast_left: RayCast2D = $RayCastLeft
@onready var raycast_right: RayCast2D = $RayCastRight
@onready var torch_sprite: Sprite2D = $Sprite2D

# 빛 흔들림 설정
var flicker_time: float = 0.0
var flicker_speed: float = 1.0  # 흔들림 속도
var base_scale: float = 0.8
var max_scale: float = 0.9

# 벽 상태 체크 타이머 (매 프레임 체크하면 비효율적)
var wall_check_timer: float = 0.0
var wall_check_interval: float = 0.3  # 0.3초마다 벽 상태 확인

func _ready():
	# torches 그룹에 추가 (중복 설치 체크용)
	add_to_group("torches")
	
	# 초기 벽 상태 감지 및 타입 설정
	detect_and_apply_torch_type()
	
	# Sprite2D(횃불 받침대)가 항상 AnimatedSprite2D(불꽃) 위에 렌더링되도록 설정
	if torch_sprite:
		torch_sprite.z_as_relative = true  # 부모 기준 상대값 사용
		torch_sprite.z_index = 1  # 부모(self)보다 항상 위에 표시

## 레이캐스트로 벽 방향을 감지하고 횃불 타입을 결정합니다.
## @returns TorchType 감지된 횃불 타입
func detect_wall_type() -> TorchType:
	if not raycast_left or not raycast_right:
		return TorchType.STAND
	
	# 레이캐스트 강제 업데이트
	raycast_left.force_raycast_update()
	raycast_right.force_raycast_update()
	
	var left_wall = raycast_left.is_colliding()
	var right_wall = raycast_right.is_colliding()
	
	# 왼쪽 벽에 붙어있으면 reverse_wall_fire (횃불이 오른쪽 향함)
	# 오른쪽 벽에 붙어있으면 wall_fire (횃불이 왼쪽 향함)
	if left_wall and not right_wall:
		return TorchType.WALL_REVERSE
	elif right_wall and not left_wall:
		return TorchType.WALL
	else:
		return TorchType.STAND

## 벽 상태를 감지하고 횃불 타입 및 애니메이션을 적용합니다.
func detect_and_apply_torch_type():
	var new_type = detect_wall_type()
	
	# 타입이 변경되었을 때만 애니메이션 업데이트
	if new_type != torch_type or torch_type == TorchType.AUTO:
		torch_type = new_type
		apply_animation()

## 현재 횃불 타입에 맞는 애니메이션을 재생합니다.
func apply_animation():
	if not animation_player:
		return
	
	match torch_type:
		TorchType.WALL:
			animation_player.play("wall_fire")
		TorchType.WALL_REVERSE:
			animation_player.play("reverse_wall_fire")
		TorchType.STAND:
			animation_player.play("stand_fire")

func _process(delta):
	# 빛 흔들림 효과
	update_light_flicker(delta)
	
	# 주기적으로 벽 상태 확인 (벽이 파괴되었는지 체크)
	wall_check_timer += delta
	if wall_check_timer >= wall_check_interval:
		wall_check_timer = 0.0
		check_wall_state()

## 빛 흔들림 효과를 업데이트합니다.
func update_light_flicker(delta: float):
	if not light:
		return
	
	flicker_time += delta * flicker_speed
	
	# 여러 sin 파형을 합쳐서 자연스러운 흔들림 생성
	var flicker = sin(flicker_time) * 0.5
	flicker += sin(flicker_time * 1.7) * 0.3
	flicker += sin(flicker_time * 2.3) * 0.2
	
	# -1 ~ 1 범위를 0 ~ 1로 정규화
	flicker = (flicker + 1.0) / 2.0
	
	# 0.8 ~ 1.0 사이로 스케일 적용
	light.texture_scale = base_scale + flicker * (max_scale - base_scale)

## 벽 상태를 확인하고 필요 시 횃불 타입을 업데이트합니다.
## 붙어있던 벽이 파괴되면 다른 벽에 붙거나 stand 상태로 전환됩니다.
func check_wall_state():
	var new_type = detect_wall_type()
	
	# 현재 타입과 다르면 업데이트
	if new_type != torch_type:
		torch_type = new_type
		apply_animation()
