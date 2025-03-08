extends Node2D

@onready var animation_player = $AnimationPlayer
@onready var s2_line = $s2
@onready var s3_line = $s3
@onready var s4_line = $s4
@onready var s5_line = $s5
@onready var s6_line = $s6
@onready var audio_stream_player_2d = $AudioStreamPlayer2D  # 오디오 플레이어 참조 추가

var star_count = 0
var clicked_s_stars = []  # S 별자리의 클릭된 별들
var s_connections = {
	"s2": ["1", "2"],
	"s3": ["2", "3"],
	"s4": ["3", "4"],
	"s5": ["4", "5"],
	"s6": ["5", "6"]
}

var s_completed = false
var base_pitch = 1.0  # 기본 피치 값

func _ready():
	animation_player.play("title")
	# 게임 상태 초기화
	Main.visible = false
	Main.control.visible = false
	Main.go = false
	Main.camera.enabled = false


	# 별자리 관련 변수 초기화
	clicked_s_stars.clear()  # 클릭한 별 목록 초기화
	s_completed = false  # 별자리 완성 상태 초기화
	# 모든 선을 처음에는 숨김
	s2_line.visible = false
	s3_line.visible = false
	s4_line.visible = false
	s5_line.visible = false
	s6_line.visible = false
	
	# S 별자리의 별들 초기화
	for i in range(1, 7):
		var star = get_node(str(i))
		if star:
			star.modulate = Color(1, 1, 1, 1)  # 기본 색상으로 설정

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 전역 마우스 위치에서 노드의 전역 위치를 빼서 로컬 좌표로 변환
		var click_pos = get_global_mouse_position() - global_position
		
		# 가장 가까운 별 찾기
		var closest_star = null
		var closest_distance = INF
		
		# S 별자리의 별들 체크
		for i in range(1, 7):  # 1부터 6까지의 별
			var star = get_node(str(i))
			if star and not clicked_s_stars.has(str(i)):  # 아직 클릭하지 않은 별만 체크
				var distance = click_pos.distance_to(star.position)
				if distance < 30 and distance < closest_distance:  # 클릭 감지 거리를 30으로 줄임
					closest_distance = distance
					closest_star = star
		
		# 가장 가까운 별 처리
		if closest_star:
			var star_number = closest_star.name
			clicked_s_stars.append(star_number)
			closest_star.modulate = Color(1, 1, 4, 1)  # 클릭한 별을 빛나게 함
			
			# 별을 클릭할 때마다 소리 재생 및 피치 증가
			audio_stream_player_2d.pitch_scale = base_pitch
			audio_stream_player_2d.play()
			base_pitch += 0.1  # 피치 증가
			
			check_connections()  # 선 연결 체크
			
			if clicked_s_stars.size() >= 6:  # 모든 별을 클릭했을 때
				await get_tree().create_timer(1.0).timeout  # 1초 대기
				Main.go = true  # 게임 활성화
				Main.camera.enabled = true  # 카메라 활성화

func check_connections():
	# 모든 선이 보이는지 확인
	var all_lines_visible = true
	for line_name in s_connections:
		var stars = s_connections[line_name]
		var all_clicked = true
		
		for star in stars:
			if not clicked_s_stars.has(star):
				all_clicked = false
				all_lines_visible = false
				break
		
		# 해당 선의 별들이 모두 클릭되었으면 선을 보이게 함
		match line_name:
			"s2": s2_line.visible = all_clicked
			"s3": s3_line.visible = all_clicked
			"s4": s4_line.visible = all_clicked
			"s5": s5_line.visible = all_clicked
			"s6": s6_line.visible = all_clicked
	
	# 모든 선이 보이면 애니메이션 재생 후 씬 전환
	if all_lines_visible and not s_completed:
		s_completed = true
		animation_player.play("new_animation")
		# 애니메이션이 끝나면 씬 전환
		await animation_player.animation_finished
		Main.go = true
		get_tree().change_scene_to_file("res://real_main.tscn")


func _on_setting_button_down():
	get_tree().change_scene_to_file("res://setting.tscn")


func _on_button_button_down():
	get_tree().quit()
