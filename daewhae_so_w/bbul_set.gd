extends Node2D
@onready var label = $Label
@onready var control = $".."
@onready var animation_player = $AnimationPlayer
@onready var namec = $"../name"

var current_constellation = 0  # 현재 보여지는 별자리 인덱스
var constellations = []  # 별자리 노드들을 저장할 배열
var completed_constellations = []  # 완성된 별자리 저장

var clicked_named_stars = []
const CLICK_DISTANCE = 10.0  # 클릭 감지 거리
@onready var for_see = $for_see
@onready var for_see_2 = $for_see2
@onready var for_see_3 = $for_see3
@onready var for_see_4 = $for_see4
@onready var for_see_5 = $for_see5
@onready var for_see_6 = $for_see6

# 별자리 정보를 딕셔너리로 저장
var constellation_info = {
	0: {"name": "작은곰자리", "cost": 50},
	1: {"name": "천칭자리", "cost": 100},
	2: {"name": "게자리", "cost": 1000},
	3: {"name": "물병자리", "cost": 2500},
	4: {"name": "양자리", "cost": 5000},
	5: {"name": "황소자리", "cost": 10000}
}

func _ready():
	all_see_off()
	# 별자리 순서 정의 수정
	constellations = [
		$Node2D3,  # 작은곰자리
		$Node2D2,  # 천칭자리
		$Node2D4,  # 게자리
		$Node2D5,  # 물병자리
		$Node2D6,  # 양자리
		$Node2D7   # 황소자리
	]
	
	# 각 별자리의 named_star_clicked 시그널 연결
	for constellation in constellations:
		constellation.connect("named_star_clicked", _on_named_star_clicked)
	
	# 완성된 별자리 배열 초기화
	completed_constellations = [false, false, false, false, false, false]
	
	# 처음에는 천칭자리만 보이게 설정
	show_constellation(0)

func _process(_delta):
	# 현재 보이는 별자리의 남은 별 수 업데이트
	if current_constellation >= 0 and current_constellation < constellations.size():
		var constellation = constellations[current_constellation]
		var total_named_stars = 0
		
		# 네임드 별들만 카운트
		for child in constellation.get_children():
			if child is Sprite2D and child.name.is_valid_int():
				total_named_stars += 1
		
		var clicked_stars = constellation.clicked_named_stars.size()
		var remaining = total_named_stars - clicked_stars
		label.text = "남은 별: %d" % remaining
		

		
		# 스타더스트가 충분한지 표시
		var required_cost = constellation_info[current_constellation]["cost"]
		if Gamemaneger.stardust >= required_cost:
			$Label2.modulate = Color(1, 1, 20, 1)  # 충분하면 밝게
		else:
			$Label2.modulate = Color(1, 0, 0, 1)   # 부족하면 빨간색으로
		
		# 모든 별을 찾았는지 확인
		if clicked_stars == total_named_stars and not completed_constellations[current_constellation]:
			print("별자리 완성!")  # 디버그 출력
			completed_constellations[current_constellation] = true  # 완성 표시
			
			# 모든 별자리가 완성되었는지 확인
			var all_completed = true
			for constc in completed_constellations:
				if not constc:
					all_completed = false
					break
			
			if all_completed:
				Main.end = true
			
			match current_constellation:
				0:  # 작은곰자리
					if not Main.node_2d.visible:
						Main.node_2d.visible = true
						Main.node_2d.animation_player.play("new_animation")
						var tween = create_tween()
						tween.set_trans(Tween.TRANS_CUBIC)
						tween.set_ease(Tween.EASE_IN_OUT)
						Gamemaneger.cam_go = false
						tween.tween_property(Main.camera, "position", Main.node_2d.position, 1.0)
						tween.finished.connect(func(): Gamemaneger.cam_go = true)
						animation_player.play("out")
						control.animation_player.play("naga")
						control.bb_up = false
						namec.text = "작은 곰 자리"
				1:  # 천칭자리
					if not Main.node_2d_2.visible:
						Main.node_2d_2.visible = true
						Main.node_2d_2.animation_player.play("new_animation")
						var tween = create_tween()
						tween.set_trans(Tween.TRANS_CUBIC)
						tween.set_ease(Tween.EASE_IN_OUT)
						Gamemaneger.cam_go = false
						tween.tween_property(Main.camera, "position", Main.node_2d_2.position, 1.0)
						namec.text = "천칭 자리"
						tween.finished.connect(func(): 
							Gamemaneger.cam_go = true
						)
						animation_player.play("out")
						control.animation_player.play("naga")
						control.bb_up = false
				2:  # 게자리
					if not Main.node_2d_3.visible:
						Main.node_2d_3.visible = true
						Main.node_2d_3.animation_player.play("new_animation")
						var tween = create_tween()
						tween.set_trans(Tween.TRANS_CUBIC)
						tween.set_ease(Tween.EASE_IN_OUT)
						Gamemaneger.cam_go = false
						tween.tween_property(Main.camera, "position", Main.node_2d_3.position, 1.0)
						tween.finished.connect(func(): Gamemaneger.cam_go = true)
						animation_player.play("out")
						control.animation_player.play("naga")
						control.bb_up = false
						namec.text = "게 자리"
				3:  # 물병자리
					if not Main.bottle_of_water.visible:
						Main.bottle_of_water.visible = true
						Main.bottle_of_water.animation_player.play("new_animation")
						var tween = create_tween()
						tween.set_trans(Tween.TRANS_CUBIC)
						tween.set_ease(Tween.EASE_IN_OUT)
						Gamemaneger.cam_go = false
						tween.tween_property(Main.camera, "position", Main.bottle_of_water.position, 1.0)
						tween.finished.connect(func(): Gamemaneger.cam_go = true)
						animation_player.play("out")
						control.animation_player.play("naga")
						control.bb_up = false
						namec.text = "물병자리"
				4:  # 양자리
					if not Main.yyang.visible:
						Main.yyang.visible = true
						Main.yyang.animation_player.play("new_animation")
						var tween = create_tween()
						tween.set_trans(Tween.TRANS_CUBIC)
						tween.set_ease(Tween.EASE_IN_OUT)
						Gamemaneger.cam_go = false
						tween.tween_property(Main.camera, "position", Main.yyang.position, 1.0)
						tween.finished.connect(func(): Gamemaneger.cam_go = true)
						animation_player.play("out")
						control.animation_player.play("naga")
						control.bb_up = false
						namec.text = "양 자리"
				5:  # 황소자리
					if not Main.big_cow.visible:
						Main.big_cow.visible = true
						Main.big_cow.animation_player.play("new_animation")
						var tween = create_tween()
						tween.set_trans(Tween.TRANS_CUBIC)
						tween.set_ease(Tween.EASE_IN_OUT)
						Gamemaneger.cam_go = false
						tween.tween_property(Main.camera, "position", Main.big_cow.position, 1.0)
						tween.finished.connect(func(): Gamemaneger.cam_go = true)
						animation_player.play("out")
						control.animation_player.play("naga")
						control.bb_up = false
						namec.text = "황소자리"
						

func update_camera_position():
	if current_constellation >= 0 and current_constellation < constellations.size():
		var current_node = constellations[current_constellation]
		if current_node.visible:
			Main.target_camera_position = current_node.position
			Gamemaneger.cam_go = false

func _on_named_star_clicked(total_stars: int, clicked_stars: int):
	var required_cost = constellation_info[current_constellation]["cost"]
	# clicked_stars가 1이면 첫 번째 별을 클릭한 것
	if clicked_stars == 1:  # 첫 번째 별을 클릭할 때만 확인
		if Gamemaneger.stardust >= required_cost:
			Gamemaneger.stardust -= required_cost  # 스타더스트 차감
		else:
			# 스타더스트가 부족하면 클릭을 취소
			constellations[current_constellation].cancel_last_click()
			return
	
	var remaining = total_stars - clicked_stars
	label.text = "남은 별: %d" % remaining

func show_constellation(index):
	# 모든 별자리를 숨김
	for constellation in constellations:
		constellation.hide()
	
	# 선택된 별자리만 보이게 함
	constellations[index].show()
	current_constellation = index
	
	# 별자리 이름과 가격을 표시
	var info = constellation_info[index]
	$thing.text = info["name"]
	$Label2.text = str(info["cost"]) + "g"

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_LEFT:
			current_constellation = (current_constellation - 1) % constellations.size()
			if current_constellation < 0:
				current_constellation = constellations.size() - 1
			show_constellation(current_constellation)
		elif event.keycode == KEY_RIGHT:
			current_constellation = (current_constellation + 1) % constellations.size()
			show_constellation(current_constellation)

# 버튼 핸들러 수정
func _on_left_button_down():
	# 이전 별자리로 이동
	var new_index = (current_constellation - 1)
	if new_index < 0:
		new_index = constellations.size() - 1
	show_constellation(new_index)

func _on_right_button_down():
	# 다음 별자리로 이동
	var new_index = (current_constellation + 1) % constellations.size()
	show_constellation(new_index)

func _on_button_3_button_down():  # 별자리 만들기 버튼을 눌렀을 때
	if not control.bb_up:
		animation_player.play("up")  # 나타나는 애니메이션 재생
		control.bb_up = true
	else:
		animation_player.play("out")  # 사라지는 애니메이션 재생
		control.bb_up = false

func all_see_off():
	for_see.visible = false
	for_see_2.visible = false
	for_see_3.visible = false
	for_see_4.visible = false
	for_see_5.visible = false
	for_see_6.visible = false

func _on_moyang_button_down():
	animation_player.play("for_see")

func is_it():
	match current_constellation:
		0:  # 작은곰자리
			for_see_2.visible = true
		1:  # 천칭자리
			for_see.visible = true
		2:  # 게자리
			for_see_3.visible = true
		3:  # 물병자리
			for_see_4.visible = true
		4:  # 양자리
			for_see_5.visible = true
		5:  # 황소자리
			for_see_6.visible = true
