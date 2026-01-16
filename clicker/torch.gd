extends AnimatedSprite2D

## 횃불 타입 (벽에 붙은 횃불 / 반대방향 벽 횃불 / 서있는 횃불)
enum TorchType { WALL, WALL_REVERSE, STAND }

@export var torch_type: TorchType = TorchType.WALL

@onready var light: PointLight2D = $Light2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# 빛 흔들림 설정
var flicker_time: float = 0.0
var flicker_speed: float = 1.0  # 흔들림 속도
var base_scale: float = 0.8
var max_scale: float = 1.0

func _ready():
	# 횃불 타입에 따라 애니메이션 재생
	if animation_player:
		match torch_type:
			TorchType.WALL:
				animation_player.play("wall_fire")
			TorchType.WALL_REVERSE:
				animation_player.play("reverse_wall_fire")
			TorchType.STAND:
				animation_player.play("stand_fire")

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
