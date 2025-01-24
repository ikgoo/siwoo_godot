extends Node2D

var flip_card1: FlipCard
var flip_card2: FlipCard
var flip_card3: FlipCard
var card1
var card2
var card3
var card1_q = false
var card2_q = false
var card3_q = false
var null_thing
var fliped
var see_flip = false
var see_card
@onready var timer = $Timer
@onready var animation_player = $AnimationPlayer
@onready var sprite_2d = $Sprite2D
@onready var area_2d = $"../Area2D"

var cards: Array

const FLIP_CARD = preload("res://tscn/flip_card.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	flip_card1 = %flip_card
	flip_card1.my_id = 0
	flip_card2 = %flip_card2
	flip_card2.my_id = 1
	flip_card3 = %flip_card3
	flip_card3.my_id = 2
	
	cards = [flip_card1, flip_card2, flip_card3]

func _process(delta):
	print(Gamemaneger.now_playing)

	#if fliped:
		#if Gamemaneger.now_playing == "see":
			#see_flip = true
		#else:
			#animation_player.play("up")
			#card1.n_fliping = true
			#card2.n_fliping = true
			#card3.n_fliping = true
			#fliped = false
			#area_2d.position = get_local_mouse_position()

## 카드의 flip 상태 이벤트
## fliping: 
##    true -> 뒤집는중, false -> 뒤집기 종료
func _on_flip_card_fliping(card_id, fliping):
	if fliping:
		set_all_flip_yn(false)
	else:
		# 무존건 앞면 오픈 상태임
		match Gamemaneger.now_playing:
			Gamemaneger.playing_state.SELECT:		## 카드 선택 상태
				
				see_card = card_id
				match cards[see_card].my_thing:
					Gamemaneger.playing_state.SEE:
						card_state_see(card_id)
					Gamemaneger.playing_state.STORE:
						card_state_not_see(Gamemaneger.playing_state.STORE)
					Gamemaneger.playing_state.DANGER:
						card_state_not_see(Gamemaneger.playing_state.DANGER)
					Gamemaneger.playing_state.LITTLE_PAPER:
						card_state_not_see(Gamemaneger.playing_state.LITTLE_PAPER)
				#print(cards[card_id].thing)
				#match cards[card_id].thing:
					#Gamemaneger.card_thing.SEE:
						#card_state_see(card_id)
					#_:
						#card_state_not_see(card_id)
			Gamemaneger.playing_state.SEE:			## 카드 보기 상태
				var tmp_selected_card: FlipCard = cards[card_id]
				cards[see_card].animation_player.play("wait_f")
			


func card_state_see(card_id: int):
	Gamemaneger.now_playing = Gamemaneger.playing_state.SEE

	var tmp_selected_card: FlipCard = cards[card_id]
	
	flip_card1.flip_yn = true
	flip_card2.flip_yn = true
	flip_card3.flip_yn = true
	tmp_selected_card.flip_yn = false

	

	#tmp_card.thing

func card_state_see_end(card_id: int):
	flip_card1.flip_yn = false
	flip_card2.flip_yn = false
	flip_card3.flip_yn = false

	#awiat tmp_selected_card.animation_player.play("flip_s").fi
	Gamemaneger.now_playing = Gamemaneger.playing_state.SELECT

func card_state_not_see(card_id: int):
	animation_player.play("up")
	Gamemaneger.now_playing = card_id
	await animation_player.animation_finished
	match card_id:
		Gamemaneger.playing_state.STORE:
			pass
		Gamemaneger.playing_state.DANGER:
			pass	
		Gamemaneger.playing_state.LITTLE_PAPER:
			pass

## 카드들 뒤집기 상태 전환
func set_all_flip_yn(flag: bool):
	flip_card1.flip_yn = flag
	flip_card2.flip_yn = flag
	flip_card3.flip_yn = flag
