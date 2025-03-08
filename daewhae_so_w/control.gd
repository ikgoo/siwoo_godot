extends Control
const STARER = preload("res://starer.tscn")
@onready var label = $Label

@onready var label_1 = $bb_up/Label
@onready var label_2 = $bb_up/Label2
@onready var label_3 = $bb_up/Label3
@onready var namec = $name

var bb_up = false
@onready var panel_2 = $Panel2

# 각 업그레이드의 현재 단계를 추적
var current_speed_cost = 150
var current_collect_cost = 150
var current_spawn_cost = 150

# 각 업그레이드의 최대 레벨 설정
const MAX_SPEED_LEVEL = 8
const MAX_COLLECT_LEVEL = 7
const MAX_SPAWN_LEVEL = 6

@onready var animation_player = $AnimationPlayer
@onready var node_2d_2 = $Node2D  # bbul_set 노드의 참조

# 튜토리얼 UI 변수 추가
@onready var tutorial_label = $tutorial

# 도감 변수 추가
@onready var dictionary = $dictionary_for_see
var dict_visible = false

# Called when the node enters the scene tree for the first time.
func _ready():
	update_label()
	update_upgrade_labels()
	# 처음에는 튜토리얼과 도감 숨기기
	tutorial_label.visible = false
	dictionary.visible = false  # 도감도 숨김


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_label()
	update_upgrade_labels()


func update_label():
	label.text = "스타 더스트 : " + str(Gamemaneger.stardust) + "g"


func update_upgrade_labels():
	# 생성 업그레이드 라벨
	if Gamemaneger.spawn_level >= MAX_SPAWN_LEVEL:
		label_1.text = "MAX"
	else:
		label_1.text = str(current_spawn_cost) + "g"
	

	# 속도 업그레이드 라벨
	if Gamemaneger.speed_level >= MAX_SPEED_LEVEL:
		label_3.text = "MAX"
	else:
		label_3.text = str(current_speed_cost) + "g"


func _on_button_button_down():
	var starer_in = STARER.instantiate()
	get_parent().get_parent().add_child(starer_in)


func _on_button_5_button_down():
	animation_player.play("bb_up_down")


func _on_button_2_button_down():
	animation_player.play("bb_up_up")


# 속도 업그레이드
func _on_speed_upgrade_button_down():
	if Gamemaneger.stardust >= current_speed_cost and Gamemaneger.speed_level < MAX_SPEED_LEVEL:
		Gamemaneger.stardust -= current_speed_cost
		Gamemaneger.speed_level += 1
		# 다음 업그레이드 비용 설정
		match Gamemaneger.speed_level:
			2: current_speed_cost = 500
			3: current_speed_cost = 1000
			4: current_speed_cost = 5000  # 1000 -> 2000 (2배)
			5: current_speed_cost = 10000  # 1500 -> 3000 (2배)
			6: current_speed_cost = 20000  # 2000 -> 4000 (2배)
			7: current_speed_cost = 50000
			8: current_speed_cost = 100000
		update_label()
		update_upgrade_labels()





# 새로운 별 생성
func _on_spawn_upgrade_button_down():
	if Gamemaneger.stardust >= current_spawn_cost and Gamemaneger.spawn_level < MAX_SPAWN_LEVEL:
		Gamemaneger.stardust -= current_spawn_cost
		Gamemaneger.spawn_level += 1
		
		# starer 생성
		var starer_in = STARER.instantiate()
		get_parent().get_parent().add_child(starer_in)
		
		# 다음 업그레이드 비용 설정
		match Gamemaneger.spawn_level:
			2: current_spawn_cost = 500
			3: current_spawn_cost = 1000  # 600 -> 1200 (2배)
			4: current_spawn_cost = 5000
			5: current_spawn_cost = 10000
			6: current_spawn_cost = 20000
		update_label()
		update_upgrade_labels()


func _on_button_3_button_down():
	if not bb_up:
		node_2d_2.animation_player.play("up")  # 별자리 메뉴가 나타나는 애니메이션
		animation_player.play("see_bb_set")
		Gamemaneger.cam_go = false
		bb_up = true
	else:
		node_2d_2.animation_player.play("out")  # 별자리 메뉴가 사라지는 애니메이션
		Gamemaneger.cam_go = true
		bb_up = false


func gof():
	# 아무 동작도 하지 않도록 수정
	pass


func _on_button_6_button_down():
	# 게임 계속하기
	Main.end = false  # 게임 종료 상태 해제
	Gamemaneger.cam_go = true  # 카메라 이동 활성화


func _on_outing_button_down():
	Main.visible = false
	# 메인 화면으로 돌아가기
	get_tree().change_scene_to_file("res://title.tscn")  # 메인 씬으로 전환


# 튜토리얼 버튼 클릭 시
func _on_tutorial_b_button_down():
	tutorial_label.visible = true
	panel_2.visible = true


# 아무 곳이나 클릭했을 때 튜토리얼 숨기기
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if tutorial_label.visible:
			tutorial_label.visible = false
			panel_2.visible = false


# 튜토리얼 표시 함수 추가
func show_tutorial():
	tutorial_label.visible = true


func _on_ict_button_down():
	dict_visible = !dict_visible  # 상태 토글
	
	if dict_visible:
		# 도감 표시
		dictionary.visible = true
		Gamemaneger.cam_go = false
	else:
		# 도감 숨기기
		dictionary.visible = false
		Gamemaneger.cam_go = true
