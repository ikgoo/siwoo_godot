extends Node2D
@onready var node_2d = $Node2D
@onready var node_2d_2 = $Node2D2
@onready var bottle_of_water = $bottle_of_water
@onready var node_2d_3 = $Node2D3
@onready var yyang = $yyang
@onready var big_cow = $big_cow
@onready var end_message = $CanvasLayer/Control/Label4  # "모든별자리를 해금했습니다!" 메시지
@onready var continue_button = $CanvasLayer/Control/Button6  # 계속하기 버튼
@onready var main_button = $CanvasLayer/Control/outing  # 메인으로 가기 버튼
var end = false
@onready var control = $CanvasLayer/Control
var go = true
@onready var timer_2 = $Timer2
@onready var audio_stream_player_2d_2 = $AudioStreamPlayer2D2
var spawn_timer: float = 0.0
const SPAWN_INTERVAL: float = 5.0
const MIN_POSITION = Vector2(-3000, -2000)  
const MAX_POSITION = Vector2(3000, 2000)    
const MAX_STARS = 500  # 최대 별 개수
@onready var timer = $Timer
@onready var camera = $Camera2D
@onready var canvas_layer = $CanvasLayer
@onready var audio_stream_player_2d = $AudioStreamPlayer2D
var ok = false
var stardust: int = 0
var star_scene = preload("res://star.tscn")  # Star 씬을 미리 로드
var target_camera_position = Vector2.ZERO  # 카메라가 이동할 목표 위치
var is_paused = false  # 일시정지 상태를 추적하는 변수 추가
@onready var audio_stream_player = $AudioStreamPlayer


var cursor = 0


func spawn_star(type: int):
	if go:
		if Gamemaneger.stars.size() >= MAX_STARS:
			return
		
		# 별자리 완성 여부에 따른 생성 조건 체크
		match type:
			0:  # 기본 별 - 항상 생성
				pass
			1:  # 작은곰자리 완성 시 생성되는 별
				if node_2d.visible:  # 작은곰자리
					pass
				else:
					return
			2:  # 천칭자리 완성 시 생성되는 별
				if node_2d_2.visible:  # 천칭자리
					pass
				else:
					return
			3:  # 게자리 완성 시 생성되는 별
				if node_2d_3.visible:  # 게자리
					pass
				else:
					return
			4:  # 물병자리 완성 시 생성되는 별
				if bottle_of_water.visible:  # 물병자리
					pass
				else:
					return
			5:  # 양자리 완성 시 생성되는 별
				if yyang.visible:  # 양자리
					pass
				else:
					return
			6:  # 황소자리 완성 시 생성되는 별
				if big_cow.visible:  # 황소자리
					pass
				else:
					return
		
		var star_instance = star_scene.instantiate()
		star_instance.set_star_type(type)
		
		# 랜덤 위치 설정
		var random_x = randf_range(MIN_POSITION.x, MAX_POSITION.x)
		var random_y = randf_range(MIN_POSITION.y, MAX_POSITION.y)
		star_instance.position = Vector2(random_x, random_y)
		
		add_child(star_instance)
		star_instance.star_clicked.connect(_on_star_clicked)
		Gamemaneger.add_star(star_instance)

func _on_timer_timeout():
	if go:
		spawn_star(0)
		spawn_star(0)
		spawn_star(0)
		spawn_star(0)
		spawn_star(0)



func _on_star_clicked():
	if go:
		Gamemaneger.stardust += 5

func _ready():
	var cursor_image1 = preload("res://New-Piskel-(3).png")
	Input.set_custom_mouse_cursor(cursor_image1, Input.CURSOR_ARROW, Vector2(16, 16))
	if go:
		# 카메라 시야 제한을 훨씬 더 크게 설정
		camera.limit_left = -5000    # 더 왼쪽으로 확장
		camera.limit_right = 6000    # 더 오른쪽으로 확장
		camera.limit_top = -4000     # 더 위로 확장
		camera.limit_bottom = 4000   # 더 아래로 확장
		# 처음에는 엔딩 관련 UI 숨기기
		end_message.visible = false
		continue_button.visible = false
		main_button.visible = false

func _process(delta):
	if go:
		if end:
			# UI 관련 코드 수정
			control.visible = true  # 기본 UI는 보이게 유지
			end_message.visible = true  # 엔딩 메시지 표시
			continue_button.visible = true  # 계속하기 버튼 표시
			main_button.visible = true  # 메인으로 가기 버튼 표시
			if not ok:
				ok = true
				end_message.text = "모든 별자리를 해금했습니다!"
			
			# 카메라 효과 제거
			# get_tree().root.content_scale_factor = lerpf(get_tree().root.content_scale_factor, 0.5, 2 * delta)
			Gamemaneger.cam_go = false
		else:
			# 일반 상태
			control.visible = true  # 기본 UI 표시
			end_message.visible = false  # 엔딩 메시지 숨기기
			continue_button.visible = false  # 계속하기 버튼 숨기기
			main_button.visible = false  # 메인으로 가기 버튼 숨기기
		

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:  # ESC 키를 눌렀을 때
			is_paused = !is_paused  # 일시정지 상태 토글
			
			if is_paused:  # 일시정지 활성화
				# 일시정지 상태로 전환
				go = false
				Gamemaneger.cam_go = false
				
				# UI 표시
				control.visible = true
				if end:  # 모든 별자리를 완성했을 때
					end_message.text = "모든 별자리를 해금했습니다!"
				else:  # 일반 일시정지
					end_message.text = "일시정지"
				end_message.visible = true
				continue_button.visible = true
				main_button.visible = true
			else:  # 일시정지 비활성화
				# 게임 재개
				go = true
				Gamemaneger.cam_go = true
				
				# UI 숨기기
				end_message.visible = false
				continue_button.visible = false
				main_button.visible = false

func _on_button_6_button_down():  # 계속하기 버튼
	is_paused = false  # 일시정지 상태 해제
	# 게임 재개
	go = true
	Gamemaneger.cam_go = true
	
	# UI 숨기기
	end_message.visible = false
	continue_button.visible = false
	main_button.visible = false


func _on_timer_2_timeout():
	Gamemaneger.star_get = 0

func tting(now, full):
	# now: 현재까지 클릭한 네임드 별의 수
	# full: 전체 네임드 별의 수
	# 시작 피치: 1.0, 끝 피치: 1.5
	var start_pitch = 1.0
	var end_pitch = 1.5
	
	# 진행률에 따라 피치 계산 (선형 보간)
	var progress = float(now - 1) / float(full)
	var current_pitch = start_pitch + (end_pitch - start_pitch) * progress
	
	audio_stream_player_2d_2.pitch_scale = current_pitch
	audio_stream_player_2d_2.play()


func _on_audio_stream_player_finished():
	audio_stream_player.play()


func _on_cursor_timer_timeout():
	if cursor == 0:
		var cursor_image1 = preload("res://New-Piskel-(3) (1).png")
		Input.set_custom_mouse_cursor(cursor_image1, Input.CURSOR_ARROW, Vector2(16, 16))
		cursor = 1
	elif cursor == 1:
		var cursor_image1 = preload("res://New-Piskel-(3).png")
		Input.set_custom_mouse_cursor(cursor_image1, Input.CURSOR_ARROW, Vector2(16, 16))
		cursor = 0
