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

func _ready():
	# AUTO 모드면 레이캐스트로 벽 방향 감지
	if torch_type == TorchType.AUTO:
		# 레이캐스트 강제 업데이트 (첫 프레임에 충돌 감지)
		raycast_left.force_raycast_update()
		raycast_right.force_raycast_update()
		
		var left_wall = raycast_left.is_colliding()
		var right_wall = raycast_right.is_colliding()
		
		# 왼쪽 벽에 붙어있으면 wall_fire, 오른쪽 벽에 붙어있으면 reverse_wall_fire
		if left_wall and not right_wall:
			torch_type = TorchType.WALL
		elif right_wall and not left_wall:
			torch_type = TorchType.WALL_REVERSE
		else:
			torch_type = TorchType.STAND
	
	# 횃불 타입에 따라 애니메이션 재생
	if animation_player:
		match torch_type:
			TorchType.WALL:
				animation_player.play("wall_fire")
			TorchType.WALL_REVERSE:
				animation_player.play("reverse_wall_fire")
			TorchType.STAND:
				animation_player.play("stand_fire")
	
	# y좌표가 높을수록(화면 아래) z_index가 높게 설정
	z_index = int(global_position.y)
	
	# Sprite2D(횃불 받침대)가 항상 AnimatedSprite2D(불꽃) 위에 렌더링되도록 설정
	if torch_sprite:
		torch_sprite.z_as_relative = true  # 부모 기준 상대값 사용
		torch_sprite.z_index = 1  # 부모(self)보다 항상 위에 표시

func _process(delta):
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
