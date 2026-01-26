extends Node2D
@onready var start = $start

const MINC_CLICKER_LOBBY_BUTTON_START_3 = preload("uid://byi030cxhp7oc")

@onready var animation_player = $AnimationPlayer
@onready var label = $Label

## 씬 초기화 시 레이블 깜빡임 애니메이션 시작
func _ready():
	# UI 텍스트 번역 적용
	label.text = Globals.get_text("LOBBY PRESS KEY")
	animation_player.play("label_blink")

func _on_start_button_up():
	animation_player.play("close")

func _on_setting_button_up():
	pass


func _on_exit_button_up():
	get_tree().quit()

## 아무 키나 눌러도 게임 시작
func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		_on_start_button_up()

func go():
	get_tree().change_scene_to_file("res://main.tscn")
