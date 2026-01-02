extends Sprite2D

@onready var light: PointLight2D = $Light2D

# 빛 흔들림 설정
var flicker_time: float = 0.0
var flicker_speed: float = 1.0  # 흔들림 속도
var base_scale: float = 0.8
var max_scale: float = 1.0

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
