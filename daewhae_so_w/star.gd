extends Node2D
@onready var audio_stream_player_2d = $AudioStreamPlayer2D

var camera: Camera2D
var initial_scale: Vector2
var is_clicked = false
var star_type: int = 0  # 별의 타입 (0: 기본, 1~6: 각 별자리)
signal star_clicked
@onready var animation_player = $AnimationPlayer
var is_it_done = false
# 별 타입별 특성
const STAR_PROPERTIES = {
	0: {"scale": 0.5, "color": Color(1, 1, 1, 1), "collect_amount": 5},  # 기본 별 - 흰색
	1: {"scale": 0.7, "color": Color(0, 1, 0, 1), "collect_amount": 10},  # 작은곰자리 - 초록색
	2: {"scale": 0.8, "color": Color(1, 0.8, 0, 1), "collect_amount": 15},  # 천칭자리 - 금색
	3: {"scale": 0.9, "color": Color(1, 0, 0, 1), "collect_amount": 20},  # 게자리 - 빨간색
	4: {"scale": 1.0, "color": Color(0, 0.5, 1, 1), "collect_amount": 25},  # 물병자리 - 파란색
	5: {"scale": 1.1, "color": Color(1, 0, 1, 1), "collect_amount": 30},  # 양자리 - 자주색
	6: {"scale": 1.2, "color": Color(1, 0.5, 0, 1), "collect_amount": 35}   # 황소자리 - 주황색
}

func _ready():
	animation_player.play("idle")
	# 초기 스케일과 색상 설정
	var props = STAR_PROPERTIES[star_type]
	# 기본 스케일에 랜덤 변화 추가 (0.8 ~ 1.2 배)
	var random_scale_multiplier = randf_range(0.8, 1.2)
	initial_scale = scale * props["scale"] * random_scale_multiplier
	modulate = props["color"]
	
	camera = get_viewport().get_camera_2d()
	add_to_group("stars")

func _process(delta) -> void:
	if not is_it_done:
			is_it_done = true
			var props = STAR_PROPERTIES[star_type]
			modulate = props["color"]
	if camera:
		if not camera == null:
			var zoom_factor = camera.zoom.x  # 현재 카메라 줌 레벨
			# 줌 레벨에 따라 스케일을 부드럽게 조절 (루트 사용으로 증가)
			var new_scale = initial_scale * (1.0 + sqrt(zoom_factor) * 2)
			scale = scale.lerp(new_scale, 0.1)

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var distance = get_local_mouse_position().length()
		if distance < 10:  # 클릭 감지 거리

				collect()
				
func set_star_type(type: int):
	star_type = type
	if is_inside_tree():  # 노드가 씬 트리에 추가된 후에만 실행
		var props = STAR_PROPERTIES[type]
		# 기본 스케일에 랜덤 변화 추가 (0.8 ~ 1.2 배)
		var random_scale_multiplier = randf_range(0.8, 1.2)
		initial_scale = scale * props["scale"] * random_scale_multiplier
		modulate = props["color"]  # 색상 즉시 설정
	if type == 2:
		pass

func collect():
	if not is_clicked:
		is_clicked = true
		Gamemaneger.add_star_get()
		if Gamemaneger.star_get >= 20:
			Gamemaneger.star_get = 0
		
		var pitch_scale = 1.0 + (Gamemaneger.star_get * 0.01)
		var pitch_scalec = min(pitch_scale, 1.2)
		
		audio_stream_player_2d.pitch_scale = pitch_scalec
		audio_stream_player_2d.play()
		
		# 스타더스트 획득량 계산
		Gamemaneger.stars.erase(self)
		var base_amount = STAR_PROPERTIES[star_type]["collect_amount"]
		Gamemaneger.stardust += base_amount
		
		emit_signal("star_clicked")
		animation_player.play("get")

# 볼륨 설정 메서드 추가
func set_volume(value):
	audio_stream_player_2d.volume_db = linear_to_db(value)
