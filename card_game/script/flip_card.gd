extends Node2D
class_name FlipCard

## 카드 뒤집
signal fliping(card_id: int, fliping: bool)

@onready var card_back = $card_back

@onready var sprite_2d = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var timer = $Timer
var my_id : int

## 카드 앞뒤면 : True: 앞, False: 뒤
var card_front = false
## 카드를 강제로 뒤집기 방지 : True : 가능, False : 불가능
var flip_yn = true

var m_in = false
## 카드 종류 정보
var my_thing = null
## 카드 이미지
var thing : String

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# 디버깅을 위한 체크
	if card_back and card_back.material:
		print("셰이더 material이 존재합니다")
	else:
		print("셰이더 material이 없습니다")
	select_random_card()

## 카드 선택기
func select_random_card():
	
	sprite_2d.get_child(0).queue_free()
	var random = randi_range(0,3)
	
	var thing = Gamemaneger.flip_cards[random].instantiate()
	sprite_2d.add_child(thing)
	
	if random == 0:
		my_thing = Gamemaneger.playing_state.DANGER

	if random == 1:
		my_thing = Gamemaneger.playing_state.LITTLE_PAPER

	if random == 2:
		my_thing = Gamemaneger.playing_state.SEE

	if random == 3:
		my_thing = Gamemaneger.playing_state.STORE

		
	
	

func _input(event):
	Gamemaneger.money += 1000
	if m_in:
		if event is InputEventMouseButton:
			if event.pressed:
				if not card_front:		# 뒷면인 경우
					if flip_yn:
						card_front = true
						fliping.emit(my_id, true)
						if not Gamemaneger.now_playing == Gamemaneger.playing_state.SEE:
							animation_player.play("flip")
						elif Gamemaneger.now_playing == Gamemaneger.playing_state.SEE:
							animation_player.play("flip_s")
							fliping.emit(my_id, false)
						#get_parent().get_parent().fliped = true
						#Gamemaneger.now_playing = my_thing
						

					#if Gamemaneger.now_playing == "see":
						#animation_player.play("flip_s")
						
						

func _on_area_2d_mouse_entered():
	m_in = true
	if not card_front:	# 뒷면인 겨우
		if flip_yn:
			animation_player.play("up")


func _on_area_2d_mouse_exited():
	m_in = false
	if not card_front:
		if flip_yn:
			animation_player.play("down")

func que():
	fliping.emit(my_id, false)
	#if not Gamemaneger.now_playing == "see":
		#timer.start()

func redo_f():
	card_front = false
	animation_player.play("redo")
	get_parent().get_parent().set_all_flip_yn(true)
	Gamemaneger.now_playing = Gamemaneger.playing_state.SELECT
## 카드 뒤집기 이벤트
func redo():
	select_random_card()		# 카드 다시 선택
	

		
func end():
	card_front = false
	animation_player.play("redo_s")

func start_s():
	animation_player.play("wait")
	

	
