extends Control

#호버하면 오른쪽으로 갈 거리 / 커지는 배율 / 따라오는 속도
const HOVER_X = 30.0
const HOVER_SCALE = 1.15
const SPEED = 12.0

#얘들
@onready var animation_player = $AnimationPlayer
#버튼마다 따로 - 한 AnimationPlayer 는 한번에 하나만 재생돼서 서로 끊김
@onready var start_ani = $start_ani
@onready var option_ani = $option_ani
@onready var exit_ani = $exit_ani
@onready var buttons = [$start, $option, $exit]
@onready var setting = $setting
@onready var audio_stream_player = $AudioStreamPlayer
@onready var start_t_ani = $start_t_ani

#버튼별 원래 위치, 마우스 올라가있는지
var press
var base_pos = {}
var hovering = {}
#클릭 이펙트 재생중엔 lerp 끄기
var clicked = false

func _ready():
	audio_stream_player.play()

func _on_hover(b, is_in):
	hovering[b] = is_in



#클릭했을때
func _on_pressed(b):
	if clicked:
		return
	clicked = true
	if b.name:
		animation_player.play("fade_in")
		press = b
		
	else:
		#option 은 아직 없으니 이펙트만 보여주고 원래대로
		await get_tree().create_timer(0.45).timeout
		clicked = false


#페이드 인 끝났을때
func ani_end():
	if press == "start":
		get_tree().change_scene_to_file("res://home.tscn")
	elif press == "start_t":
		Gamemaneger.tu = true
		get_tree().change_scene_to_file("res://main_game.tscn")
	else:
		get_tree().quit()
	


func _on_start_mouse_entered():
	start_ani.play("start_come")
	

func _on_start_mouse_exited():
	start_ani.play_backwards("start_come")
	

func _on_option_mouse_entered():
	option_ani.play("option_come")



func _on_option_mouse_exited():
	option_ani.play_backwards("option_come")



func _on_exit_mouse_entered():
	exit_ani.play("exit_come")


func _on_exit_mouse_exited():
	exit_ani.play_backwards("exit_come")


func _on_start_pressed():
	animation_player.play("fade_in")
	press = "start"

func _on_option_pressed():
	setting.visible = true


func _on_exit_pressed():
	pass # Replace with function body.


func _on_start_t_button_down():
	animation_player.play("fade_in")
	press = "start_t"


func _on_start_t_mouse_entered():
	start_t_ani.play("start_t_open")


func _on_start_t_mouse_exited():
	start_t_ani.play_backwards("start_t_open")
